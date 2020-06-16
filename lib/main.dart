import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:get_ip/get_ip.dart';

void main() => runApp(MotionControllerApp());

class MotionControllerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motion Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MotionControllerMainPage(),
    );
  }
}

class MotionControllerMainPage extends StatefulWidget {
  @override
  _MotionControllerMainPageState createState() => _MotionControllerMainPageState();
}

class _MotionControllerMainPageState extends State<MotionControllerMainPage> {
  String textMessage = "0.0.0.0";
  HttpServer server;
  StreamController streamController;

  final List<SensorEvent> list = [];

  @override
  void initState() {
    super.initState();

    streamController = StreamController<String>();

    AeyriumSensor.sensorEvents.listen((SensorEvent event) {
      streamController.add(event.toString());
      setState(() {
        list.insert(0, event);
        if (list.length > 10) {
          list.removeLast();
        }
      });
      print("Pitch ${event.pitch} and Roll ${event.roll}");
    });

    startServer();
  }

  void startServer() async {
    var _ipAddress = await GetIp.ipAddress;
    server = await HttpServer.bind(_ipAddress, 4040);
    print('Listening on: ${server.address.host}:${server.port}');
    server.listen(handleRequest);

    setState(() {
      textMessage = 'Listening on: ${server.address.host}:${server.port}';
    });
  }

  void handleRequest(HttpRequest req) {
    print('${req.headers}');

    if (WebSocketTransformer.isUpgradeRequest(req)) {
      WebSocketTransformer.upgrade(req).then(handleWebSocket);
    }
  }

  void handleWebSocket(WebSocket socket) {
    print('Client connected');
    socket.addStream(streamController.stream);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Motion Controller'),
      ),
      body: new ListView.builder (
        itemCount: list.length,
        itemBuilder: (context, index) {
          return ListTile(
              leading: const Icon(Icons.event),
              title: Text(list[index].toString())
          );
        },
    ),
    );
  }
}
