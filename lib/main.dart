import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'apikeys.dart' as api;
Future<void> main () async {
  await Supabase.initialize(
      url: api.url,
      anonKey: api.anonkey);
  runApp(MaterialApp(home: MinuteApp()));
}

class MinuteApp extends StatefulWidget {
  const MinuteApp({super.key});

  @override
  State<MinuteApp> createState() => _MinuteAppState();
}

class _MinuteAppState extends State<MinuteApp> {
  int screenIndex = 0;
  final List screen = [
    HomeScreen(),
    SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Minute", style: TextStyle(fontSize: 30),), backgroundColor: Colors.lightBlue,),
      body: screen[screenIndex],
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label:"Home"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings")],
        onDestinationSelected: (int index){
          setState(() {
            screenIndex = index;
          });
        },
      selectedIndex: screenIndex,),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final _supabaseData = Supabase.instance.client.from('table').stream(primaryKey: ['id']).order('createdAt', ascending: true);
  final TextEditingController _msgController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: _supabaseData,
          builder: (context, snapshot){
            if (!snapshot.hasData){
              return const Center(child: CircularProgressIndicator());
            }
            final messagesData = snapshot.data!;
            return (
              ListView.separated(itemCount: messagesData.length,itemBuilder: (BuildContext context, int index){
                var messageTmp = messagesData[index]['message'];
                return(Text("$messageTmp", style: TextStyle(fontSize: 20),));
              }, separatorBuilder: (BuildContext context, int index) => const Divider(),)
            );

          },

      ),
      bottomNavigationBar: Row(
        children: [
          Expanded(
              child: TextField(
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Enter your message here", filled: true, fillColor: Colors.white70, hoverColor: Color.fromRGBO(93, 183, 222, 1)),
                controller: _msgController,
                onSubmitted: (String input) async {
                  await Supabase.instance.client.from('table').insert({'message': input});
                  _msgController.clear();
                  },
              )),
          IconButton.filled(
              onPressed: () async {
                await Supabase.instance.client.from('table').insert({'message': _msgController.text});
                _msgController.clear();
                },
              icon: Icon(Icons.arrow_upward))
        ],),);
  }
}


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Text("Version : 0.0.1", style: TextStyle(fontSize: 30),);
  }
}

