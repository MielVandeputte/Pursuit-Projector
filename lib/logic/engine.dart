import 'dart:ffi';
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
  List<List<int>>? _referenceSong;
  final List<Match> _matches = [];

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
    Directory('${docDir.path}\\PursuitProjector').deleteSync(recursive: true);

    String dirPath = '${docDir.path}\\PursuitProjector\\audiofile';

    _matches.clear();

    int i = 0;
    int j = 0;

    while (j < 20) {
      await record.start(encoder: AudioEncoder.wav, path: '$dirPath$i');

      await Future.delayed(const Duration(seconds: 4));

      String? filepath = await record.stop();

      await Future.delayed(const Duration(seconds: 1));

      if (filepath != null) {
        print('analyzing $filepath');
        compareToAmbientSound(filepath);
      } else {
        print('null detected');
      }

      i = (i + 1) % 10;
      j++;
    }
  }

  void compareToAmbientSound(String filepath) async {
    List<List<int>>? soundSnippet =
        await _generateSoundFingerPrint({'fp': filepath, 'fac': '1'});
  }

  void findMatches(List<List<int>> soundSnippet) {
    for (int startingSample = 0;
        startingSample < _referenceSong!.length - 40;
        startingSample++) {
      int totalScore = 0;

      for (int i = 0; i < 40; i++) {
        totalScore += checkSample(soundSnippet[i],
            _referenceSong!.sublist(startingSample, startingSample + 40)[i]);
      }

      print('start sample: $startingSample, total score: $totalScore');
    }
  }

  int checkSample(Iterable<int> ambient, Iterable<int> original) {
    int score = 0;

    for (int i in original) {
      if (ambient.contains(i)) {
        score += 2;
      } else if (ambient.contains(i + 1) || ambient.contains(i - 1)) {
        score++;
      } else {
        score--;
      }
    }
    return score;
  }

  void testFunction() async {
    final original = await _generateSoundFingerPrint(
        {'fp': "C:\\Users\\vande\\Desktop\\speakershort.wav", 'fac': '1'});

    File('C:\\Users\\vande\\Desktop\\shortenedspeaker.txt').writeAsStringSync(
        original!.toList().toString().replaceAll('],', '],\n'));

    print('done');
  }
}

Engine engine = Engine();

//Converts WAV file to a usable spectogram
Future<List<List<int>>?> _generateSoundFingerPrint(
    Map<String, String> args) async {
  String filepath = args['fp'].toString();
  int factor = int.parse(args['fac'].toString());

  Matrix2d m2d = const Matrix2d();

  //import wav
  final wav = await Wav.readFile(filepath);

  //add channels together to create mono
  List<double> mono =
      m2d.addition(wav.channels[0], wav.channels[1]).cast<double>();
  mono = mono.map((a) => a / 2).toList();

  //lowpass filter of 5.5 kHz
  Butterworth butterworth = Butterworth();
  butterworth.lowPass(100, 44100, 5500);
  Iterable<double> lowPass = mono.map((s) => butterworth.filter(s));

  //Downsampling by 4: from 44.1 kHz to 11.025 kHz
  //Theorem of Nyquist-Shannon: sampling rate must be strictly greater than 2*frequency of signal
  //Result after: signal from 0 to 5.5 kHz, sampled at 11.025 kHz
  List<List<double>> splitDownSample = partition(lowPass, 4).toList();
  Iterable<double> downSample =
      splitDownSample.map((e) => e.reduce((a, b) => a + b) / 4);

  //Fast Fourier Transform

  //windowSize defines the amount of samples used to define a bin,
  //a larger windowSize makes for a more accurate bin which increases the amount of bins

  //at a sampling rate of 11.025 kHz, every sample lasts 1/11.025kHz
  //so every calculation of bins considers windowsSize * 1/11.025 seconds in length = 0.1 seconds

  //size of bin/frequency resolution equals sampling rate divided by windowSize = 10.77 Hz
  //dividing sampling rate by freq resolution gets you the edges of the bins and amount of bins
  //these repeat 1 time so the amount of unique bins is half = 513

  const windowSize = 1024;
  final stft = STFT(windowSize, Window.hanning(windowSize));

  final spectogram = <Float64List>[];
  stft.run(downSample.toList(), (Float64x2List freq) {
    spectogram.add(freq.discardConjugates().magnitudes());
  });

  //filtering bins with highest energy
  List<List<int>>? results = _filterBins(spectogram, factor);

  return results;
}

//Calculates which bins in a given sample are outliers for that particular bin
List<List<int>>? _filterBins(List<Float64List> input, int factor) {
  //Calculate 3rd quartile for the volume of each bin over the total length/all samples of the audioclip
  List<double> lowLimit = List.filled(input[0].length, 0);

  for (int i = 0; i < input[0].length; i++) {
    List<double> temp = input.map((e) => e[i]).toList();
    temp.sort();

    // 1.5 * 3rd quartile is the edge where outliers begin in statistics
    // any bin value for a given sample above this edge is an outlier for that bin
    lowLimit[i] = temp[(temp.length * 0.75).round()] * 1.5;
  }

  //For each sample, keep the indexes of the bins which are outliers
  List<List<int>> outcomes = List.empty(growable: true);

  for (int i = 0; i < input.length; i++) {
    List<int> temp = List.empty(growable: true);
    for (int j = 0; j < input[0].length; j++) {
      if (input[i][j] > lowLimit[j]) {
        temp.add(j);
      }
    }
    outcomes.add(temp);
  }
  return outcomes;
}
