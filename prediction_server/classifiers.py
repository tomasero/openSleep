import numpy as np
from scipy.spatial.distance import mahalanobis

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

    def predict(self, X, feature_importance):
        y = np.zeros(len(X))
        u = np.multiply(self.means, feature_importance)
        for i in range(len(X)):
            v = np.multiply(X[i], feature_importance)
            y[i] = min(50, mahalanobis(u, v, self.cov_inv))
        return y
