import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:watcher_app/device_info_helper.dart';

class homePage extends StatefulWidget {
  const homePage({Key? key}) : super(key: key);

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {

  //To check if the client is connected to the broker
  late  bool _isConected;
  //To check if the button has been clicked.
  late bool _isClicked;
  //initialize firebase
  final Firebase = FirebaseFirestore.instance;
  //callback methods
  late  int noOfretries ;
  late String _ConnectionStatus;
  //Variables to store auth details to and from firebase.
  late String _Username;
  late String _Password;
  late String _Topic;
  late String _publicationValidator;
  var db = FirebaseFirestore.instance;

  //Initializing an instance of an mqtt server
  MqttServerClient client =
  MqttServerClient.withPort('broker.emqx.io', 'flutter_client', 1883);

  Future<MqttServerClient> connect() async {
    setState(() {
      noOfretries = 1;
    });
    ProgressDialog progressDialog = ProgressDialog(
        context,
        blur: 10,
        title: Text("Please wait"),
        message: Column(
          children: [
            Text("Connecting to broker..."),
          ],
        ),
        dismissable: false
    );
    client.logging(on: false);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    try {
      progressDialog.show();
      await client.connect();
      progressDialog.dismiss();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content : Text('Connection failed try again')),
      );
      progressDialog.dismiss();
    }

    // client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    //   final MqttMessage message = c[0].payload;
    //   // final payload =
    //   // MqttPublishPayload.bytesToStringAsString(message.payload.message);
    //   //
    //   // print('Received message:$payload from topic: ${c[0].topic}>');
    // });

