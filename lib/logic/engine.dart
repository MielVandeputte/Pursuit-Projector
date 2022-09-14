import 'dart:io';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:iirjdart/butterworth.dart';
import 'package:matrix2d/matrix2d.dart';
import 'package:quiver/iterables.dart';
import 'package:wav/wav.dart';
import 'logger.dart';

class Engine {
  Iterable<Iterable<int>>? _referenceSong;

  void importReferenceSong(String filepath) async {
    logger.addLog(
        'Import ${filepath.substring(filepath.lastIndexOf('\\'))}: Import started');

    _referenceSong =
        await compute(_generateSoundFingerPrint, {'fp': filepath, 'fac': '3'});

    logger.addLog(
        'Import ${filepath.substring(filepath.lastIndexOf('\\'))}: Import completed');
  }

  void compareToAmbientSound() async {
    Iterable<Iterable<int>>? soundSnippet = await _generateSoundFingerPrint(
        {'fp': 'C:\\Users\\vande\\Desktop\\begin moved.wav', 'fac': '1'});

//begin te vergelijken vanaf startsample
    for (int startSample = 0;
        startSample < _referenceSong!.length;
        startSample++) {
      int i = startSample;
      int j = 0;

      while (checkSamplePartOfSample(
          _referenceSong!.elementAt(i), soundSnippet.elementAt(j))) {
        i++;
        j++;

        if (i >= _referenceSong!.length || j >= soundSnippet.length) {
          print("match found at $startSample");
          break;
        }
      }
    }
    print('out');
    File('reference.txt').writeAsString(
        _referenceSong!.toList().toString().replaceAll('],', '],\n'));
    File('snip.txt').writeAsString(
        soundSnippet.toList().toString().replaceAll('],', '],\n'));
  }

  bool checkSamplePartOfSample(Iterable<int> a, Iterable<int> b) {
    for (int i in a) {
      if (!b.contains(i)) {
        return false;
      }
    }
    return true;
  }
}

Engine engine = Engine();

Future<Iterable<Iterable<int>>> _generateSoundFingerPrint(
    Map<String, String> args) async {
  String filepath = args['fp'].toString();
  int factor = int.parse(args['fac'].toString());

  Matrix2d m2d = const Matrix2d();

  //import wav
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
  const windowSize = 512;
  final stft = STFT(windowSize, Window.hanning(windowSize));

  final spectogram = <Float64List>[];
  stft.run(downSample.toList(), (Float64x2List freq) {
    spectogram.add(freq.discardConjugates().magnitudes());
  });

  //filtering bins with highest energy
  Iterable<Iterable<int>> results =
      spectogram.map((e) => _filterBins(e, factor));

  return results;
}

List<int> _filterBins(Float64List input, int factor) {
  int start = 0;
  int end = 10;

  List<double> maxValues = [];

  while (start < input.shape[0]) {
    if (end > input.shape[0] + 1) {
      end = input.shape[0];
    }

    maxValues.add(input
        .sublist(start, end)
        .reduce(((value, element) => value > element ? value : element)));

    start = end;
    end *= 2;
  }

  double average = maxValues.reduce(((value, element) => value + element)) /
      maxValues.length;

  List<int> qualifyingbins = [];

  for (int i = 0; i < input.length; i++) {
    if (input.elementAt(i) > average * factor) {
      qualifyingbins.add(i);
    }
  }

  return qualifyingbins;
}
