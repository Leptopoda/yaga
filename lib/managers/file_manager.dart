import 'package:logger/logger.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';

class FileManager extends FileManagerBase {
  Logger _logger = Logger();
  RxCommand<NcFile, NcFile> _getImageCommand;

  RxCommand<NcFile, NcFile> downloadImageCommand;
  RxCommand<NcFile, NcFile> updateImageCommand;

  RxCommand<NcFile, NcFile> removeLocal;
  RxCommand<NcFile, NcFile> removeTmp;

  NextCloudService _nextCloudService;
  LocalFileService _localFileService;

  FileManager(this._nextCloudService, this._localFileService) {
    _getImageCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    _getImageCommand
        .asyncMap((ncFile) => this
                ._nextCloudService
                .downloadImage(ncFile.uri)
                .then((value) async {
              ncFile.localFile = await _localFileService.createFile(
                  file: ncFile.localFile,
                  bytes: value,
                  lastModified: ncFile.lastModified);
              return ncFile;
            }, onError: (err) {
              return null;
            }))
        .where((event) => event != null)
        .listen((value) => updateImageCommand(value));

    downloadImageCommand = RxCommand.createSync((param) => param);
    downloadImageCommand.listen((ncFile) {
      if (ncFile.localFile != null && ncFile.localFile.existsSync()) {
        updateImageCommand(ncFile);
        return;
      }
      this._getImageCommand(ncFile);
    });

    updateImageCommand = RxCommand.createSync((param) => param);

    removeLocal = RxCommand.createSync((param) => param);
    removeLocal.listen((value) {
      _logger.d("Removing local file ${value.localFile.path}");
      _localFileService.deleteFile(value.localFile);
    });

    removeTmp = RxCommand.createSync((param) => param);
    removeTmp.listen((value) {
      _logger.d("Removing preview file ${value.previewFile.path}");
      _localFileService.deleteFile(value.previewFile);
    });
  }
}
