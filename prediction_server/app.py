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
from pyod.models.hbos import HBOS

from str_helpers import *

app = Flask(__name__)

@app.route('/init', methods=['GET'])
def init():
    """ Initialize predictor """
    # move old file
    device_uuid = request.args.get('deviceUUID')
    if len(device_uuid) > 0:
        date_time = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

        device_data_folder = config.data_filepath+device_uuid
        if os.path.exists(device_data_folder):
            pass
        else:
            os.makedirs(device_data_folder)

        data_filename = get_data_filename(device_uuid, date_time)

        new_data_file = open(data_filename, "w+")
        new_data_file.close()

        device_model_folder = config.model_filepath + device_uuid
        if(len(device_uuid) != 0 and os.path.exists(device_model_folder)):
            for model_file in os.listdir(device_model_folder):
                os.remove(device_model_folder+"/" + model_file)
        else:
            os.mkdir(device_model_folder)

        with open(get_params_filename(device_uuid, date_time), 'w+') as f:
            args_dict = request.args.to_dict()
            writer = csv.writer(f)
            for k in args_dict.keys():
                writer.writerow((k, args_dict[k]))

        return jsonify({"status" : 0, "datetime": date_time})
    else:
        return jsonify({"status" : 400, "errorMsg": "Invalid DeviceUUID"})

@app.route('/upload', methods=['POST'])
def upload():
    """ Add biosignals to data """
    json_ = request.json
    count = 0
    data_filename = get_data_filename(json_['deviceUUID'], json_['datetime'])
    with open(data_filename, 'a') as f:
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
    device_uuid, date_time = request.args.get('deviceUUID'), request.args.get('datetime')
    data_filename = get_data_filename(device_uuid, date_time)

    with open(data_filename, 'r') as f:
        rows = f.readlines()
    with open(config.awake_filename, 'rb') as f:
        awake_features = pickle.load(f)
    if len(rows) < config.min_train_data_size:
        return jsonify({"status" : 1,
                        "message" : "Not enough training data! %d" % len(rows)})
    raw = np.zeros((len(rows), 3))
    for i in range(len(rows)):
        raw[i] = [int(val) for val in rows[i].strip().split(',')]
    norm = features.normalize(raw)
    temp_features = features.extract_multi_features(norm, step=config.step_size, x_len=config.sample_size)
    baseline_features = features.get_baseline_features(temp_features)
    norm_features = features.get_calibrated_features(temp_features, baseline_features)
    X = np.concatenate((awake_features, norm_features), axis=0)
    X[: ,1] = np.abs(np.random.normal(0, 0.01, len(X)))
    app.logger.info('Training classifier using %d feature sets, each containing %d features' % (X.shape[0], X.shape[1]))
    clf = HBOS(contamination=0.05)
    clf.fit(X)

    model_filename = get_model_filename(device_uuid, date_time)
    with open(model_filename, 'wb') as f:
        pickle.dump(clf, f)

    pred = clf.decision_function(X)
    baseline = {
        'features' : baseline_features,
        'hboss_base' : np.min(pred)
    }

    baseline_filename = get_baseline_filename(device_uuid, date_time)
    with open(baseline_filename, 'wb') as f:
        pickle.dump(baseline, f)

    return jsonify({"status" : 0, "time" : (time.time() - start_time)})

@app.route('/predict', methods=['GET', 'POST'])
def predict():
    """ Predict sleep vs. non-sleep """
    start_time = time.time()

    device_uuid, date_time = request.args.get('deviceUUID'), request.args.get('datetime')
    model_filename = get_model_filename(device_uuid, date_time)
    with open(model_filename, 'rb') as f:
        clf = pickle.load(f)

    baseline_filename = get_baseline_filename(device_uuid, date_time)
    with open(baseline_filename, 'rb') as f:
        baseline = pickle.load(f)

    data_filename = get_data_filename(device_uuid, date_time)
    with open(data_filename, 'r') as f:
        rows = f.readlines()
    if len(rows) < config.prediction_data_size:
        return jsonify({"status" : 1,
                        "message" : "Not enough data! %d" % len(rows)})
    raw = np.zeros((config.prediction_data_size, 3))
    for i, j in zip(range(config.prediction_data_size),
                    range(len(rows) - config.prediction_data_size, len(rows))):
        raw[i] = [int(val) for val in rows[j].strip().split(',')]
    norm = features.normalize(raw)
    temp_features = features.extract_multi_features(norm, step=config.step_size, x_len=config.sample_size)
    X = features.get_calibrated_features(temp_features, baseline['features'])

    """
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
    """

    y = clf.decision_function(X) - baseline['hboss_base']
    mean_sleep = np.mean(y)
    max_sleep = np.max(y)
    curr_time = time.time()

    with open(get_hboss_filename(device_uuid, date_time), 'a+') as f:
        writer = csv.writer(f)
        writer.writerow((mean_sleep, max_sleep, start_time, curr_time))

    return jsonify({"status" : 0,
        "sleep" : list(y),
        "mean_sleep" : mean_sleep,
        "max_sleep" : max_sleep,
        "time" : (curr_time - start_time)
    })

@app.route('/reportTrigger', methods=['POST'])
def report_trigger():
    #open file/write if doesn't exist
    #name is: device_uuid_datetime_triggers
    #csv file format
    # trigger reason, time, legitmate = True/False
    json_ = request.json
    app.logger.info(json_["trigger"])
    triggers_filename = get_report_trigger_filename(json_['deviceUUID'], json_['datetime'])
    with open(triggers_filename, 'a+') as f:
        writer = csv.writer(f)
        writer.writerow((json_["trigger"], str(datetime.datetime.now()), str(json_["legitimate"])))
    return jsonify({"status" : 0})

@app.route('/data', methods=['GET'])
def data():
    device_uuid, date_time = request.args.get('deviceUUID'), request.args.get('datetime')
    data_filename = get_data_filename(device_uuid, date_time)

    with open(data_filename, 'r') as f:
        rows = f.read().splitlines()
    return "||||" + "|".join(rows)

@app.route('/getTriggers', methods=['GET'])
def getTriggers():
    device_uuid, date_time = request.args.get('deviceUUID'), request.args.get('datetime')
    triggers_filename = get_report_trigger_filename(device_uuid, date_time)

    with open(triggers_filename, 'r') as f:
        rows = f.read().splitlines()
    return "||||" + "|".join(rows)

@app.route('/getUsers', methods=['GET'])
def getUsers():
    user_dict = {}
    for device_uuid in os.listdir(config.data_filepath):
        for datetime in os.listdir(config.data_filepath+device_uuid):
            if device_uuid not in user_dict.keys():
                user_dict[device_uuid] = []
            user_dict[device_uuid].append(datetime)
    print(user_dict)
    return json.dumps(user_dict)

@app.route('/getHBOSS', methods=['GET'])
def getHBOSS():
    device_uuid, date_time = request.args.get('deviceUUID'), request.args.get('datetime')

    with open(get_hboss_filename(device_uuid, date_time), 'r') as f:
        rows = f.read().splitlines()
    return "||||"+"|".join(rows)

@app.route('/getParams', methods=['GET'])
def getParams():
    device_uuid, date_time = request.args.get('deviceUUID'), request.args.get('datetime')

    with open(get_params_filename(device_uuid, date_time), 'r') as f:
        txt = f.read()
    return txt

if __name__ == '__main__':
    app.run(host='0.0.0.0')
