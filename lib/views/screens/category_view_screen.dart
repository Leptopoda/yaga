import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/model/category_view_config.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/preferences/preference.dart';
import 'package:yaga/model/preferences/uri_preference.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/model/route_args/settings_screen_arguments.dart';
import 'package:yaga/services/shared_preferences_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/settings_screen.dart';
import 'package:yaga/views/widgets/image_search.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/views/widgets/image_views/category_view_exp.dart';
import 'package:yaga/views/widgets/image_view_container.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';
import 'package:yaga/views/widgets/yaga_bottom_nav_bar.dart';
import 'package:yaga/views/widgets/yaga_drawer.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';

enum CategoryViewMenu { settings }

abstract class CategoryViewScreen extends StatefulWidget {
  final CategoryViewConfig _categoryViewConfig;

  CategoryViewScreen(this._categoryViewConfig);

  @override
  _CategoryViewScreenState createState() => _CategoryViewScreenState();
}

class _CategoryViewScreenState extends State<CategoryViewScreen>
    with AutomaticKeepAliveClientMixin<CategoryViewScreen> {
  final List<Preference> _defaultViewPreferences = [];
  ViewConfiguration _viewConfig;

  // GeneralViewConfig _generalViewConfig;

  StreamSubscription<UriPreference> _updateUriSubscription;
  FileListLocalManager _fileListLocalManager;

  @override
  void initState() {
    this._viewConfig = ViewConfiguration(
      route: widget._categoryViewConfig.pref,
      defaultView: CategoryViewExp.viewKey,
      onFolderTap: null,
      onFileTap: (List<NcFile> files, int index) => Navigator.pushNamed(
        context,
        ImageScreen.route,
        arguments: ImageScreenArguments(files, index),
      ),
    );

    this
        ._defaultViewPreferences
        .add(widget._categoryViewConfig.generalViewConfig.general);
    this
        ._defaultViewPreferences
        .add(widget._categoryViewConfig.generalViewConfig.path);
    this._defaultViewPreferences.add(this._viewConfig.section);
    this._defaultViewPreferences.add(this._viewConfig.recursive);
    this._defaultViewPreferences.add(this._viewConfig.view);

    //todo: refactor
    getIt.get<NextCloudManager>().logoutCommand.listen((value) => getIt
        .get<SettingsManager>()
        .persistStringSettingCommand(
            widget._categoryViewConfig.generalViewConfig.path.rebuild((b) => b
              ..value = getIt.get<SystemLocationService>().externalAppDirUri)));

    //todo: is it still necessary for tab to be a stateful widget?
    //image state wrapper ist a widget local manager
    this._fileListLocalManager = new FileListLocalManager(
        getIt
            .get<SharedPreferencesService>()
            .loadPreferenceFromString(
                widget._categoryViewConfig.generalViewConfig.path)
            .value,
        getIt
            .get<SharedPreferencesService>()
            .loadPreferenceFromBool(this._viewConfig.recursive));

    //todo: this could be moved into imageStateWrapper
    _updateUriSubscription = getIt
        .get<SettingsManager>()
        .updateSettingCommand
        .where((event) =>
            event.key == widget._categoryViewConfig.generalViewConfig.path.key)
        .map((event) => event as UriPreference)
        .listen((event) {
      this._fileListLocalManager.refetch(uri: event.value);
    });

    this._fileListLocalManager.initState();
    super.initState();
  }

  @override
  void dispose() {
    _updateUriSubscription.cancel();
    this._fileListLocalManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          widget._categoryViewConfig.title,
          overflow: TextOverflow.fade,
        ),
        actions: <Widget>[
          //todo: image search button goes here
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: ImageSearch(_fileListLocalManager, this._viewConfig),
            ),
          ),
          YagaPopupMenuButton<CategoryViewMenu>(
            this._buildPopupMenu,
            this._popupMenuHandler,
          ),
        ],
      ),
      drawer: widget._categoryViewConfig.hasDrawer ? YagaDrawer() : null,
      body: ImageViewContainer(
          fileListLocalManager: this._fileListLocalManager,
          viewConfig: this._viewConfig),
      bottomNavigationBar:
          YagaBottomNavBar(widget._categoryViewConfig.selectedTab),
    );
  }

  void _popupMenuHandler(BuildContext context, CategoryViewMenu result) {
    Navigator.pushNamed(
      context,
      SettingsScreen.route,
      arguments: new SettingsScreenArguments(
        preferences: _defaultViewPreferences,
      ),
    );
  }

  List<PopupMenuEntry<CategoryViewMenu>> _buildPopupMenu(BuildContext context) {
    return [
      PopupMenuItem(
        child: ListMenuEntry(Icons.settings, "Settings"),
        value: CategoryViewMenu.settings,
      ),
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
