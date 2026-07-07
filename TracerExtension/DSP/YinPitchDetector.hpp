#pragma once

#include <vector>

struct PitchEstimate {
    double frequencyHz = 0.0;
    double confidence = 0.0;
    bool valid = false;
};

// Monophonic fundamental-frequency estimator (de Cheveigne & Kawahara, YIN).
// prepare() allocates; analyze() is render-thread safe once prepared.
class YinPitchDetector {
public:
    void prepare(double sampleRate, int windowSize);

    // `window` must point to exactly windowSize samples.
    PitchEstimate analyze(const float* window);

private:
    static constexpr double kAbsoluteThreshold = 0.10;
    static constexpr double kMinFrequencyHz = 55.0;
    static constexpr double kMaxFrequencyHz = 1500.0;

    double mSampleRate = 44100.0;
    int mWindowSize = 0;
    int mMaxLag = 0;

    std::vector<double> mDifference;
    std::vector<double> mCmndf;
};
