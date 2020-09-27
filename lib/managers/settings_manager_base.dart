import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/preference.dart';

abstract class SettingsManagerBase {
  RxCommand<Preference, Preference> updateSettingCommand;

  SettingsManagerBase() {
    updateSettingCommand = RxCommand.createSync((param) => param);
  }
}