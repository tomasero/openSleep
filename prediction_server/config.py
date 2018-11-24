# number of data points the data must have in order to train
min_train_data_size = 300
# number of data points to use for prediction
prediction_data_size = 200

# where to locally store the data
# all backups will have the same path, with an added suffix
data_filename = "data/data.csv"
# where to locally store the trained model
model_filename = "model.pkl"
# where to locally store the awake features for the population
awake_filename = "awake.pkl"
# where to locally store the baseline features for the session
baseline_filename = "baseline.pkl"

# how many data points to use to extract one feature set
sample_size = 150
# step size when extracting features
step_size = 10
