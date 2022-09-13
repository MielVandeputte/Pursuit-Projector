import 'package:fluent_ui/fluent_ui.dart';

import '../../logic/engine.dart';

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
    return Column(
      children: [
        Expanded(
            child: Card(
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            StreamBuilder(
                stream: engine.progressStream$,
                builder: (BuildContext context, AsyncSnapshot snap) {
                  return const ProgressRing();
                }),
          ])
        ]))),
      ],
    );
  }
}
