import 'package:fluent_ui/fluent_ui.dart';
import '../../logic/importer.dart';

class Controls extends StatefulWidget {
  const Controls({super.key});

  @override
  State<StatefulWidget> createState() {
    return ControlsState();
  }
}

class ControlsState extends State<Controls> {
  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
            child: Column(children: [
          SizedBox(
              width: 400,
              child: StreamBuilder(
                  stream: importer.audioFileStream$,
                  builder: (BuildContext context, AsyncSnapshot snap) {
                    return Card(
                        padding: const EdgeInsets.all(30),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4.0)),
                        child: Column(children: <Widget>[
                          Text(
                            'Song selection',
                            style: DefaultTextStyle.of(context)
                                .style
                                .apply(fontSizeFactor: 2.0),
                          ),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10)),
                          Button(
                              child: const Text('Select audio file'),
                              onPressed: () {
                                importer.pickFile('wav');
                              }),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10)),
                          if (snap.data == null)
                            const Text("No file selected")
                          else
                            Column(children: <Widget>[
                              Text(snap.data.name.substring(
                                  0, snap.data.name.lastIndexOf('.'))),
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 1)),
                              Text(snap.data.extension),
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 1)),
                              Text(snap.data.path.substring(
                                  0, snap.data.path.lastIndexOf('\\'))),
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 1)),
                              Text('${snap.data.size.toString()} bytes'),
                            ]),
                        ]));
                  })),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
          SizedBox(
              width: 400,
              child: StreamBuilder(
                  stream: importer.videoFileStream$,
                  builder: (BuildContext context, AsyncSnapshot snap) {
                    return Card(
                        padding: const EdgeInsets.all(30),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4.0)),
                        child: Column(children: <Widget>[
                          Text(
                            'Video selection',
                            style: DefaultTextStyle.of(context)
                                .style
                                .apply(fontSizeFactor: 2.0),
                          ),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10)),
                          Button(
                              child: const Text('Select video file'),
                              onPressed: () {
                                importer.pickFile('mp4');
                              }),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10)),
                          if (snap.data == null)
                            const Text("No file selected")
                          else
                            Column(children: <Widget>[
                              Text(snap.data.name.substring(
                                  0, snap.data.name.lastIndexOf('.'))),
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 1)),
                              Text(snap.data.extension),
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 1)),
                              Text(snap.data.path.substring(
                                  0, snap.data.path.lastIndexOf('\\'))),
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 1)),
                              Text('${snap.data.size.toString()} bytes'),
                            ]),
                        ]));
                  })),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Button(child: const Text('Listen & Test'), onPressed: () => {}),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
              Button(
                  child: const Text('Listen & Present'), onPressed: () => {}),
            ],
          ),
        ])));
  }
}
