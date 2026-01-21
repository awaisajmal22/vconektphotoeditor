import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStorage() async {
    return await Permission.storage.request().isGranted;
  }

  static Future<bool> requestCamera() async {
    return await Permission.camera.request().isGranted;
  }
}