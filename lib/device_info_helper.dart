import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

 saveDevice() async {
  //Create an instance of device info plugin
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //Unique id for each device
  String? deviceId;
  Map<String,dynamic> ?deviceData;
  if(Platform.isAndroid){
    //instantiate deviceInfo
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
    deviceData = {
      'version.baseOS': androidInfo.version.baseOS,
      "platform": "android",
      'model': androidInfo.model,
      'device': androidInfo.device,

    };
  }
  if(Platform.isIOS){
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor;
    deviceData = {
      'version.baseOS': iosInfo.systemVersion,
      "platform": "ios",
      'model': iosInfo.model,
      'device': iosInfo.name,
    };
  }

  return deviceData;

}