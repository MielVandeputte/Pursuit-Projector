import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:pursuit_projector/homescreen/controls.dart';
import 'package:pursuit_projector/homescreen/status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> {
  PlatformFile? selectedAudioFile;
  PlatformFile? selectedVideoFile;

  double sensitivity = 60;
  double pollingRate = 60;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        content: Container(
            margin: const EdgeInsets.all(20.0),
            child: Row(children: const [
              Controls(),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
              Expanded(child: Status())
            ])));
  }
}
