import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wav/wav.dart';
import 'package:matrix2d/matrix2d.dart';
import 'package:quiver/iterables.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:iirjdart/butterworth.dart';

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

  PlatformFile? selectedAudioFile;
  PlatformFile? selectedVideoFile;

  double sensitivity = 60;
  double pollingRate = 60;

  final double _minRecommendedSensitivity = 10;
  final double _maxRecommendedSensitivity = 200;

  final double _minRecommendedPolingRate = 10;
  final double _maxRecommendedPolingRate = 200;

  void _convertWav(String filepath) async {
    Matrix2d m2d = const Matrix2d();

    final wav = await Wav.readFile(filepath);

    //add channels to create mono
    List<double> mono =
        m2d.addition(wav.channels[0], wav.channels[1]).cast<double>();
    mono = mono.map((a) => a / 2).toList();

    //lowpass filter from 44.1 kHz to 11.025 kHz => fc = 0.25
    Butterworth butterworth = Butterworth();
    butterworth.lowPass(100, 441000, 11025);
    Iterable<double> lowPass = mono.map((s) => butterworth.filter(s));

    //downsampling by 4
    List<List<double>> splitDownSample = partition(lowPass, 4).toList();
    Iterable<double> downSample =
        splitDownSample.map((e) => e.reduce((a, b) => a + b) / 4);

    //Fast Fourier Transform
  }

  void _pickFile(String filetype) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: [filetype]);

    if (result != null) {
      setState(() {
        if (filetype == 'wav') {
          selectedAudioFile = result.files.first;
          _convertWav(selectedAudioFile!.path!);
        } else if (filetype == 'mp4') {
          selectedVideoFile = result.files.last;
        }
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
              icon: const Icon(FluentIcons.microphone),
              title: const Text('Listener'),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('Settings'),
            ),
          ],
        ),
        content: NavigationBody(index: _currentIndex, children: [
          ScaffoldPage(
              content: Container(
                  margin: const EdgeInsets.all(20.0),
                  child: Column(children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 5,
                              child: Column(children: <Widget>[
                                Text(
                                  'Song selection',
                                  style: DefaultTextStyle.of(context)
                                      .style
                                      .apply(fontSizeFactor: 2.0),
                                ),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                Button(
                                    child: const Text('Select audio file'),
                                    onPressed: () {
                                      _pickFile('wav');
                                    }),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                if (selectedAudioFile == null)
                                  const Text("No file selected")
                                else
                                  Column(children: <Widget>[
                                    Text(selectedAudioFile?.name.substring(
                                            0,
                                            selectedAudioFile?.name
                                                .lastIndexOf('.')) ??
                                        ''),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 1)),
                                    Text(selectedAudioFile?.extension ?? ''),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 1)),
                                    Text(selectedAudioFile?.path?.substring(
                                            0,
                                            selectedAudioFile?.path
                                                ?.lastIndexOf('\\')) ??
                                        ''),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 1)),
                                    Text(
                                        '${selectedAudioFile?.size.toString() ?? '0'} bytes'),
                                  ]),
                              ])),
                          Expanded(
                              flex: 5,
                              child: Column(children: <Widget>[
                                Text(
                                  'Video selection',
                                  style: DefaultTextStyle.of(context)
                                      .style
                                      .apply(fontSizeFactor: 2.0),
                                ),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                Button(
                                    child: const Text('Select video file'),
                                    onPressed: () {
                                      _pickFile('mp4');
                                    }),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                if (selectedVideoFile == null)
                                  const Text("No file selected")
                                else
                                  Column(children: <Widget>[
                                    Text(selectedVideoFile?.name.substring(
                                            0,
                                            selectedVideoFile?.name
                                                .lastIndexOf('.')) ??
                                        ''),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 1)),
                                    Text(selectedVideoFile?.extension ?? ''),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 1)),
                                    Text(selectedVideoFile?.path?.substring(
                                            0,
                                            selectedVideoFile?.path
                                                ?.lastIndexOf('\\')) ??
                                        ''),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 1)),
                                    Text(
                                        '${selectedVideoFile?.size.toString() ?? '0'} bytes'),
                                  ]),
                              ])),
                          Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Text(
                                    'Settings',
                                    style: DefaultTextStyle.of(context)
                                        .style
                                        .apply(fontSizeFactor: 2.0),
                                  ),
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10)),
                                  const Text('Sensitivity'),
                                  ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 250),
                                      child: Slider(
                                          value: sensitivity <
                                                  _minRecommendedSensitivity
                                              ? _minRecommendedPolingRate
                                              : sensitivity >
                                                      _maxRecommendedSensitivity
                                                  ? _maxRecommendedPolingRate
                                                  : sensitivity,
                                          min: _minRecommendedSensitivity,
                                          max: _maxRecommendedSensitivity,
                                          onChanged: (s) => {
                                                setState(() => sensitivity =
                                                    s.round().toDouble())
                                              })),
                                  Text(sensitivity.toString()),
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10)),
                                  const Text('Polling rate'),
                                  ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 250),
                                      child: Slider(
                                          value: pollingRate <
                                                  _minRecommendedPolingRate
                                              ? _minRecommendedPolingRate
                                              : pollingRate >
                                                      _maxRecommendedPolingRate
                                                  ? _maxRecommendedPolingRate
                                                  : pollingRate,
                                          min: _minRecommendedPolingRate,
                                          max: _maxRecommendedPolingRate,
                                          onChanged: (s) => {
                                                setState(() => pollingRate =
                                                    s.round().toDouble())
                                              })),
                                  Text(pollingRate.toString()),
                                ],
                              ))
                        ]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Button(
                            child: const Text('Listen & Test'),
                            onPressed: () => {}),
                        const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 100)),
                        Button(
                            child: const Text('Listen & Present'),
                            onPressed: () => {}),
                      ],
                    )
                  ])))
        ]));
  }
}
