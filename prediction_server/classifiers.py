import numpy as np
from scipy.spatial.distance import mahalanobis

THRESHOLD = 6

class SimpleClassifier():
    def __init__(self, feature_importance):
        self.feature_importance = feature_importance
        self.n_features = len(feature_importance)
        self.means = np.empty(self.n_features)

    def fit(self, X):
        assert self.n_features == X.shape[1]
        self.means = np.mean(X, axis=0)
        noise = np.random.normal(0, 0.01, X.shape)
        self.cov_inv = np.linalg.inv(np.cov(X + noise, rowvar=0))
        self.u = np.multiply(self.means, self.feature_importance)

    def predict(self, X):
        y = np.zeros(len(X))
        for i in range(len(X)):
            v = np.multiply(X[i], self.feature_importance)
            y[i] = min(50, mahalanobis(self.u, v, self.cov_inv))
        return y
