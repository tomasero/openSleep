#include <queue>

#import <Foundation/Foundation.h>

#include <node_buffer.h>

#include "XpcConnection.h"
#include <nan.h>

using namespace v8;

Nan::Persistent<FunctionTemplate> XpcConnection::constructor_template;

NAN_MODULE_INIT(XpcConnection::Init) {
  Nan::HandleScope scope;

  Local<FunctionTemplate> tmpl = Nan::New<FunctionTemplate>(New);
  constructor_template.Reset(tmpl);

  tmpl->InstanceTemplate()->SetInternalFieldCount(1);
  tmpl->SetClassName(Nan::New("XpcConnection").ToLocalChecked());

  Nan::SetPrototypeMethod(tmpl, "setup", Setup);
  Nan::SetPrototypeMethod(tmpl, "sendMessage", SendMessage);

  target->Set(Nan::New("XpcConnection").ToLocalChecked(), tmpl->GetFunction());
}

XpcConnection::XpcConnection(std::string serviceName) :
  node::ObjectWrap(),
  serviceName(serviceName) {

  this->asyncHandle = new uv_async_t;

  uv_async_init(uv_default_loop(), this->asyncHandle, (uv_async_cb)XpcConnection::AsyncCallback);
  uv_mutex_init(&this->eventQueueMutex);

  this->asyncHandle->data = this;
}

XpcConnection::~XpcConnection() {
  uv_close((uv_handle_t*)this->asyncHandle, (uv_close_cb)XpcConnection::AsyncCloseCallback);

  uv_mutex_destroy(&this->eventQueueMutex);
}

void XpcConnection::setup() {
  this->dispatchQueue = dispatch_queue_create(this->serviceName.c_str(), 0);
  this->xpcConnnection = xpc_connection_create_mach_service(this->serviceName.c_str(), this->dispatchQueue, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);

  xpc_connection_set_event_handler(this->xpcConnnection, ^(xpc_object_t event) {
    xpc_retain(event);
    this->queueEvent(event);
  });

  xpc_connection_resume(this->xpcConnnection);
}

void XpcConnection::sendMessage(xpc_object_t message) {
  xpc_connection_send_message(this->xpcConnnection, message);
}

void XpcConnection::queueEvent(xpc_object_t event) {

  uv_mutex_lock(&this->eventQueueMutex);
  eventQueue.push(event);
  uv_mutex_unlock(&eventQueueMutex);

  uv_async_send(this->asyncHandle);
}

NAN_METHOD(XpcConnection::New) {
  Nan::HandleScope scope;
  std::string serviceName = "";

  if (info.Length() > 0 && info[0]->IsString()) {
    Nan::Utf8String arg0(info[0]);

    serviceName = *arg0;
  }

  XpcConnection* p = new XpcConnection(serviceName);
  p->Wrap(info.This());
  p->This.Reset(info.This());
  info.GetReturnValue().Set(info.This());
}


NAN_METHOD(XpcConnection::Setup) {
  Nan::HandleScope scope;

  XpcConnection* p = node::ObjectWrap::Unwrap<XpcConnection>(info.This());

  p->setup();

  info.GetReturnValue().SetUndefined();
}

xpc_object_t XpcConnection::ValueToXpcObject(Local<Value> value) {
  xpc_object_t xpcObject = NULL;

  if (value->IsInt32() || value->IsUint32()) {
    xpcObject = xpc_int64_create(value->IntegerValue());
  } else if (value->IsString()) {
    Nan::Utf8String valueString(value);

    xpcObject = xpc_string_create(*valueString);
  } else if (value->IsArray()) {
    Local<Array> valueArray = Local<Array>::Cast(value);

    xpcObject = XpcConnection::ArrayToXpcObject(valueArray);
  } else if (node::Buffer::HasInstance(value)) {
    Local<Object> valueObject = value->ToObject();

    if (valueObject->HasRealNamedProperty(Nan::New("isUuid").ToLocalChecked())) {
      uuid_t *uuid = (uuid_t *)node::Buffer::Data(valueObject);

      xpcObject = xpc_uuid_create(*uuid);
    } else {
      xpcObject = xpc_data_create(node::Buffer::Data(valueObject), node::Buffer::Length(valueObject));
    }
  } else if (value->IsObject()) {
    Local<Object> valueObject = value->ToObject();

    xpcObject = XpcConnection::ObjectToXpcObject(valueObject);
  } else {
  }

  return xpcObject;
}

xpc_object_t XpcConnection::ObjectToXpcObject(Local<Object> object) {
  xpc_object_t xpcObject = xpc_dictionary_create(NULL, NULL, 0);

  Local<Array> propertyNames = object->GetPropertyNames();

  for(uint32_t i = 0; i < propertyNames->Length(); i++) {
    Local<Value> propertyName = propertyNames->Get(i);

    if (propertyName->IsString()) {
      Nan::Utf8String propertyNameString(propertyName);

      Local<Value> propertyValue = object->GetRealNamedProperty(propertyName->ToString());

      xpc_object_t xpcValue = XpcConnection::ValueToXpcObject(propertyValue);
      xpc_dictionary_set_value(xpcObject, *propertyNameString, xpcValue);
      if (xpcValue) {
        xpc_release(xpcValue);
      }
    }
  }

  return xpcObject;
}

