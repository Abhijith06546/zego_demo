import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'zpns_config.dart';

@JS('initZPNs')
external void _initZPNs(JSObject config);

@JS('unregisterZPNs')
external void _unregisterZPNs();

class ZPNsService {
  static void register() {
    _initZPNs(JSObject()
      ..setProperty('apiKey'.toJS,            ZPNsConfig.apiKey.toJS)
      ..setProperty('authDomain'.toJS,        ZPNsConfig.authDomain.toJS)
      ..setProperty('projectId'.toJS,         ZPNsConfig.projectId.toJS)
      ..setProperty('storageBucket'.toJS,     ZPNsConfig.storageBucket.toJS)
      ..setProperty('messagingSenderId'.toJS, ZPNsConfig.messagingSenderId.toJS)
      ..setProperty('appId'.toJS,             ZPNsConfig.appId.toJS)
      ..setProperty('measurementId'.toJS,     ZPNsConfig.measurementId.toJS)
      ..setProperty('vapidKey'.toJS,          ZPNsConfig.vapidKey.toJS));
  }

  static void unregister() {
    _unregisterZPNs();
  }
}
