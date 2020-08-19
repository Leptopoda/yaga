import 'dart:io';

import 'package:mime/mime.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaga/managers/local_file_manager.dart';
import 'package:yaga/services/service.dart';

class LocalFileService extends Service<LocalFileService>{
  Future<File> createFile({@required File file, @required List<int> bytes, DateTime lastModified}) async {
    logger.d("Creating file ${file.path}");
    await file.create(recursive: true);
    File res = await file.writeAsBytes(bytes, flush: true);
    if(lastModified != null) {
      await res.setLastModified(lastModified);
    }
    return res;
  }

  //todo: refactor when adding remote delete function
  void deleteFile(File file) {
    //todo: null exception comes from webview cache files
    //todo: subtask1: local files in cache and default app dir should be in a user@cloud.bla folder
    //todo: subtask2: check if file is null before delete --> done
    //todo: subtask3: webview should not cache data
    if(file != null && file.existsSync()) {
      file.deleteSync();
    }
  }

  Stream<FileSystemEntity> list(Directory directory) {
    return Permission.storage.request().asStream()
      .where((permissionState) => permissionState.isGranted)
      .flatMap((_) => directory.exists().asStream())
      .where((exists) => exists)
      .flatMap((_) => directory.list(recursive: false, followLinks: false))
      .where((event) => event is Directory || _checkMimeType(event.path));
  }

  //todo: is this filtering here at the right place?
  bool _checkMimeType(String path) {
    String type = lookupMimeType(path);
    return type != null && type.startsWith("image");
  }
}