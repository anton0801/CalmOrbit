//
//  SoundManager.swift
//  CalmOrbit
//
//  Generates ambient sound in real time with AVAudioSourceNode — no bundled
//  audio files. Each SoundKind drives a small synth (sine layers + filtered
//  noise + a slow amplitude LFO). Respects the global "sound enabled" setting.
//

import Foundation
import AVFoundation
import Combine

enum SoundPref {
    static let key = "settings_sound_enabled"
}

final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published private(set) var currentSoundID: UUID?
    @Published var volume: Double {
        didSet {
            UserDefaults.standard.set(volume, forKey: "settings_sound_volume")
            engine.mainMixerNode.outputVolume = Float(volume)
        }
    }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100

    // Synth state (touched only on the audio render thread once playing).
    private var phase1 = 0.0
    private var phase2 = 0.0
    private var lfoPhase = 0.0
    private var noiseState = 0.0
    private var rngState: UInt32 = 0x9E3779B9
    private var kind: SoundKind = .pad

    private init() {
        let stored = UserDefaults.standard.object(forKey: "settings_sound_volume") as? Double
        volume = stored ?? 0.7
    }

    var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: SoundPref.key) as? Bool ?? true
    }

    var isPlaying: Bool { currentSoundID != nil }

    func toggle(_ sound: SoundOption) {
        if currentSoundID == sound.id {
            stop()
        } else {
            play(sound)
        }
    }

    func play(_ sound: SoundOption) {
        guard soundEnabled else { return }
        stop()

        kind = sound.kind
        configureSession()

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            return self.render(frameCount: frameCount, audioBufferList: audioBufferList)
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = Float(volume)
        sourceNode = node

        do {
            try engine.start()
            currentSoundID = sound.id
        } catch {
            cleanup()
        }
    }

    func stop() {
        cleanup()
        currentSoundID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Called when the global sound setting is turned off.
    func stopIfDisabled() {
        if !soundEnabled { stop() }
    }

    private func cleanup() {
        if engine.isRunning { engine.stop() }
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        phase1 = 0; phase2 = 0; lfoPhase = 0; noiseState = 0
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // Fast, real-time-safe white noise (xorshift) — avoids locking the system RNG.
    private func nextNoise() -> Double {
        rngState ^= rngState << 13
        rngState ^= rngState >> 17
        rngState ^= rngState << 5
        return (Double(rngState) / Double(UInt32.max)) * 2.0 - 1.0
    }

    private func render(frameCount: AVAudioFrameCount,
                        audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let k = kind
        let twoPi = 2.0 * Double.pi
        let inc1 = twoPi * k.baseFrequency / sampleRate
        let inc2 = twoPi * k.harmonicFrequency / sampleRate
        let lfoInc = twoPi * k.lfoRate / sampleRate

        for frame in 0..<Int(frameCount) {
            var sample = 0.0
            if k.baseFrequency > 0 { sample += sin(phase1) * 0.5 }
            if k.harmonicFrequency > 0 { sample += sin(phase2) * 0.28 }
            if k.noiseLevel > 0 {
                let white = nextNoise()
                noiseState = noiseState * k.noiseDamping + white * (1.0 - k.noiseDamping)
                sample += noiseState * k.noiseLevel * 1.8
            }

            let lfo = k.lfoRate > 0 ? (0.72 + 0.28 * sin(lfoPhase)) : 1.0
            sample *= lfo * 0.55

            if sample > 1 { sample = 1 } else if sample < -1 { sample = -1 }
            let value = Float(sample)

            for buffer in ablPointer {
                let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                ptr[frame] = value
            }

            phase1 += inc1; if phase1 > twoPi { phase1 -= twoPi }
            phase2 += inc2; if phase2 > twoPi { phase2 -= twoPi }
            lfoPhase += lfoInc; if lfoPhase > twoPi { lfoPhase -= twoPi }
        }
        return noErr
    }
}
