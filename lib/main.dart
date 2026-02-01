import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
Future<void> main () async {
  await Supabase.initialize(
      url: 'https://qojuaxoxgmrnytovntlj.supabase.co',
      anonKey: 'sb_publishable_fFIrjhWDciitizwlJRe4BQ_8aSvQHZ4');
  runApp(MaterialApp(home: MinuteApp()));
}

class MinuteApp extends StatefulWidget {
  const MinuteApp({super.key});

  @override
  State<MinuteApp> createState() => _MinuteAppState();
}

class _MinuteAppState extends State<MinuteApp> {
  int screenIndex = 0;
  List screen = [
    HomeScreen(),
    SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Minute"),),
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
  List<String> messages = [];
  final _supabaseData = Supabase.instance.client.from('table').select().order('createdAt', ascending: true);
  final TextEditingController _msgController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(future: _supabaseData,
          builder: (context, snapshot){
            if (!snapshot.hasData){
              return const Center(child: CircularProgressIndicator());
            }
            final messagesData = snapshot.data!;
            return (
              ListView.builder(itemCount: messagesData.length,itemBuilder: (BuildContext context, int index){
                var messageTmp = messagesData[index]['message'];
                return(Text("$messageTmp"));
              })
            );

          },

      ),
      bottomNavigationBar: Row(
        children: [
          Expanded(
              child: TextField(
                controller: _msgController,
                onSubmitted: (String input) async {
                  await Supabase.instance.client.from('table').insert({'message': input});
                  },
              )),
          IconButton.filled(
              onPressed: () async {
                await Supabase.instance.client.from('table').insert({'message': _msgController.text});
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
    return Text("settings");
  }
}

