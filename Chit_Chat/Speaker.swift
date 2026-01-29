import SwiftUI
import AVFoundation

/// Configures the AVAudioSession for voice chat use.
struct AudioSessionConfigurator {
    static func configure() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Audio Config Error: \(error)")
        }
    }
}
