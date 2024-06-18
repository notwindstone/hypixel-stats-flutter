import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
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
  bool isTapped = false;

  Future<void> toggleTapped() async {
    setState(() {
      isTapped = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isTapped = false;
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
          'API-Key': dotenv.env['API_KEY'] ?? '',
        }
      );

    if (hypixelResponse.statusCode == 200) {
      return hypixelResponse.body;
    } else {
      throw Exception('Failed to load playerdata');
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
                  'Current player:',
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

                    return const CircularProgressIndicator();
                  },
                )
              ],
            ),
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isTapped 
          ? null
          : () {
            toggleTapped();
          },
        tooltip: 'Increment',
        child: const Icon(Icons.favorite_border),
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
  bool isTapped = false;

  Future<void> toggleTapped() async {
    setState(() {
      isTapped = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isTapped = false;
    });
  }

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
              onPressed: isTapped 
                ? null
                : () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                    
                  toggleTapped();
                  appState.setNickname(playerName);
                },
              child: Text(
                'Submit',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
