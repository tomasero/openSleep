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
    if os.path.isfile(config.data_filename) and os.stat(config.data_filename).st_size > 0:
        filename = os.path.splitext(config.data_filename)[0]
        filename += datetime.datetime.now().strftime("_%Y%m%d_%H%M%S")
        filename += ".csv"
        shutil.move(config.data_filename, filename)

    # delete model file
    os.remove(config.model_filename)

    return jsonify({"status" : 0})

@app.route('/upload', methods=['POST'])
def upload():
    """ Add biosignals to data """
    json_ = request.json
    count = 0
    with open(config.data_filename, 'a') as f:
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
    with open(config.data_filename, 'r') as f:
        rows = f.readlines()
    if len(rows) < config.min_train_data_size:
        return jsonify({"status" : 1,
                        "message" : "Not enough training data! %d" % len(rows)})
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

@app.route('/predict', methods=['GET', 'POST'])
def predict():
    """ Predict sleep vs. non-sleep """
    start_time = time.time()
    with open(config.model_filename, 'rb') as f:
        clf = pickle.load(f)

    with open(config.data_filename, 'r') as f:
        rows = f.readlines()
    if len(rows) < config.prediction_data_size:
        return jsonify({"status" : 1,
                        "message" : "Not enough data! %d" % len(rows)})
    raw = np.zeros((config.prediction_data_size, 3))
    for i, j in zip(range(config.prediction_data_size),
                    range(len(rows) - config.prediction_data_size, len(rows))):
        raw[i] = [int(val) for val in rows[j].strip().split(',')]
    norm = features.normalize(raw)
    X = features.extract_multi_features(norm, step=config.step_size, x_len=config.sample_size)

    json_ = request.json
    n_features = X.shape[1]
    feature_importance = np.zeros(n_features)
    if json_ and 'feature_importance' in json_:
        feature_importance[0] = json_['feature_importance']['flex']
        feature_importance[1] = json_['feature_importance']['eda']
        for i in range(2, n_features):
            feature_importance[i] = json_['feature_importance']['ecg'] / float(n_features - 2)
    else:
        feature_importance[0] = 1 / 3.
        feature_importance[1] = 1 / 3.
        for i in range(2, n_features):
            feature_importance[i] = 1 / float(3 * (n_features - 2))

    y = clf.predict(X, feature_importance)

    return jsonify({"status" : 0,
        "sleep" : list(y),
        "mean_sleep" : np.mean(y),
        "time" : (time.time() - start_time)
    })

@app.route('/data', methods=['GET'])
def data():
    filename = os.path.splitext(config.data_filename)[0]
    filename += request.args.get('suffix', default='')
    filename += ".csv"
    with open(filename, 'r') as f:
        rows = f.read().splitlines()
    return "||||" + "|".join(rows)

if __name__ == '__main__':
    app.run(host='0.0.0.0')
