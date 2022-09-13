import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:iirjdart/butterworth.dart';
import 'package:matrix2d/matrix2d.dart';
import 'package:quiver/iterables.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wav/wav.dart';
import 'dart:io';
import 'dart:math';
import 'package:pmap/pmap.dart';

class Engine {
  final BehaviorSubject _progress = BehaviorSubject<bool>.seeded(false);
  Stream get progressStream$ => _progress.stream;

  Future<void> convertWav(String filepath) {
    return compute(_convertWav, filepath);
  }
}

Engine engine = Engine();

void _convertWav(String filepath) async {
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
  final results = spectogram.map((e) => filterBins(e));

  print(results);

  //checking
  await File("test.txt").writeAsString(results.toList().toString());
  await File("spectogram.txt").writeAsString(spectogram.toString());
  print('samples: ${spectogram.shape[0]}');
  print('bins: ${spectogram.shape[1]}');
  print('transform complete');
}

filterBins(Float64List input) {
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

  return maxValues.where((e) =>
      e >=
      (maxValues.reduce(((value, element) => value + element)) /
          maxValues.length));
}
