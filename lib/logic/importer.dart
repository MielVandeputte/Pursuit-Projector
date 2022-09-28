import 'package:file_picker/file_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'engine.dart';

class Importer {
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
        //engine.importReferenceSong(result.files.first.path.toString());
      } else if (filetype == 'mp4') {
        _selectedVideoFile.add(result.files.first);
      }
    }
  }
}

Importer importer = Importer();