    return client;
  }


  Future<MqttServerClient> disconnect() async {

    client.logging(on: false);
    client.disconnect();

    return client;
  }



  // Callback function to handle the `onConnected` event
  void onConnected() {
    //When is clicked is set to true the connect button is hidden
    setState(() {
      _ConnectionStatus = 'Connected';
      _isClicked = true;
    });


    //Publish that the device has been connected
    Uint8List data = Uint8List.fromList('connectedAt : ${DateTime.now()}'.codeUnits);
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    client.publishMessage(_Topic, MqttQos.atLeastOnce, dataBuffer);

    //send data to firebase
    FirebaseFirestore.instance.collection('mqtt logs').doc()
        .set({
      'connectedAt' : '${DateTime.now()}'
    });

    //Log Status
    print('Connected');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content : Text('Connected')),
    );

  }

  // Callback function to handle the `onDisconnected` event
  void onDisconnected() {
    setState(() {
      _isClicked = false;
      _ConnectionStatus = 'Disconnected';
    });


    try {
      //Publish that the device has been disconnected
      Uint8List data = Uint8List.fromList('disconnectedAt : ${DateTime.now()}'.codeUnits);
      Uint8Buffer dataBuffer = Uint8Buffer();
      dataBuffer.addAll(data);
      client.publishMessage(_Topic, MqttQos.atLeastOnce, dataBuffer);

    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content : Text('Connection failed try again')),
      );
    }

    print('Disconnected');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content : Text('Disconnected')),
    );


  }

  void sendMessage(){
    _publicationValidator = _publishController.text.trim();
    if(_isClicked == false){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content : Text('Connect to broker')),
      );
    }
    if(_publicationValidator.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content : Text('Enter a publication')),
      );


    }
    Uint8List data = Uint8List.fromList(_publishController.text.trim().codeUnits);
    Uint8Buffer dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
  client.publishMessage(_Topic, MqttQos.atLeastOnce, dataBuffer);
    _publishController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content : Text('Publish Succesfull')),
    );
  }
  @override
  void initState() {

    _isConected = false;
    _isClicked = false;
    _Topic = '/stats/health/device_id/network';
    noOfretries = 0;
    _ConnectionStatus = 'Disconnected';
    super.initState();
  }

  final _publishController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
                         onPressed: () async{
                          await disconnect();
                           setState(() {
                             _isClicked = false;
                           });
                         },
          label: Text('Disconnect')),

      appBar: AppBar(
        title: Text('Watcher App'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20,),
            //TextField to show connection status.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Connection Status : ', style:
                  TextStyle(fontWeight: FontWeight.bold),),
                  SizedBox(width: 5,),
                  Text( _ConnectionStatus),
                ],
              ),
            ),

            if(_isClicked == false)
           SizedBox(
             child: ElevatedButton(
                     onPressed: () async{
                               connect();
                                  },
         child: Text('Connect to broker')),
           ) ,


            //pre_Subscribed topic
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                    alignment : Alignment.topLeft,
                child: Row(
                  children: [
                    Text('Subscribed to : ', style:
                    TextStyle(fontWeight: FontWeight.bold),),
                    SizedBox(width: 5,),
                    Text(' ${_Topic}', ),
                  ],
                )),
              ),
            ),
            SizedBox(height: 5 ,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _publishController,
                decoration:
                InputDecoration(
                    hintText: 'Type Something'
                )  ,
                maxLines: 1,
              ),
            ),

            //Publish test message
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: (){
                      sendMessage();
              },
                  child: Text('Publish Message')),
            ),
            SizedBox(height: 5 ,),


            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                  child: Text('Connection Logs', style:
                  TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),)),

            ),
           SizedBox(height: 5,),
           // buildLogs()

            //Sample Logs
            Padding(
             padding: const EdgeInsets.all(8.0),
             //Log 1
             child: ListTile(
               leading: Column(
                 children: [
                   Icon(Icons.history),
                   SizedBox(height: 5,),

                   Icon(Icons.share),
                 ],
               ),
               tileColor: Colors.grey[300],
               title: Text('    ${DateTime.now() }'),
               subtitle: Container(
                 child: Align(
                   child: Column(
                     children: [
                       Text('Connection time : 3 seconds'),
                       SizedBox(height: 5,),
                       Text('Connection downTime : 30 seconds'),
                       SizedBox(height: 5,),
                       Text('Number of retries : 3')
                     ],
                   ),
                 ),
               ),
             ),
           ),
            SizedBox(height: 10,),

            //Log 2
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Column(
                  children: [
                    Icon(Icons.history),
                    SizedBox(height: 5,),

                    Icon(Icons.share),
                  ],
                ),
                tileColor: Colors.grey[300],
                title: Text('    ${DateTime.now()}'),
                subtitle: Container(
                  child: Align(
                    child: Column(
                      children: [
                        Text('Connection time : 3 seconds'),
                        SizedBox(height: 5,),
                        Text('Connection downTime : 20 seconds'),
                        SizedBox(height: 5,),
                        Text('Number of retries : 2')
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10,),

            //Log 3
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Column(
                  children: [
                    Icon(Icons.history),
                    SizedBox(height: 5,),

                    Icon(Icons.share),
                  ],
                ),
                tileColor: Colors.grey[300],
                title: Text('    ${DateTime.now()}'),
                subtitle: Container(
                  child: Align(
                    child: Column(
                      children: [
                        Text('Connection time : 4 seconds'),
                        SizedBox(height: 5,),
                        Text('Connection downTime : 10 seconds'),
                        SizedBox(height: 5,),
                        Text('Number of retries : 1')
                      ],
                    ),
                  ),
                ),
              ),
            )




          ],
        ),
      ),
    );
  }

  Future getLogs() async{
    var Firestore = FirebaseFirestore.instance;
    QuerySnapshot qn = await Firestore
        .collection('mqtt logs')
        .get();

    return qn.docs;
  }


  // Widget buildLogs()=>
  //     FutureBuilder(
  //       future: getLogs(),
  //       builder: (context, snapshot) {
  //         if (snapshot.hasData) {
  //           return StreamBuilder(
  //             stream: snapshot.data,
  //             builder: (context, snapshot) {
  //               if (snapshot.hasData) {
  //                 // return ListView.builder(
  //                 //     itemBuilder:
  //                 // (BuildContext,index)
  //                 // {
  //                 //   return ListTile(
  //                 //     title: Text('Connected at : ${snapshot.data} '),
  //                 //   );
  //                 // });
  //                  Text('${snapshot.data}');
  //               } else {
  //                 return Text("Loading data...");
  //               }
  //
  //             },
  //           );
  //         } else {
  //           return Text("Loading stream...");
  //         }
  //       },
  //     );

}
