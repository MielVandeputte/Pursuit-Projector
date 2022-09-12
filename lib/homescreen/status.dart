import 'package:fluent_ui/fluent_ui.dart';

class Status extends StatefulWidget {
  const Status({super.key});

  @override
  State<StatefulWidget> createState() {
    return StatusState();
  }
}

class StatusState extends State<Status> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: const [ProgressRing(value: 35)],
        )
      ],
    );
  }
}
