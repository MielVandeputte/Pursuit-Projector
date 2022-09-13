import 'package:rxdart/rxdart.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class Logger {
  final BehaviorSubject<List<String>> _logs = BehaviorSubject<List<String>>();
  Stream get logsStream$ => _logs.stream;

  final List<String> _logRepos = [];

  void addLog(String message) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('kk:mm:ss').format(now);

    _logRepos.add('$formattedDate\n$message');
    _logs.add(_logRepos);
  }
}

Logger logger = Logger();
