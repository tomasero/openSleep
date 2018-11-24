import numpy as np
import pandas as pd
import scipy.signal


def normalize(x):
    x[:,0] = (x[:, 0] - 256) / 320.
    x[:,1] = x[:, 1] / 960.
    x[:,2] = x[:, 2] / 64

    return x

def find_peaks(sig, radius=3, eps=1e-4):
    """ Find local peaks. """
    if np.min(sig) == np.max(sig):
        return np.empty(0)

    peak_inds = []

    i = radius
    while i < (len(sig) - radius):
        if np.abs(sig[i] - max(sig[i - radius:i + radius])) < eps:
            peak_inds.append(i)
        i += 1

    averaged_peak_inds = []
    i = 0
    while i < len(peak_inds):
        j = 0
        while i + j + 1 < len(peak_inds) and (peak_inds[i + j + 1] - peak_inds[i + j]) < 2:
            j += 1
        averaged_peak_inds.append((peak_inds[i] + peak_inds[i + j]) / 2.)
        i += j + 1

    return (np.array(averaged_peak_inds))

def find_peaks2(sig, thresh=0.05):
    i = 0
    peaks = []
    while i < (len(sig) - 1):
        if sig[i + 1] - sig[i] > thresh:
            peaks.append(i)
            i += 4
        i += 1

    return peaks

feature_labels = [
    "Flex Mean",
    #"Flex SD",
    "Flex Diff Clipped",
    "EDA Mean",
    #"EDA SD",
    #"EDA Diffs Mean",
    #"EDA Diffs SD",
    "ECG HR (normalized)",
    "ECG RR Intervals Mean",
    #"ECG RR Intervals SD",
    #"ECG RR 2nd Order Intervals Mean",
    #"ECG RR 2nd Order Intervals SD",
    #"ECG RR 2nd Order Intervals Absolute Mean",
    #"ECG RR 2nd Order Intervals Absolute SD",
    #"ECG LF Power",
    #"ECG HF Power",
    "ECG LF / HF"

]
N_FEATURES = len(feature_labels)
def extract_features(x):
    #flex
    flex_mean = np.mean(x[:, 0])
    flex_sd = np.std(x[:, 0])

    # flex 2nd order
    flex_diffs = [x[i + 1, 0] - x[i, 0] for i in range(x.shape[0] - 1)]
    flex_diffs_mean = np.mean(flex_diffs)
    flex_diffs_sd = np.std(flex_diffs)

    flex_diffs_clipped = flex_diffs_mean * 5e3 if flex_diffs_mean > 1e-4 else 0
    flex_diffs_clipped = flex_diffs_clipped * flex_diffs_clipped

    # eda
    eda_mean = np.mean(x[:, 2])
    eda_sd = np.std(x[:, 2])

    # eda 2nd order
    eda_diffs = [x[i + 1, 2] - x[i, 2] for i in range(x.shape[0] - 1)]
    eda_diffs_mean = np.mean(eda_diffs)
    eda_diffs_sd = np.std(eda_diffs)

    # ecg
    peaks = find_peaks2(x[:, 1])
    if len(peaks):
        # RR intervals (peak intervals)
        rrs = [(peaks[i + 1] - peaks[i]) / 10. for i in range(len(peaks) - 1)]
        rr_mean = np.mean(rrs)
        rr_sd = np.std(rrs)

        hr = 60 / rr_mean
        hr_norm = (min(120, hr) - 40) / 60.

        # second order intervals
        rr_diffs = [rrs[i + 1] - rrs[i] for i in range(len(rrs) - 1)]
        rr_diffs_mean = np.mean(rr_diffs)
        rr_diffs_sd = np.std(rr_diffs)
        rr_diffs_abs_mean = np.mean(np.abs(rr_diffs))
        rr_diffs_abs_sd = np.std(np.abs(rr_diffs))

        rr_diffs_clipped = rr_diffs_mean * 10 if rr_diffs_mean > 0.02 else 0
        rr_diffs_clipped = rr_diffs_clipped * rr_diffs_clipped

        # power spectral density
        f_psd, psd = scipy.signal.periodogram(x[:, 1])
        psds= pd.DataFrame({'freq': f_psd, 'psd':psd})
        lf_power = np.mean(psds[(psds['freq']>0.04) & (psds['freq']<0.15)]['psd'])
        hf_power = np.mean(psds[(psds['freq']<0.4) & (psds['freq']>0.15)]['psd'])
        lf_power_norm = lf_power / (lf_power + hf_power)
        hf_power_norm = hf_power / (lf_power + hf_power)
    else:
        rr_mean = 0
        rr_sd = 0

        hr = 0
        hr_norm = 0

        # second order intervals
        rr_diffs_mean = 0
        rr_diffs_sd = 0
        rr_diffs_abs_mean = 0
        rr_diffs_abs_sd = 0

        rr_diffs_clipped = 0

        # power spectral density
        lf_power = 0
        hf_power = 0

    return [
        flex_mean,
        #flex_diffs_sd,
        flex_diffs_clipped,
        eda_mean,
        #eda_sd,
        #eda_diffs_mean,
        #eda_diffs_sd,
        hr_norm,
        rr_diffs_clipped,
        #rr_sd,
        #rr_diffs_mean,
        #rr_diffs_sd,
        #rr_diffs_abs_mean,
        #rr_diffs_abs_sd,
        #lf_power_norm,
        #hf_power_norm,
        np.log(lf_power / hf_power)
    ]

def extract_multi_features(data, x_len=150, step=30, start=0, end=None):
    if not end:
        end = data.shape[0]
    features = []
    for i in range(start, end-x_len+1, step):
        features.append(extract_features(data[i:i+x_len, ]))
    return np.array(features)

def get_baseline_features(features):
    start = 0
    end = len(features)
    if len(features) > 60:
        start = 60
        if len(features) > 120:
            end = 120
    return features[start:end, ]

def get_calibrated_features(features, calibration_features):
    mean_features = np.mean(calibration_features, axis=0)
    mean_features[1] = 0
    mean_features[4] = 0

    calibrated_features = features - mean_features
    calibrated_features[:, 0] = calibrated_features[:, 0].clip(max=0)
    calibrated_features[:, 3] = 4 * (calibrated_features[:, 3].clip(max=0) ** 2)
    #calibrated_features[:, 5] = calibrated_features[:, 5].clip(max=0)

    return calibrated_features
