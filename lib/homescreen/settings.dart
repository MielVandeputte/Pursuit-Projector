import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:wav/wav.dart';
import 'package:matrix2d/matrix2d.dart';
import 'package:quiver/iterables.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:iirjdart/butterworth.dart';
import 'package:fftea/fftea.dart';
import 'dart:io';
import 'dart:typed_data';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() {
    return SettingsState();
  }
}

class SettingsState extends State<Settings> {
  PlatformFile? selectedAudioFile;
  PlatformFile? selectedVideoFile;

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
    const chunkSize = 4500;
    final stft = STFT(chunkSize, Window.hanning(chunkSize));

    final spectogram = <Float64List>[];
    stft.run(downSample.toList(), (Float64x2List freq) {
      spectogram.add(freq.discardConjugates().magnitudes());
    });

    var file = await File('logs.txt').writeAsString(spectogram.toString());
  }
  //-------------------------------------------------

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
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          flex: 5,
          child: Card(
              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
              child: Column(children: <Widget>[
                Text(
                  'Song selection',
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 2.0),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                Button(
                    child: const Text('Select audio file'),
                    onPressed: () {
                      _pickFile('wav');
                    }),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                if (selectedAudioFile == null)
                  const Text("No file selected")
                else
                  Column(children: <Widget>[
                    Text(selectedAudioFile?.name.substring(
                            0, selectedAudioFile?.name.lastIndexOf('.')) ??
                        ''),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                    Text(selectedAudioFile?.extension ?? ''),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                    Text(selectedAudioFile?.path?.substring(
                            0, selectedAudioFile?.path?.lastIndexOf('\\')) ??
                        ''),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                    Text('${selectedAudioFile?.size.toString() ?? '0'} bytes'),
                  ]),
              ]))),
      Expanded(
          flex: 5,
          child: Column(children: <Widget>[
            Text(
              'Video selection',
              style:
                  DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
            Button(
                child: const Text('Select video file'),
                onPressed: () {
                  _pickFile('mp4');
                }),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
            if (selectedVideoFile == null)
              const Text("No file selected")
            else
              Column(children: <Widget>[
                Text(selectedVideoFile?.name.substring(
                        0, selectedVideoFile?.name.lastIndexOf('.')) ??
                    ''),
                const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                Text(selectedVideoFile?.extension ?? ''),
                const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                Text(selectedVideoFile?.path?.substring(
                        0, selectedVideoFile?.path?.lastIndexOf('\\')) ??
                    ''),
                const Padding(padding: EdgeInsets.symmetric(vertical: 1)),
                Text('${selectedVideoFile?.size.toString() ?? '0'} bytes'),
              ]),
          ])),
    ]);
  }
}
