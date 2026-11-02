import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation

struct AudioDevice: Identifiable, Hashable, Codable {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let input: Bool
    let output: Bool
    let virtual: Bool

    static func all() -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return [] }
        var ids = Array(repeating: AudioDeviceID(0), count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        let status = ids.withUnsafeMutableBytes { AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, $0.baseAddress!) }
        guard status == noErr else { return [] }
        return ids.map { id in
            AudioDevice(id: id, uid: string(id, kAudioDevicePropertyDeviceUID), name: string(id, kAudioObjectPropertyName),
                        input: streams(id, kAudioDevicePropertyScopeInput), output: streams(id, kAudioDevicePropertyScopeOutput),
                        virtual: number(id, kAudioDevicePropertyTransportType) == kAudioDeviceTransportTypeVirtual)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func string(_ id: AudioDeviceID, _ selector: AudioObjectPropertySelector) -> String {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = withUnsafeMutablePointer(to: &value) {
            AudioObjectGetPropertyData(id, &address, 0, nil, &size, $0)
        }
        // Both Core Audio properties return a retained CFObject.
        guard status == noErr, let value else { return "" }
        return value.takeRetainedValue() as String
    }
    private static func number(_ id: AudioDeviceID, _ selector: AudioObjectPropertySelector) -> UInt32 {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        _ = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value)
        return value
    }
    private static func streams(_ id: AudioDeviceID, _ scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams, mScope: scope, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr && size > 0
    }
}

enum MicError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case let .message(text) = self { return text }; return nil }
}

func setDevice(_ unit: AudioUnit?, to id: AudioDeviceID) throws {
    guard let unit else { throw MicError.message("The audio device could not be opened.") }
    var device = id
    let status = AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
                                      &device, UInt32(MemoryLayout<AudioDeviceID>.size))
    guard status == noErr else { throw MicError.message("Could not select the audio device. Core Audio error \(status).") }
}

/// Device selection updates the hardware input format before the engine's
/// cached output format. Capture cannot convert between these two formats.
func microphoneFormat(_ node: AVAudioInputNode) -> AVAudioFormat {
    node.inputFormat(forBus: 0)
}

func currentDevice(_ unit: AudioUnit?) -> AudioDeviceID? {
    guard let unit else { return nil }
    var device = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    guard AudioUnitGetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
                               &device, &size) == noErr else { return nil }
    return device
}
