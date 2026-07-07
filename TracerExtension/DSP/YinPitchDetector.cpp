#include "YinPitchDetector.hpp"

#include <algorithm>
#include <cmath>

void YinPitchDetector::prepare(double sampleRate, int windowSize) {
    mSampleRate = sampleRate;
    mWindowSize = windowSize;
    // windowSize/2 is what actually bounds the lowest detectable frequency in
    // practice (a full period must fit inside the window); kMinFrequencyHz is
    // an aspirational floor that only binds at larger windows/sample rates.
    mMaxLag = std::min(windowSize / 2, (int)(sampleRate / kMinFrequencyHz));
    mDifference.assign(mMaxLag + 1, 0.0);
    mCmndf.assign(mMaxLag + 1, 0.0);
}

PitchEstimate YinPitchDetector::analyze(const float* window) {
    PitchEstimate result;
    if (mMaxLag < 2 || mWindowSize <= 0) {
        return result;
    }

    // Difference function: d(tau) = sum_i (x[i] - x[i+tau])^2
    mDifference[0] = 0.0;
    for (int tau = 1; tau <= mMaxLag; ++tau) {
        double sum = 0.0;
        const int count = mWindowSize - tau;
        for (int i = 0; i < count; ++i) {
            double delta = (double)window[i] - (double)window[i + tau];
            sum += delta * delta;
        }
        mDifference[tau] = sum;
    }

    // Cumulative mean normalized difference function.
    mCmndf[0] = 1.0;
    double runningSum = 0.0;
    for (int tau = 1; tau <= mMaxLag; ++tau) {
        runningSum += mDifference[tau];
        mCmndf[tau] = (runningSum > 0.0) ? (mDifference[tau] * (double)tau / runningSum) : 1.0;
    }

    // Absolute threshold: first dip below threshold, refined to its local minimum.
    int tauEstimate = -1;
    for (int tau = 2; tau < mMaxLag; ++tau) {
        if (mCmndf[tau] < kAbsoluteThreshold) {
            while (tau + 1 < mMaxLag && mCmndf[tau + 1] < mCmndf[tau]) {
                ++tau;
            }
            tauEstimate = tau;
            break;
        }
    }

    // Nothing cleared the threshold: fall back to the global minimum and let
    // the resulting (low) confidence value tell the caller to distrust it.
    if (tauEstimate < 0) {
        int bestTau = 2;
        double bestValue = mCmndf[2];
        for (int tau = 3; tau < mMaxLag; ++tau) {
            if (mCmndf[tau] < bestValue) {
                bestValue = mCmndf[tau];
                bestTau = tau;
            }
        }
        tauEstimate = bestTau;
    }

    // Parabolic interpolation around the chosen minimum for sub-sample lag accuracy.
    double refinedTau = (double)tauEstimate;
    double minValue = mCmndf[tauEstimate];
    if (tauEstimate > 0 && tauEstimate < mMaxLag) {
        double y0 = mCmndf[tauEstimate - 1];
        double y1 = mCmndf[tauEstimate];
        double y2 = mCmndf[tauEstimate + 1];
        double denom = y0 - 2.0 * y1 + y2;
        if (std::abs(denom) > 1.0e-12) {
            double shift = std::clamp(0.5 * (y0 - y2) / denom, -1.0, 1.0);
            refinedTau = (double)tauEstimate + shift;
            minValue = y1 - 0.25 * (y0 - y2) * shift;
        }
    }

    if (refinedTau <= 0.0) {
        return result;
    }

    double frequency = mSampleRate / refinedTau;
    if (frequency < kMinFrequencyHz || frequency > kMaxFrequencyHz) {
        return result;
    }

    result.frequencyHz = frequency;
    result.confidence = std::clamp(1.0 - minValue, 0.0, 1.0);
    result.valid = true;
    return result;
}
