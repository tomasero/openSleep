import config

def make_suffix(device_uuid, date_time):
	assert(isinstance(device_uuid, str))
	assert(isinstance(date_time, str))

	return device_uuid + "/" + date_time

def get_data_filename(device_uuid, date_time):
	return config.data_filepath + make_suffix(device_uuid, date_time) + ".csv"

def get_model_filename(device_uuid, date_time):
	return config.model_filepath + device_uuid +"/" + date_time + ".pkl"

def get_baseline_filename(device_uuid, date_time):
	return config.baseline_filepath + device_uuid + "/baseline_"+ date_time +".pkl"

def get_report_trigger_filename(device_uuid, date_time):
	return config.data_filepath + make_suffix(device_uuid, date_time)+"_triggers.csv"

def get_hboss_filename(device_uuid, date_time):
	return config.data_filepath + make_suffix(device_uuid, date_time) + "_hboss" + ".csv"

def get_params_filename(device_uuid, date_time):
	return config.data_filepath + make_suffix(device_uuid, date_time) + "_params" + ".csv"
