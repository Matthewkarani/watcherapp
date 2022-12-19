import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          SizedBox(height: 30,),
          Text('Enter Auth Details', style:
          TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline
          ),),
          SizedBox(height: 10,),
          TextField(
            decoration:
            InputDecoration(
                hintText: 'Username'
            )  ,
            maxLines: 1,
          ),
          SizedBox(height: 10,),
          TextField(
            decoration :
            InputDecoration(
                hintText: 'Password'
            )  ,
            maxLines: 1,
          )
        ],
      ),
    );
  }
}
