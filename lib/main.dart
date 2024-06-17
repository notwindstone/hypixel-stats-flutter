import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hypix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Hypix'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future fetchMockData() async {
    final mojangResponse = await http
      .get(
        Uri.parse('https://api.mojang.com/users/profiles/minecraft/player$_counter'),
      );

    final playerId = jsonDecode(mojangResponse.body)['id'];

    final hypixelResponse = await http
      .get(
        Uri.parse('https://api.hypixel.net/v2/player?uuid=$playerId'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'API-Key': '196349f9-4013-412f-ab31-9b9f432cffc0'
        }
      );

    if (hypixelResponse.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return hypixelResponse.body;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album, ${hypixelResponse.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Current player:',
            ),
            Text(
              'player$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              'Player data:',
            ),
            FutureBuilder(
              future: fetchMockData(),
              builder: (context, snapshot) {
                var isPending = snapshot.connectionState == ConnectionState.waiting;

                if (isPending) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasData) {
                  return Text(snapshot.data);
                }
                
                if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                // By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}