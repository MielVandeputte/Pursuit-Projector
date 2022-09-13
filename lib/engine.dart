import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:file_picker/file_picker.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:iirjdart/butterworth.dart';
import 'package:matrix2d/matrix2d.dart';
import 'package:quiver/iterables.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wav/wav.dart';

class Engine {
  final BehaviorSubject _selectedAudioFile = BehaviorSubject<PlatformFile>();
  final BehaviorSubject _selectedVideoFile = BehaviorSubject<PlatformFile>();

  Stream get audioFileStream$ => _selectedAudioFile.stream;
  Stream get videoFileStream$ => _selectedVideoFile.stream;

  void pickFile(String filetype) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: [filetype]);
    if (result != null) {
      if (filetype == 'wav') {
        _selectedAudioFile.add(result.files.first);
        _convertWav(result.files.first.path.toString());
      } else if (filetype == 'mp4') {
        _selectedVideoFile.add(result.files.first);
      }
    }
  }

  final BehaviorSubject _progress = BehaviorSubject<double>.seeded(0.0);
  Stream get progressStream$ => _progress.stream;

  void _convertWav(String filepath) async {
    Matrix2d m2d = const Matrix2d();

    _progress.add(0.0);

    final wav = await Wav.readFile(filepath);

    _progress.add(20.0);

    //add channels to create mono
    List<double> mono =
        m2d.addition(wav.channels[0], wav.channels[1]).cast<double>();
    mono = mono.map((a) => a / 2).toList();

    _progress.add(40.0);

    //lowpass filter from 44.1 kHz to 11.025 kHz => fc = 0.25
    Butterworth butterworth = Butterworth();
    butterworth.lowPass(100, 441000, 11025);
    Iterable<double> lowPass = mono.map((s) => butterworth.filter(s));

    _progress.add(60.0);

    //downsampling by 4
    List<List<double>> splitDownSample = partition(lowPass, 4).toList();
    Iterable<double> downSample =
        splitDownSample.map((e) => e.reduce((a, b) => a + b) / 4);

    _progress.add(80.0);

    //Fast Fourier Transform
    const chunkSize = 4500;
    final stft = STFT(chunkSize, Window.hanning(chunkSize));

    final spectogram = <Float64List>[];
    stft.run(downSample.toList(), (Float64x2List freq) {
      spectogram.add(freq.discardConjugates().magnitudes());
    });

    _progress.add(100.0);
  }
}

Engine engine = Engine();
