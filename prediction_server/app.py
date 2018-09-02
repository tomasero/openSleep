#!/usr/bin/env python
# # -*- coding: utf-8 -*-
""" Flask API for predicting probability of survival """
import json
import sys
from flask import Flask, jsonify, request, render_template, url_for
from sklearn.externals import joblib
import pandas as pd
import numpy as np

try:
    model = joblib.load('random_forest.mdl')
except:
    print("Error loading application. Missing model file?")
    sys.exit(0)

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    """ Predict sleep vs. non-sleep """
    json_ = request.json
    df = pd.DataFrame(json_)

    print(df)

    return jsonify({"sleep" : 1})

if __name__ == '__main__':
    app.run(host='0.0.0.0')
