import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'apikeys.dart' as api;
import 'package:censor_it/censor_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await Supabase.initialize(url: api.url, anonKey: api.anonkey);
  runApp(MaterialApp(home: MinuteApp()));
}

class MinuteApp extends StatefulWidget {
  const MinuteApp({super.key});

  @override
  State<MinuteApp> createState() => _MinuteAppState();
}

class _MinuteAppState extends State<MinuteApp> {
  int screenIndex = 0;
  final List screen = [HomeScreen(), LoginScreen(), SettingsScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Minute", style: TextStyle(fontSize: 30)),
        backgroundColor: Colors.lightBlue,
      ),
      body: screen[screenIndex],
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.person), label: "Account"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            screenIndex = index;
          });
        },
        selectedIndex: screenIndex,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabaseData = Supabase.instance.client
      .from('table')
      .stream(primaryKey: ['id'])
      .order('createdAt', ascending: true);
  final TextEditingController _msgController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _supabaseData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final messagesData = snapshot.data!;
          return (ListView.separated(
            itemCount: messagesData.length,
            itemBuilder: (BuildContext context, int index) {
              var messageTmp = messagesData[index]['message'];
              var userTmp = messagesData[index]['username'];
              return (Text(
                "$userTmp || $messageTmp",
                style: TextStyle(fontSize: 20),
              ));
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
          ));
        },
      ),
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your message here",
                filled: true,
                fillColor: Colors.white70,
                hoverColor: Color.fromRGBO(93, 183, 222, 1),
              ),
              controller: _msgController,
              onSubmitted: (String input) async {
                var censoredInput = CensorIt.mask(
                  input,
                  pattern: LanguagePattern.english,
                );
                final storage = await SharedPreferences.getInstance();
                String usr = 'DefaultFlutterUser';
                if (storage.getString('username') != null) {
                  usr = storage.getString('username')!;
                }
                await Supabase.instance.client.from('table').insert({
                  'message': censoredInput.censored,
                  'username': usr,
                });
                _msgController.clear();
                focusNode.requestFocus();
              },
            ),
          ),
          IconButton.filled(
            onPressed: () async {
              var censoredInput = CensorIt.mask(
                _msgController.text,
                pattern: LanguagePattern.english,
              );
              final storage = await SharedPreferences.getInstance();
              String usr = 'DefaultFlutterUser';
              if (storage.getString('username') != null) {
                usr = storage.getString('username')!;
              }
              await Supabase.instance.client.from('table').insert({
                'message': censoredInput.censored,
                'username': usr,
              });
              _msgController.clear();
              focusNode.requestFocus();
            },
            icon: Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> addUsrStorage(String username) async {
    final storage = await SharedPreferences.getInstance();
    storage.setString('username', username);
  }

  @override
  Widget build(BuildContext context) {
    return (Column(
      children: [
        Text("Version : 0.0.1", style: TextStyle(fontSize: 25)),
        TextField(
          decoration: InputDecoration(label: Text('Enter your username')),
          onChanged: (String input) async {
            await addUsername(input);
          },
        ),
      ],
    ));
  }
}

Future<void> addUsername(String username) async {
  final storage = await SharedPreferences.getInstance();
  storage.setString('username', username);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  User? user;
  Session? session;
  Future<void> signUp(String emailInput, String passwordInput) async {
    final AuthResponse res = await supabase.auth.signUp(
      email: emailInput,
      password: passwordInput,
    );
    user = res.user;
  }

  Future<void> signIn(String emailInput, String passwordInput) async {
    final AuthResponse res = await supabase.auth.signInWithPassword(
      email: emailInput,
      password: passwordInput,
    );
    user = res.user;
    session = res.session;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return (Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(label: Text("Enter your email")),
        ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(label: Text("Enter your password")),
        ),
        Row(
          children: [
            FilledButton(
                onPressed: () async {
                  await signUp(emailController.text, passwordController.text);
                },
                child: Text("Sign Up")),
            FilledButton(
                onPressed: () async {
                  await signIn(emailController.text, passwordController.text);
                },
                child: Text("Sign In")),
            FilledButton(
                onPressed: () async {
                  await signOut();
                },
                child: Text("Sign Out")),
          ],
        ),
      ],
    ));
  }
}
