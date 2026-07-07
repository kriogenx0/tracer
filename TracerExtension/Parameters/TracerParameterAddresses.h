#pragma once

#include <AudioToolbox/AUParameters.h>

typedef NS_ENUM(AUParameterAddress, TracerParameterAddress) {
    gateThreshold = 0,
    sensitivity = 1,
    pitchBendEnable = 2,
    // Read-only meters that mirror the kernel's live analysis for the UI;
    // never written by a host.
    detectedNote = 3,
    detectedFrequency = 4,
    noteActive = 5
};
