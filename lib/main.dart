import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          brightness: Brightness.dark,
          accentColor: Colors.orange,
          iconTheme: const IconThemeData(size: 24)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() {
    return MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  PlatformFile? selectedFile;

  double sensitivity = 60;
  double pollingRate = 60;

  final double _minRecommendedSensitivity = 10;
  final double _maxRecommendedSensitivity = 200;

  final double _minRecommendedPolingRate = 10;
  final double _maxRecommendedPolingRate = 200;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['mp3']);

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

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
              icon: Icon(FluentIcons.microphone),
              title: Text('Listener'),
            ),
            PaneItem(
              icon: Icon(FluentIcons.settings),
              title: Text('Settings'),
            ),
          ],
        ),
        content: NavigationBody(index: _currentIndex, children: [
          ScaffoldPage(
              content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                Column(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Text(
                      'Song selection',
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 2.0),
                    ),
                  ),
                  Button(
                      child: const Text('Select audio file'),
                      onPressed: () {
                        _pickFile();
                      }),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                  if (selectedFile == null)
                    const Text("No file selected")
                  else
                    Column(children: <Widget>[
                      Text(selectedFile?.name.substring(
                              0, selectedFile?.name.lastIndexOf('.')) ??
                          ''),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                      Text(selectedFile?.extension ?? ''),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                      Text(selectedFile?.path?.substring(
                              0, selectedFile?.path?.lastIndexOf('\\')) ??
                          ''),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                      Text('${selectedFile?.size.toString() ?? '0'} bytes'),
                    ]),
                ]),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Text(
                        'Settings',
                        style: DefaultTextStyle.of(context)
                            .style
                            .apply(fontSizeFactor: 2.0),
                      ),
                    ),
                    const Text('Sensitivity'),
                    Slider(
                        value: sensitivity < _minRecommendedSensitivity
                            ? _minRecommendedPolingRate
                            : sensitivity > _maxRecommendedSensitivity
                                ? _maxRecommendedPolingRate
                                : sensitivity,
                        min: _minRecommendedSensitivity,
                        max: _maxRecommendedSensitivity,
                        onChanged: (s) => {
                              setState(() => sensitivity = s.round().toDouble())
                            }),
                    Text(sensitivity.toString()),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                    const Text('Polling rate'),
                    Slider(
                        value: pollingRate < _minRecommendedPolingRate
                            ? _minRecommendedPolingRate
                            : pollingRate > _maxRecommendedPolingRate
                                ? _maxRecommendedPolingRate
                                : pollingRate,
                        min: _minRecommendedPolingRate,
                        max: _maxRecommendedPolingRate,
                        onChanged: (s) => {
                              setState(() => pollingRate = s.round().toDouble())
                            }),
                    Text(pollingRate.toString()),
                  ],
                )
              ]))
        ]));
  }
}
