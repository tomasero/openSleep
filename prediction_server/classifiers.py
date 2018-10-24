import numpy as np

class SimpleClassifier():
    def __init__(self, feature_importance):
        self.feature_importance = feature_importance
        self.n_features = len(feature_importance)
        self.means = np.empty(self.n_features)
        self.sds = np.empty(self.n_features)

    def fit(self, X):
        assert self.n_features == X.shape[1]
        self.means = np.mean(X, axis=0)
        self.sds = np.std(X, axis=0)

    def predict(self, X):
        y = np.zeros(len(X))
        for i in range(len(X)):
            zscores = np.zeros(self.n_features)
            for feature in range(self.n_features):
                zscores[feature] = (X[i, feature] - self.means[feature]) / self.sds[feature]
            y[i] = int(np.sqrt(np.dot(self.feature_importance, zscores ** 2) / self.n_features) >= 6)
        return y
