import 'package:fluent_ui/fluent_ui.dart';
import 'package:pursuit_projector/screens/homescreen/homescreen.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/settings.dart';
import 'screens/about.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(900, 300),
      size: Size(1200, 900));

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const PursuitApp());
}

class PursuitApp extends StatelessWidget {
  const PursuitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'Pursuit Projector',
      theme: ThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.orange,
          iconTheme: const IconThemeData(size: 24)),
      home: const FramePage(),
    );
  }
}

class FramePage extends StatefulWidget {
  const FramePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return FramePageState();
  }
}

class FramePageState extends State<FramePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
        appBar: NavigationAppBar(
            title: const Text('Pursuit Projector'),
            actions: DragToMoveArea(
                child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Spacer(),
                SizedBox(
                    width: 138,
                    height: 50,
                    child: WindowCaption(
                      brightness: Brightness.dark,
                      backgroundColor: Colors.transparent,
                    ))
              ],
            )),
            automaticallyImplyLeading: true),
        pane: NavigationPane(
          selected: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
          displayMode: PaneDisplayMode.top,
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.microphone),
              title: const Text('Listener'),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('Settings'),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.info),
              title: const Text('About'),
            ),
          ],
        ),
        content: NavigationBody(index: _currentIndex, children: const [
          HomeScreen(),
          Settings(),
          About(),
        ]));
  }
}
