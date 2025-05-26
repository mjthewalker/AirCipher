import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChannelScreen extends StatefulWidget{
  const ChannelScreen({super.key});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text("Establishing Connection")
        ],
      ),
    );
  }
}