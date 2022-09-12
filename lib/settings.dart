import 'package:fluent_ui/fluent_ui.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() {
    return SettingsState();
  }
}

class SettingsState extends State<Settings> {
  double sensitivity = 60;
  double pollingRate = 60;

  final double _minRecommendedSensitivity = 10;
  final double _maxRecommendedSensitivity = 200;

  final double _minRecommendedPolingRate = 10;
  final double _maxRecommendedPolingRate = 200;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        content: Container(
            margin: const EdgeInsets.all(20.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Column(
                children: [
                  const Text('Sensitivity'),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Slider(
                          value: sensitivity < _minRecommendedSensitivity
                              ? _minRecommendedPolingRate
                              : sensitivity > _maxRecommendedSensitivity
                                  ? _maxRecommendedPolingRate
                                  : sensitivity,
                          min: _minRecommendedSensitivity,
                          max: _maxRecommendedSensitivity,
                          onChanged: (s) => {
                                setState(
                                    () => sensitivity = s.round().toDouble())
                              })),
                  Text(sensitivity.toString()),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                  const Text('Polling rate'),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Slider(
                          value: pollingRate < _minRecommendedPolingRate
                              ? _minRecommendedPolingRate
                              : pollingRate > _maxRecommendedPolingRate
                                  ? _maxRecommendedPolingRate
                                  : pollingRate,
                          min: _minRecommendedPolingRate,
                          max: _maxRecommendedPolingRate,
                          onChanged: (s) => {
                                setState(
                                    () => pollingRate = s.round().toDouble())
                              })),
                  Text(pollingRate.toString()),
                ],
              )
            ])));
  }
}
