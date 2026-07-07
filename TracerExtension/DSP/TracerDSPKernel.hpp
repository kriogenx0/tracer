#pragma once

#include <AudioToolbox/AudioToolbox.h>
#include <CoreMIDI/CoreMIDI.h>

#include <algorithm>
#include <cassert>
#include <cmath>
#include <span>
#include <vector>

#include "MidiMath.hpp"
#include "NoteStateMachine.hpp"
#include "TracerParameterAddresses.h"
#include "YinPitchDetector.hpp"

inline int nextPowerOfTwo(int value) {
    int power = 1;
    while (power < value) {
        power *= 2;
    }
    return power;
}

// Simple power-of-two circular history buffer. write() and copyLatestWindow()
// are the only operations used from the render thread; both are O(n), no
// allocation.
class AnalysisRingBuffer {
public:
    void prepare(int capacity) {
        mData.assign(capacity, 0.0f);
        mMask = (uint32_t)(capacity - 1);
        mWriteIndex = 0;
    }

    void write(const float* samples, int count) {
        for (int i = 0; i < count; ++i) {
            mData[mWriteIndex & mMask] = samples[i];
            ++mWriteIndex;
        }
    }

    void copyLatestWindow(float* out, int windowSize) const {
        uint32_t start = mWriteIndex - (uint32_t)windowSize;
        for (int i = 0; i < windowSize; ++i) {
            out[i] = mData[(start + (uint32_t)i) & mMask];
        }
    }

private:
    std::vector<float> mData;
    uint32_t mMask = 0;
    uint32_t mWriteIndex = 0;
};

/*
 TracerDSPKernel
 As a non-ObjC class, this is safe to use from the render thread.

 Listens to a mono audio input, runs YIN pitch detection on overlapping
 analysis windows, and emits MIDI note on/off/pitch-bend events for the
 detected monophonic pitch. Audio is passed through unchanged.
 */
class TracerDSPKernel {
public:
    static constexpr int kWindowSize = 1024;
    static constexpr int kHopSize = 256;

    void initialize(int inputChannelCount, int outputChannelCount, double inSampleRate) {
        mSampleRate = inSampleRate;

        int minimumCapacity = 2 * (int)std::max<AUAudioFrameCount>(mMaxFramesToRender, kHopSize);
        int capacity = std::max(2048, nextPowerOfTwo(minimumCapacity));
        mRingBuffer.prepare(capacity);
        mAnalysisWindow.assign(kWindowSize, 0.0f);
        mSamplesSinceLastHop = 0;

        mPitchDetector.prepare(inSampleRate, kWindowSize);
        mNoteStateMachine.reset();

        mMeterNote = 0.0f;
        mMeterFrequency = 0.0f;
        mMeterNoteActive = 0.0f;
    }

    void deInitialize() {}

    // MARK: - Bypass
    bool isBypassed() const { return mBypassed; }
    void setBypass(bool shouldBypass) { mBypassed = shouldBypass; }

    // MARK: - Parameter Getter / Setter
    void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
            case TracerParameterAddress::gateThreshold:
                mGateThresholdDb = value;
                break;
            case TracerParameterAddress::sensitivity:
                mSensitivity = value;
                break;
            case TracerParameterAddress::pitchBendEnable:
                mPitchBendEnable = value >= 0.5f;
                break;
        }
    }

    AUValue getParameter(AUParameterAddress address) {
        switch (address) {
            case TracerParameterAddress::gateThreshold:
                return (AUValue)mGateThresholdDb;
            case TracerParameterAddress::sensitivity:
                return (AUValue)mSensitivity;
            case TracerParameterAddress::pitchBendEnable:
                return mPitchBendEnable ? 1.0f : 0.0f;
            case TracerParameterAddress::detectedNote:
                return mMeterNote;
            case TracerParameterAddress::detectedFrequency:
                return mMeterFrequency;
            case TracerParameterAddress::noteActive:
                return mMeterNoteActive;
            default:
                return 0.f;
        }
    }

    // MARK: - Max Frames
    AUAudioFrameCount maximumFramesToRender() const { return mMaxFramesToRender; }
    void setMaximumFramesToRender(const AUAudioFrameCount& maxFrames) { mMaxFramesToRender = maxFrames; }

    // MARK: - MIDI Output
    void setMIDIOutputEventBlock(AUMIDIOutputEventBlock midiOutBlock) { mMIDIOutputEventBlock = midiOutBlock; }

    /**
     MARK: - Internal Process

     Passes audio through unchanged while accumulating it into a ring buffer;
     every kHopSize new samples, analyzes the most recent kWindowSize samples
     and turns the result into MIDI note/bend actions.
     */
    void process(std::span<float const*> inputBuffers, std::span<float*> outputBuffers, AUEventSampleTime bufferStartTime, AUAudioFrameCount frameCount) {
        assert(inputBuffers.size() >= 1 && outputBuffers.size() >= 1);

        const float* input = inputBuffers[0];
        float* output = outputBuffers[0];

        AUAudioFrameCount processed = 0;
        while (processed < frameCount) {
            int samplesUntilNextHop = kHopSize - mSamplesSinceLastHop;
            AUAudioFrameCount chunk = std::min((AUAudioFrameCount)samplesUntilNextHop, frameCount - processed);

            mRingBuffer.write(input + processed, (int)chunk);
            std::copy(input + processed, input + processed + chunk, output + processed);

            mSamplesSinceLastHop += (int)chunk;
            processed += chunk;

            if (mSamplesSinceLastHop >= kHopSize) {
                mSamplesSinceLastHop = 0;
                runAnalysisHop(bufferStartTime + (AUEventSampleTime)processed);
            }
        }
    }

    void handleOneEvent(AUEventSampleTime now, AURenderEvent const* event) {
        switch (event->head.eventType) {
            case AURenderEventParameter:
                handleParameterEvent(now, event->parameter);
                break;

            default:
                break;
        }
    }

    void handleParameterEvent(AUEventSampleTime now, AUParameterEvent const& parameterEvent) {
        setParameter(parameterEvent.parameterAddress, parameterEvent.value);
    }

    // MARK: - Member Variables
    double mSampleRate = 44100.0;
    bool mBypassed = false;
    AUAudioFrameCount mMaxFramesToRender = 1024;
    AUMIDIOutputEventBlock mMIDIOutputEventBlock = nullptr;

