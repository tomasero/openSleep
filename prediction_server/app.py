#!/usr/bin/env python
# # -*- coding: utf-8 -*-
""" Flask API for predicting probability of survival """
import csv
import datetime
import json
import os
import shutil
import sys
from flask import Flask, jsonify, request, render_template, url_for
import pandas as pd
import numpy as np
import pickle
import time

import config
import features
from classifiers import SimpleClassifier

app = Flask(__name__)

@app.route('/init', methods=['GET'])
def init():
    """ Initialize predictor """
    # move old file
    if os.path.isfile(config.train_data_filename) and os.stat(config.train_data_filename).st_size > 0:
        filename = os.path.splitext(config.train_data_filename)[0]
        filename += datetime.datetime.now().strftime("_%Y%m%d_%H%M%S")
        filename += ".csv"
        shutil.move(config.train_data_filename, filename)

    return jsonify({"status" : 0})

@app.route('/upload_train_data', methods=['POST'])
def upload_train_data():
    """ Add biosignals to training data """
    json_ = request.json
    count = 0
    with open(config.train_data_filename, 'a') as f:
        assert len(json_['flex']) == len(json_['ecg']) == len(json_['eda'])
        writer = csv.writer(f)
        for row in zip(json_['flex'], json_['ecg'], json_['eda']):
            writer.writerow(row)
            count += 1

    app.logger.info('Written %d data points' % count)
    return jsonify({"status" : 0})

@app.route('/train', methods=['GET'])
def train():
    """ Train the predictor on the data collected """
    start_time = time.time()
    json_ = request.json
    with open(config.train_data_filename, 'r') as f:
        rows = f.readlines()
    if len(rows) < config.min_train_data_size:
        return jsonify({"status" : 1,
                        "message" : "Training data size too small! %d" % len(rows)})
    raw = np.zeros((len(rows), 3))
    for i in range(len(rows)):
        raw[i] = [int(val) for val in rows[i].strip().split(',')]
    norm = features.normalize(raw)
    X = features.extract_multi_features(norm, step=config.step_size, x_len=config.sample_size)
    clf = SimpleClassifier(features.feature_importance)
    app.logger.info('Training classifier using %d feature sets, each containing %d features' % (X.shape[0], X.shape[1]))
    clf.fit(X)
    with open(config.model_filename, 'wb') as f:
        pickle.dump(clf, f)

    return jsonify({"status" : 0, "time" : (time.time() - start_time)})

@app.route('/predict', methods=['POST'])
def predict():
    """ Predict sleep vs. non-sleep """
    start_time = time.time()
    json_ = request.json
    with open(config.model_filename, 'rb') as f:
        clf = pickle.load(f)

    assert len(json_['flex']) == len(json_['ecg']) == len(json_['eda'])
    raw = np.zeros((len(json_['flex']), 3))
    i = 0
    for row in zip(json_['flex'], json_['ecg'], json_['eda']):
        raw[i] = row
        i += 1
    norm = features.normalize(raw)
    X = features.extract_multi_features(norm, step=config.step_size, x_len=config.sample_size)

    y = clf.predict(X)

    return jsonify({"sleep" : list(y),
        "mean_sleep" : np.mean(y),
        "time" : (time.time() - start_time)
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0')
