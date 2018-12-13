# number of data points the data must have in order to train
min_train_data_size = 300
# number of data points to use for prediction
prediction_data_size = 200

# where to locally store the data
# all backups will have the same path, with an added suffix
data_filepath = "data/"
# where to locally store the trained model
model_filepath = "models/"
# where to locally store the awake features for the population
awake_filename = "awake.pkl"
# where to locally store the baseline features for the session
baseline_filepath = "models/"

# how many data points to use to extract one feature set
sample_size = 150
# step size when extracting features
step_size = 10
