import config

def make_suffix(device_uuid, date_time):
	assert(isinstance(device_uuid, str))
	assert(isinstance(date_time, str))

	return device_uuid + "_" + date_time

def get_data_filename(device_uuid, date_time):
	return config.data_filepath + make_suffix(device_uuid, date_time) + ".csv"

def get_model_filename(device_uuid, date_time):
	return config.model_filepath + device_uuid +"/" + date_time + ".pkl"

def get_baseline_filename(device_uuid, date_time):
	return config.baseline_filepath + device_uuid + "/baseline_"+ date_time +".pkl"
