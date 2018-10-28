import numpy as np
import pandas as pd
import scipy.signal


def normalize(x):
    x[:,0] = (x[:, 0] - 200) / 500.
    x[:,1] = scipy.signal.detrend(x[:, 1]) / 960.
    x[:,2] = np.log(x[:, 2]) / 6.

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

feature_labels = [
    "Flex Mean",
    #"Flex SD",
    "EDA Mean",
    #"EDA SD",
    #"EDA Diffs Mean",
    #"EDA Diffs SD",
    "ECG HR (bpm)",
    #"ECG RR Intervals Mean",
    #"ECG RR Intervals SD",
    #"ECG RR 2nd Order Intervals Mean",
    #"ECG RR 2nd Order Intervals SD",
    #"ECG RR 2nd Order Intervals Absolute Mean",
    #"ECG RR 2nd Order Intervals Absolute SD",
    "ECG LF Power",
    #"ECG HF Power",
    #"ECG LF / HF"

]
N_FEATURES = len(feature_labels)
feature_importance = np.array([ 0.39891696,  0.33212996,  0.05234657,  0.2166065 ])
def extract_features(x):
    #flex
    flex_mean = np.mean(x[:, 0])
    flex_sd = np.std(x[:, 0])

    # eda
    eda_mean = np.mean(x[:, 2])
    eda_sd = np.std(x[:, 2])

    # eda 2nd order
    eda_diffs = [x[i + 1, 2] - x[i, 2] for i in range(len(x) - 1)]
    eda_diffs_mean = np.mean(eda_diffs)
    eda_diffs_sd = np.std(eda_diffs)

    # ecg
    peaks = find_peaks(x[:, 1])
    # average heart rate
    hr = len(peaks) * (600. / len(x))

    # RR intervals (peak intervals)
    rrs = [(peaks[i + 1] - peaks[i]) / 10. for i in range(len(peaks) - 1)]
    rr_mean = np.mean(rrs)
    rr_sd = np.std(rrs)

    # second order intervals
    rr_diffs = [rrs[i + 1] - rrs[i] for i in range(len(rrs) - 1)]
    rr_diffs_mean = np.mean(rr_diffs)
    rr_diffs_sd = np.std(rr_diffs)
    rr_diffs_abs_mean = np.mean(np.abs(rr_diffs))
    rr_diffs_abs_sd = np.std(np.abs(rr_diffs))

    # power spectral density
    f_psd, psd = scipy.signal.periodogram(x[:, 1])
    psds= pd.DataFrame({'freq': f_psd, 'psd':psd})
    lf_power = np.mean(psds[(psds['freq']>0.05) & (psds['freq']<0.2)]['psd'])
    hf_power = np.mean(psds[(psds['freq']<0.35) & (psds['freq']>0.2)]['psd'])

    return [
        flex_mean,
        #flex_sd,
        eda_mean,
        #eda_sd,
        #eda_diffs_mean,
        #eda_diffs_sd,
        hr,
        #rr_mean,
        #rr_sd,
        #rr_diffs_mean,
        #rr_diffs_sd,
        #rr_diffs_abs_mean,
        #rr_diffs_abs_sd,
        lf_power,
        #hf_power,
        #f_power / hf_power
    ]

def extract_multi_features(data, x_len=150, step=30, start=0, end=None):
    if not end:
        end = data.shape[0]
    features = []
    for i in range(start, end-x_len+1, step):
        features.append(extract_features(data[i:i+x_len, ]))
    return np.array(features)
