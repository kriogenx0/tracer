#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>

inline double frequencyToMidiNoteFloat(double frequencyHz) {
    return 69.0 + 12.0 * std::log2(frequencyHz / 440.0);
}

inline int frequencyToMidiNote(double frequencyHz) {
    double note = std::round(frequencyToMidiNoteFloat(frequencyHz));
    return (int)std::clamp(note, 0.0, 127.0);
}

inline double centsDeviation(double frequencyHz, int midiNote) {
    return 100.0 * (frequencyToMidiNoteFloat(frequencyHz) - (double)midiNote);
}

inline float amplitudeToDecibels(float rms) {
    constexpr float kFloor = 1.0e-9f;
    return 20.0f * std::log10(std::max(rms, kFloor));
}

// Loudness at note-on time maps to velocity so notes are not all played at
// a flat 127; the floor is clamped so a gate near 0 dB still leaves a span.
inline uint8_t decibelsToVelocity(float rmsDb, float gateThresholdDb) {
    float floorDb = std::min(gateThresholdDb, -1.0f);
    float normalized = (rmsDb - floorDb) / (0.0f - floorDb);
    normalized = std::clamp(normalized, 0.0f, 1.0f);
    int velocity = 1 + (int)std::lround(normalized * 126.0f);
    return (uint8_t)std::clamp(velocity, 1, 127);
}

// Internal convention (not a receiver-negotiated MIDI bend range message):
// +-100 cents (one semitone) sweeps the full +-8191 range around center.
inline uint16_t centsToBend14(double cents) {
    double normalized = cents / 100.0;
    double value = 8192.0 + normalized * 8191.0;
    value = std::clamp(value, 0.0, 16383.0);
    return (uint16_t)(value + 0.5);
}

inline void writeNoteOn(uint8_t channel, uint8_t note, uint8_t velocity, uint8_t outBytes[3]) {
    outBytes[0] = (uint8_t)(0x90 | (channel & 0x0F));
    outBytes[1] = note & 0x7F;
    outBytes[2] = velocity & 0x7F;
}

inline void writeNoteOff(uint8_t channel, uint8_t note, uint8_t outBytes[3]) {
    outBytes[0] = (uint8_t)(0x80 | (channel & 0x0F));
    outBytes[1] = note & 0x7F;
    outBytes[2] = 0;
}

inline void writePitchBend(uint8_t channel, uint16_t bend14, uint8_t outBytes[3]) {
    outBytes[0] = (uint8_t)(0xE0 | (channel & 0x0F));
    outBytes[1] = (uint8_t)(bend14 & 0x7F);
    outBytes[2] = (uint8_t)((bend14 >> 7) & 0x7F);
}
