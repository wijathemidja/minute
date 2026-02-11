import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'apikeys.dart' as api;
import 'package:censor_it/censor_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final TextEditingController LoginemailController = TextEditingController();
final TextEditingController LoginpasswordController = TextEditingController();
User? SBuser;
Session? SBsession;
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
                hintText: enterMessageTxt(),
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
                final authusrinfo = Supabase.instance.client.auth.currentUser!.id.toString();
                if (storage.getString('username') != null) {
                  usr = storage.getString('username')!;
                }
                await Supabase.instance.client.from('table').insert({
                  'message': censoredInput.censored,
                  'username': usr,
                  'userAuth': authusrinfo,
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
              final Map authusrinfo = jsonDecode(Supabase.instance.client.auth.currentUser!.id);
              final storage = await SharedPreferences.getInstance();
              String usr = 'DefaultFlutterUser';
              if (storage.getString('username') != null) {
                usr = storage.getString('username')!;
              }
              await Supabase.instance.client.from('table').insert({
                'message': censoredInput.censored,
                'username': usr,
                'userAuth': authusrinfo["id"],
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
  @override
  Widget build(BuildContext context) {
    return (Column(
      children: [
        TextField(
          controller: LoginemailController,
          decoration: InputDecoration(label: Text("Enter your email")),
        ),
        TextField(
          controller: LoginpasswordController,
          decoration: InputDecoration(label: Text("Enter your password")),
        ),
        ?ConditionalRowSUSI(SBsession),
        ?ConditionalButtonSignOut(SBsession),
      ],
    ));
  }
}

enterMessageTxt() {
  final User? user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    return ("Enter your message here");
  } else {
    return ("You need to sign in to send messages");
  }
}

FilledButton? ConditionalButtonSignOut(Session? session) {
  if (session != null) {
    return (FilledButton(
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
      },
      child: Text("Sign Out"),
    ));
  } else {
    return (null);
  }
}

Row? ConditionalRowSUSI(Session? session) {
  if (session == null) {
    return (Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton(
          onPressed: () async {
            SBuser = await signUp(
              LoginemailController.text,
              LoginpasswordController.text,
            );
          },
          child: Text("Sign Up"),
        ),
        FilledButton(
          onPressed: () async {
            List userSession = await signIn(
              LoginemailController.text,
              LoginpasswordController.text,
            );
            SBuser = userSession[0];
            SBsession = userSession[1];
          },
          child: Text("Sign In"),
        ),
      ],
    ));
  } else {
    return (null);
  }
}

Future<User?> signUp(String emailInput, String passwordInput) async {
  final AuthResponse res = await Supabase.instance.client.auth.signUp(
    email: emailInput,
    password: passwordInput,
  );
  User? user = res.user;
  return (user);
}

Future<List> signIn(String emailInput, String passwordInput) async {
  final AuthResponse res = await Supabase.instance.client.auth
      .signInWithPassword(email: emailInput, password: passwordInput);
  User? user = res.user;
  Session? session = res.session;
  List UserSessionList = [user, session];
  return (UserSessionList);
}

Future<void> signOut() async {
  await Supabase.instance.client.auth.signOut();
  SBsession = null;
  SBuser = null;
}
