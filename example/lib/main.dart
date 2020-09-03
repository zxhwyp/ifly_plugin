import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iflyplugin/iflyplugin.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toast/toast.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isplaying = false;

  bool hasPermission = false;

  FlutterAudioRecorder _recorder;

  String result = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      permisson();
    });

    Iflyplugin.channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "tip":
          Toast.show(call.arguments ?? '', context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
          break;
        case "result":
          setState(() {
            result = call.arguments ?? '';
          });
          break;
        default:
      }
    });
  }

  void permisson() async {
    hasPermission = await FlutterAudioRecorder.hasPermissions;
    if (!hasPermission) {
      Toast.show("没有开启录音权限", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
    }
  }

  void start() async {
    var uuid = Uuid();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = appDocDir.path + '/' + uuid.v4();
    _recorder = FlutterAudioRecorder(path, audioFormat: AudioFormat.WAV);
    await _recorder.initialized;
    await _recorder.start();
  }

  void stop() async {
    var result = await _recorder.stop();
    String file = result.path;
    Toast.show("识别中...", context,
        duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
    await Iflyplugin.recognizer(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
                onPressed: () {
                  if (!hasPermission) {
                    Toast.show("没有开启录音权限", context,
                        duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
                    return;
                  }
                  setState(() {
                    isplaying = !isplaying;
                    if (isplaying) {
                      start();
                    } else {
                      stop();
                    }
                  });
                },
                child: Image.asset(
                    isplaying ? 'lib/asset/play.png' : 'lib/asset/pause.png',
                    scale: 3)),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(isplaying ? '正在录音中' : '录音结束'),
            ),
            Text('识别结果:$result'),
            Text('')
          ],
        ),
      ),
    );
  }
}
