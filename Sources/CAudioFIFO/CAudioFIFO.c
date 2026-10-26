#include "CAudioFIFO.h"
#include <stdatomic.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

struct CMFIFO {
    float *samples;
    size_t capacity;
    _Atomic uint64_t head;
    _Atomic uint64_t tail;
    _Atomic uint64_t dropped;
    _Atomic uint64_t underruns;
    _Atomic bool armed;
};

CMFIFO *cm_fifo_create(size_t capacity) {
    if (!capacity) return NULL;
    CMFIFO *fifo = calloc(1, sizeof(*fifo));
    if (!fifo) return NULL;
    fifo->samples = calloc(capacity, sizeof(float));
    if (!fifo->samples) { free(fifo); return NULL; }
    fifo->capacity = capacity;
    atomic_init(&fifo->head, 0);
    atomic_init(&fifo->tail, 0);
    atomic_init(&fifo->dropped, 0);
    atomic_init(&fifo->underruns, 0);
    atomic_init(&fifo->armed, false);
    return fifo;
}
void cm_fifo_destroy(CMFIFO *fifo) {
    if (fifo) { free(fifo->samples); free(fifo); }
}
size_t cm_fifo_count(const CMFIFO *fifo) {
    uint64_t tail = atomic_load_explicit(&fifo->tail, memory_order_acquire);
    uint64_t head = atomic_load_explicit(&fifo->head, memory_order_acquire);
    return head >= tail ? (size_t)(head - tail) : 0;
}
size_t cm_fifo_write(CMFIFO *fifo, const float *source, size_t count) {
    uint64_t head = atomic_load_explicit(&fifo->head, memory_order_relaxed);
    uint64_t tail = atomic_load_explicit(&fifo->tail, memory_order_acquire);
    if (count > fifo->capacity - (size_t)(head - tail)) {
        atomic_fetch_add_explicit(&fifo->dropped, count, memory_order_relaxed);
        return 0;
    }
    size_t offset = head % fifo->capacity;
    size_t first = count < fifo->capacity - offset ? count : fifo->capacity - offset;
    memcpy(fifo->samples + offset, source, first * sizeof(float));
    if (count > first) memcpy(fifo->samples, source + first, (count - first) * sizeof(float));
    atomic_store_explicit(&fifo->head, head + count, memory_order_release);
    return count;
}
size_t cm_fifo_read(CMFIFO *fifo, float *destination, size_t count) {
    uint64_t tail = atomic_load_explicit(&fifo->tail, memory_order_relaxed);
    uint64_t head = atomic_load_explicit(&fifo->head, memory_order_acquire);
    size_t available = (size_t)(head - tail);
    if (count > available) count = available;
    size_t offset = tail % fifo->capacity;
    size_t first = count < fifo->capacity - offset ? count : fifo->capacity - offset;
    memcpy(destination, fifo->samples + offset, first * sizeof(float));
    if (count > first) memcpy(destination + first, fifo->samples, (count - first) * sizeof(float));
    atomic_store_explicit(&fifo->tail, tail + count, memory_order_release);
    return count;
}
size_t cm_fifo_render(CMFIFO *fifo, float *destination, size_t count) {
    if (!atomic_load_explicit(&fifo->armed, memory_order_acquire)) {
        memset(destination, 0, count * sizeof(float));
        return 0;
    }
    size_t read = cm_fifo_read(fifo, destination, count);
    if (read < count) {
        memset(destination + read, 0, (count - read) * sizeof(float));
        atomic_fetch_add_explicit(&fifo->underruns, count - read, memory_order_relaxed);
    }
    return read;
}
void cm_fifo_arm(CMFIFO *fifo) { atomic_store_explicit(&fifo->armed, true, memory_order_release); }
uint64_t cm_fifo_dropped(const CMFIFO *fifo) { return atomic_load_explicit(&fifo->dropped, memory_order_relaxed); }
uint64_t cm_fifo_underruns(const CMFIFO *fifo) { return atomic_load_explicit(&fifo->underruns, memory_order_relaxed); }
