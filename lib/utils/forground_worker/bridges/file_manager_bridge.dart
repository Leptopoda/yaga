import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';

class FileManagerBridge {
  final FileManager _fileManager;
  final ForegroundWorker _worker;

  FileManagerBridge(this._fileManager, this._worker) {
    //todo: this does not work since we can not tell which list should receive the event
    this
        ._worker
        .isolateResponseCommand
        .where((event) => event is FileUpdateMsg)
        .listen((event) =>
            _fileManager.updateFileList((event as FileUpdateMsg).file));
  }
}
