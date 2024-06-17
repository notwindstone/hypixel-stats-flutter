import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Hypix',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Hypix'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  String nickname = '';

  void setNickname(playerName) {
    nickname = playerName;

    notifyListeners();
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

  Future fetchMockData(nickname) async {
    final mojangResponse = await http
      .get(
        Uri.parse('https://api.mojang.com/users/profiles/minecraft/$nickname'),
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
    var appState = context.watch<MyAppState>();
  
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Current player ($_counter):',
                ),
                const SearchWidget(),
                Text(
                  appState.nickname,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text(
                  'Player data:',
                ),
                FutureBuilder(
                  future: fetchMockData(appState.nickname),
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
          ]
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

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String playerName = '';

  @override
  Widget build(BuildContext context) {  
    var appState = context.watch<MyAppState>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Enter player name',
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }

              setState(() {
                playerName = value;
              });

              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate will return true if the form is valid, or false if
                // the form is invalid.
                if (_formKey.currentState!.validate()) {
                  appState.setNickname(playerName);
                }
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
