import 'package:flutter/material.dart';
import 'package:yaga/managers/navigation_manager.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/services/intent_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';
import 'package:yaga/views/widgets/image_views/nc_list_view.dart';
import 'package:yaga/views/widgets/image_views/utils/view_configuration.dart';
import 'package:yaga/views/widgets/yaga_bottom_nav_bar.dart';
import 'package:yaga/views/widgets/yaga_drawer.dart';

class BrowseView extends StatelessWidget {
  final String _pref = "browse_tab";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(_getTitle() ?? "Nextcloud Yaga"),
      ),
      drawer: YagaDrawer(),
      body: StreamBuilder(
          stream: getIt.get<NextCloudManager>().updateLoginStateCommand,
          builder: (context, snapshot) {
            List<ListTile> children = [];

            children.add(
              ListTile(
                isThreeLine: false,
                leading: AvatarWidget.phone(),
                title: Text("Internal Memory"),
                onTap: () => getIt
                    .get<NavigationManager>()
                    .showDirectoryNavigation(_getArgs(
                      context,
                      getIt.get<SystemLocationService>().getOrigin(),
                    )),
              ),
            );

            if (getIt.get<NextCloudService>().isLoggedIn()) {
              Uri origin = getIt.get<NextCloudService>().getOrigin();
              children.add(ListTile(
                isThreeLine: false,
                leading: AvatarWidget.command(
                  getIt.get<NextCloudManager>().updateAvatarCommand,
                ),
                title: Text(origin.authority),
                onTap: () => getIt
                    .get<NavigationManager>()
                    .showDirectoryNavigation(_getArgs(context, origin)),
              ));
            }

            return ListView(
              children: children,
            );
          }),
      bottomNavigationBar: YagaBottomNavBar(YagaHomeTab.folder),
    );
  }

  //todo: unify this
  String _getTitle() {
    if (getIt.get<IntentService>().isOpenForSelect) {
      return "Selecte image...";
    }

    return null;
  }

  DirectoryNavigationScreenArguments _getArgs(BuildContext context, Uri uri) {
    ViewConfiguration viewConfig = ViewConfiguration.browse(
      route: _pref,
      defaultView: NcListView.viewKey,
      onFolderTap: null,
      //todo: implicit navigation
      onFileTap: (List<NcFile> files, int index) => Navigator.pushNamed(
        context,
        ImageScreen.route,
        arguments: ImageScreenArguments(files, index),
      ),
    );

    return DirectoryNavigationScreenArguments(
      uri: uri,
      title: _getTitle() ?? "Browse",
      viewConfig: viewConfig,
      //todo: this can now be probably be removed and YagaBottomNavBar can be created directly in DirectoryNavigationScreen
      bottomBarBuilder: (context, uri) => YagaBottomNavBar(YagaHomeTab.folder),
    );
  }
}
