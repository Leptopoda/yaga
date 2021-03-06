import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/logger.dart';

abstract class FileManagerBase {
  Logger _logger = getLogger(FileManagerBase);

  RxCommand<NcFile, NcFile> updateFileList;

  @protected
  Map<String, FileSubManager> _fileSubManagers = Map();

  FileManagerBase() {
    updateFileList = RxCommand.createSync((param) => param);
  }

  void registerFileManager(FileSubManager fileSubManager) {
    this
        ._fileSubManagers
        .putIfAbsent(fileSubManager.scheme, () => fileSubManager);
  }

  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    return this._fileSubManagers[uri.scheme].listFiles(uri).flatMap((file) =>
        file.isDirectory && recursive
            ? this.listFiles(file.uri, recursive: recursive)
            : Stream.value(file));
  }

  Stream<FileListResponse> listFileLists(String requestKey, Uri uri,
      {bool recursive = false}) {
    return this
        ._fileSubManagers[uri.scheme]
        .listFileList(uri, recursive: recursive)
        .map((event) => FileListResponse(requestKey, uri, recursive, event));
  }
}
