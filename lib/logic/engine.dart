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
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class Match {
  int weight = 1;
  int currentSample = 0;

  Match(this.currentSample);
}

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

  void getAudioStream() async {
    final record = Record();
    Directory docDir = await getApplicationDocumentsDirectory();
    String dirPath = '${docDir.path}\\PursuitProjector\\audiofile';
    int i = 0;
    int j = 0;

    while (j < 40) {
      await record.start(encoder: AudioEncoder.wav, path: '$dirPath$i');

      await Future.delayed(const Duration(seconds: 2));

      String? path = await record.stop();

      await Future.delayed(const Duration(milliseconds: 20));

      i = (i + 1) % 10;
      j++;
    }
  }

  void compareToAmbientSound() async {
    Iterable<Iterable<int>>? soundSnippet1 = await _generateSoundFingerPrint(
        {'fp': "C:\\Users\\vande\\Desktop\\pursuit1.wav", 'fac': '1'});

    Iterable<Iterable<int>>? soundSnippet2 = await _generateSoundFingerPrint(
        {'fp': "C:\\Users\\vande\\Desktop\\pursuit2.wav", 'fac': '1'});

    Iterable<Iterable<int>>? soundSnippet3 = await _generateSoundFingerPrint(
        {'fp': "C:\\Users\\vande\\Desktop\\pursuit3.wav", 'fac': '1'});

    Iterable<Iterable<int>>? soundSnippet4 = await _generateSoundFingerPrint(
        {'fp': "C:\\Users\\vande\\Desktop\\pursuit4.wav", 'fac': '1'});

    Iterable<Iterable<int>>? soundSnippet5 = await _generateSoundFingerPrint(
        {'fp': "C:\\Users\\vande\\Desktop\\pursuit5.wav", 'fac': '1'});

    final soundsnippets = [
      soundSnippet1,
      soundSnippet2,
      soundSnippet3,
      soundSnippet4,
      soundSnippet5
    ];

    List<Match> _matches = [];

    for (var soundSnippet in soundsnippets) {
      for (int i in findMatches(soundSnippet)) {
        Match? matchingMatch;

        for (Match m in _matches) {
          if (m.currentSample + 25 == i) {
            matchingMatch = m;
            break;
          }
        }

        if (matchingMatch != null) {
          matchingMatch.weight += 1;
          matchingMatch.currentSample = i;
        } else {
          _matches.add(Match(i));
        }
      }

      _matches.forEach((element) {
        print('cS: ${element.currentSample} | weight: ${element.weight}');
      });

      print('_______________');

      Match maxWeightMatch = _matches.reduce(
          (value, element) => value.weight > element.weight ? value : element);
      logger.addLog('Matched at ${maxWeightMatch.currentSample}');
    }
  }

  List<int> findMatches(Iterable<Iterable<int>> soundSnippet) {
    List<int> tempMatches = [];

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
          tempMatches.add(startSample);
          break;
        }
      }
    }
    return tempMatches;
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
  const windowSize = 441;
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

  List<int> qualifyingBins = [];

  for (int i = 0; i < input.length; i++) {
    if (input.elementAt(i) > average * factor) {
      qualifyingBins.add(i);
    }
  }

  return qualifyingBins;
}