xpc_object_t XpcConnection::ArrayToXpcObject(Local<Array> array) {
  xpc_object_t xpcArray = xpc_array_create(NULL, 0);

  for(uint32_t i = 0; i < array->Length(); i++) {
    Local<Value> value = array->Get(i);

    xpc_object_t xpcValue = XpcConnection::ValueToXpcObject(value);
    xpc_array_append_value(xpcArray, xpcValue);
    if (xpcValue) {
      xpc_release(xpcValue);
    }
  }

  return xpcArray;
}

Local<Value> XpcConnection::XpcObjectToValue(xpc_object_t xpcObject) {
  Local<Value> value;

  xpc_type_t valueType = xpc_get_type(xpcObject);

  if (valueType == XPC_TYPE_INT64) {
    value = Nan::New((int32_t)xpc_int64_get_value(xpcObject));
  } else if(valueType == XPC_TYPE_STRING) {
    value = Nan::New(xpc_string_get_string_ptr(xpcObject)).ToLocalChecked();
  } else if(valueType == XPC_TYPE_DICTIONARY) {
    value = XpcConnection::XpcDictionaryToObject(xpcObject);
  } else if(valueType == XPC_TYPE_ARRAY) {
    value = XpcConnection::XpcArrayToArray(xpcObject);
  } else if(valueType == XPC_TYPE_DATA) {
    value = Nan::CopyBuffer((char *)xpc_data_get_bytes_ptr(xpcObject), xpc_data_get_length(xpcObject)).ToLocalChecked();
  } else if(valueType == XPC_TYPE_UUID) {
    value = Nan::CopyBuffer((char *)xpc_uuid_get_bytes(xpcObject), sizeof(uuid_t)).ToLocalChecked();
  } else {
    NSLog(@"XpcObjectToValue: Could not convert to value!, %@", xpcObject);
  }

  return value;
}

Local<Object> XpcConnection::XpcDictionaryToObject(xpc_object_t xpcDictionary) {
  Local<Object> object = Nan::New<Object>();

  xpc_dictionary_apply(xpcDictionary, ^bool(const char *key, xpc_object_t value) {
    object->Set(Nan::New<String>(key).ToLocalChecked(), XpcConnection::XpcObjectToValue(value));

    return true;
  });

  return object;
}

Local<Array> XpcConnection::XpcArrayToArray(xpc_object_t xpcArray) {
  Local<Array> array = Nan::New<Array>();

  xpc_array_apply(xpcArray, ^bool(size_t index, xpc_object_t value) {
    array->Set(Nan::New<Number>(index), XpcConnection::XpcObjectToValue(value));

    return true;
  });

  return array;
}

void XpcConnection::AsyncCallback(uv_async_t* handle) {
  XpcConnection *xpcConnnection = (XpcConnection*)handle->data;

  xpcConnnection->processEventQueue();
}

void XpcConnection::AsyncCloseCallback(uv_async_t* handle) {
  delete handle;
}

void XpcConnection::processEventQueue() {
  uv_mutex_lock(&this->eventQueueMutex);

  Nan::HandleScope scope;

  while (!this->eventQueue.empty()) {
    xpc_object_t event = this->eventQueue.front();
    this->eventQueue.pop();

    xpc_type_t eventType = xpc_get_type(event);
    if (eventType == XPC_TYPE_ERROR) {
      const char* message = "unknown";

      if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
        message = "connection interrupted";
      } else if (event == XPC_ERROR_CONNECTION_INVALID) {
        message = "connection invalid";
      }

      Local<Value> argv[2] = {
        Nan::New("error").ToLocalChecked(),
        Nan::New(message).ToLocalChecked()
      };

      Nan::MakeCallback(Nan::New<Object>(this->This), Nan::New("emit").ToLocalChecked(), 2, argv);
    } else if (eventType == XPC_TYPE_DICTIONARY) {
      Local<Object> eventObject = XpcConnection::XpcDictionaryToObject(event);

      Local<Value> argv[2] = {
        Nan::New("event").ToLocalChecked(),
        eventObject
      };

      Nan::MakeCallback(Nan::New<Object>(this->This), Nan::New("emit").ToLocalChecked(), 2, argv);
    }

    xpc_release(event);
  }

  uv_mutex_unlock(&this->eventQueueMutex);
}

NAN_METHOD(XpcConnection::SendMessage) {
  Nan::HandleScope scope;
  XpcConnection* p = node::ObjectWrap::Unwrap<XpcConnection>(info.This());

  if (info.Length() > 0) {
    Local<Value> arg0 = info[0];
    if (arg0->IsObject()) {
      Local<Object> object = Local<Object>::Cast(arg0);

      xpc_object_t message = XpcConnection::ObjectToXpcObject(object);
      p->sendMessage(message);
      xpc_release(message);
    }
  }

  info.GetReturnValue().SetUndefined();
}

NODE_MODULE(binding, XpcConnection::Init);
