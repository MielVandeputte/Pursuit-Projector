import 'package:fluent_ui/fluent_ui.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        content: Container(
      margin: const EdgeInsets.all(20.0),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [Text('To fill in')],
        )
      ]),
    ));
  }
}
