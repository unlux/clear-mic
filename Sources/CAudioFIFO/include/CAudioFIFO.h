#ifndef CLEAR_MIC_AUDIO_FIFO_H
#define CLEAR_MIC_AUDIO_FIFO_H
#include <stddef.h>
#include <stdint.h>

typedef struct CMFIFO CMFIFO;
CMFIFO *cm_fifo_create(size_t capacity);
void cm_fifo_destroy(CMFIFO *fifo);
size_t cm_fifo_count(const CMFIFO *fifo);
size_t cm_fifo_write(CMFIFO *fifo, const float *source, size_t count);
size_t cm_fifo_read(CMFIFO *fifo, float *destination, size_t count);
// Render fills any unavailable frames with silence. Neither callback allocates,
// blocks, retains Swift objects, or calls the model.
size_t cm_fifo_render(CMFIFO *fifo, float *destination, size_t count);
void cm_fifo_arm(CMFIFO *fifo);
uint64_t cm_fifo_dropped(const CMFIFO *fifo);
uint64_t cm_fifo_underruns(const CMFIFO *fifo);
#endif
