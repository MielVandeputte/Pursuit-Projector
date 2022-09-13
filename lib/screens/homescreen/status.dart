import 'package:fluent_ui/fluent_ui.dart';
import '../../logic/logger.dart';

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
    return (Card(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
            child: StreamBuilder(
                stream: logger.logsStream$,
                builder: (BuildContext context, AsyncSnapshot snap) {
                  List<Widget> widgetList = <Widget>[];

                  if (!snap.hasData) {
                    return Column(children: const [Text('No logs found...')]);
                  }

                  for (var item in snap.data) {
                    widgetList.add(const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8)));
                    widgetList.add(Text(item));
                  }

                  widgetList = widgetList.reversed.toList();

                  return Column(children: widgetList);
                }))));
  }
}
