#pragma once

#include <cstdint>

#include "MidiMath.hpp"

struct NoteAction {
    enum class Kind { NoteOn, NoteOff, PitchBend };
    Kind kind;
    uint8_t note = 0;
    uint8_t velocity = 0;
    uint16_t bend14 = 8192;
};

// Fixed capacity so a single hop can emit "note off old / note on new /
// recenter bend" with no heap allocation on the render thread.
struct NoteActionList {
    NoteAction actions[3];
    int count = 0;

    void add(NoteAction::Kind kind, uint8_t note, uint8_t velocity = 0, uint16_t bend14 = 8192) {
        if (count < 3) {
            actions[count++] = NoteAction{kind, note, velocity, bend14};
        }
    }
};

// Debounces a raw per-hop (gate, note, cents) stream into stable MIDI note
// on/off/bend actions. Render-thread safe: no allocation, no locks.
class NoteStateMachine {
public:
    void reset() {
        mConsecutiveConfirmingHops = 0;
        mCandidateNote = -1;
        mSustainedNote = -1;
        mLastSentBend14 = 8192;
    }

    NoteActionList update(bool gatesPassed, int detectedNote, double cents, uint8_t velocity, bool pitchBendEnabled) {
        NoteActionList result;

        if (!gatesPassed) {
            mCandidateNote = -1;
            mConsecutiveConfirmingHops = 0;
            if (mSustainedNote >= 0) {
                result.add(NoteAction::Kind::NoteOff, (uint8_t)mSustainedNote);
                mSustainedNote = -1;
                mLastSentBend14 = 8192;
            }
            return result;
        }

        if (detectedNote == mSustainedNote) {
            mCandidateNote = mSustainedNote;
            mConsecutiveConfirmingHops = kRequiredConfirmingHops;
            if (pitchBendEnabled) {
                uint16_t bend = centsToBend14(cents);
                if (bend != mLastSentBend14) {
                    result.add(NoteAction::Kind::PitchBend, (uint8_t)mSustainedNote, 0, bend);
                    mLastSentBend14 = bend;
                }
            }
            return result;
        }

        if (detectedNote == mCandidateNote) {
            ++mConsecutiveConfirmingHops;
        } else {
            mCandidateNote = detectedNote;
            mConsecutiveConfirmingHops = 1;
        }

        if (mConsecutiveConfirmingHops >= kRequiredConfirmingHops) {
            if (mSustainedNote >= 0) {
                result.add(NoteAction::Kind::NoteOff, (uint8_t)mSustainedNote);
            }
            result.add(NoteAction::Kind::NoteOn, (uint8_t)mCandidateNote, velocity);
            if (pitchBendEnabled) {
                result.add(NoteAction::Kind::PitchBend, (uint8_t)mCandidateNote, 0, 8192);
            }
            mSustainedNote = mCandidateNote;
            mLastSentBend14 = 8192;
        }

        return result;
    }

    bool isSustaining() const { return mSustainedNote >= 0; }
    int sustainedNote() const { return mSustainedNote; }

private:
    static constexpr int kRequiredConfirmingHops = 2;

    int mConsecutiveConfirmingHops = 0;
    int mCandidateNote = -1;
    int mSustainedNote = -1;
    uint16_t mLastSentBend14 = 8192;
};