private:
    void runAnalysisHop(AUEventSampleTime hopTime) {
        if (mBypassed) {
            emitActions(hopTime, mNoteStateMachine.update(false, -1, 0.0, 0, false));
            updateMeters(false, -1, 0.0f);
            return;
        }

        mRingBuffer.copyLatestWindow(mAnalysisWindow.data(), kWindowSize);
        PitchEstimate estimate = mPitchDetector.analyze(mAnalysisWindow.data());

        float rmsDb = amplitudeToDecibels(computeRms(mAnalysisWindow.data(), kWindowSize));
        bool gatesPassed = estimate.valid && rmsDb >= mGateThresholdDb && estimate.confidence >= mSensitivity;

        int note = gatesPassed ? frequencyToMidiNote(estimate.frequencyHz) : -1;
        double cents = gatesPassed ? centsDeviation(estimate.frequencyHz, note) : 0.0;
        uint8_t velocity = gatesPassed ? decibelsToVelocity(rmsDb, mGateThresholdDb) : 0;

        NoteActionList actions = mNoteStateMachine.update(gatesPassed, note, cents, velocity, mPitchBendEnable);
        emitActions(hopTime, actions);
        updateMeters(mNoteStateMachine.isSustaining(), mNoteStateMachine.sustainedNote(), (float)estimate.frequencyHz);
    }

    void updateMeters(bool active, int note, float frequencyHz) {
        mMeterNoteActive = active ? 1.0f : 0.0f;
        mMeterNote = active ? (float)note : 0.0f;
        mMeterFrequency = active ? frequencyHz : 0.0f;
    }

    void emitActions(AUEventSampleTime hopTime, const NoteActionList& actions) {
        if (!mMIDIOutputEventBlock) {
            return;
        }
        for (int i = 0; i < actions.count; ++i) {
            const NoteAction& action = actions.actions[i];
            uint8_t bytes[3];
            switch (action.kind) {
                case NoteAction::Kind::NoteOn:
                    writeNoteOn(0, action.note, action.velocity, bytes);
                    break;
                case NoteAction::Kind::NoteOff:
                    writeNoteOff(0, action.note, bytes);
                    break;
                case NoteAction::Kind::PitchBend:
                    writePitchBend(0, action.bend14, bytes);
                    break;
            }
            mMIDIOutputEventBlock(hopTime, 0, 3, bytes);
        }
    }

    static float computeRms(const float* samples, int count) {
        double sumSquares = 0.0;
        for (int i = 0; i < count; ++i) {
            sumSquares += (double)samples[i] * (double)samples[i];
        }
        return (float)std::sqrt(sumSquares / (double)count);
    }

    float mGateThresholdDb = -40.0f;
    float mSensitivity = 0.5f;
    bool mPitchBendEnable = true;

    AnalysisRingBuffer mRingBuffer;
    std::vector<float> mAnalysisWindow;
    int mSamplesSinceLastHop = 0;
    YinPitchDetector mPitchDetector;
    NoteStateMachine mNoteStateMachine;

    float mMeterNote = 0.0f;
    float mMeterFrequency = 0.0f;
    float mMeterNoteActive = 0.0f;
};
