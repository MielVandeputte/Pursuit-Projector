import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:iirjdart/butterworth.dart';
import 'package:matrix2d/matrix2d.dart';
import 'package:quiver/iterables.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wav/wav.dart';

class Engine {
  //File picker
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
        _progress.add(true);
        await convertWav(result.files.first.path.toString());
        _progress.add(false);
      } else if (filetype == 'mp4') {
        _selectedVideoFile.add(result.files.first);
      }
    }
  }

  //convert wav engine
  final BehaviorSubject _progress = BehaviorSubject<bool>.seeded(false);
  Stream get progressStream$ => _progress.stream;

  Future<void> convertWav(String filepath) {
    return compute(_convertWav, filepath);
  }
}

Engine engine = Engine();

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
}
