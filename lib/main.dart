import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riderapp/Allscreens/Mainscreen.dart';
import 'package:riderapp/Allscreens/aboutScreen.dart';
import 'package:riderapp/Allscreens/login%20screen.dart';
import 'package:riderapp/Allscreens/registrationScreen.dart';
import 'package:riderapp/DataHandler/appData.dart';

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

DatabaseReference usersRef = FirebaseDatabase.instance.reference().child("users");
DatabaseReference driversRef = FirebaseDatabase.instance.reference().child("drivers");
DatabaseReference newRequestsRef = FirebaseDatabase.instance.reference().child("Ride Requests");


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=> AppData(),
      child: MaterialApp(
        title: 'Bus User app',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null ? loginscreen.idScreen : Mainscreen.idScreen,
        routes: {
          registrationScreen.idScreen:(context)=>registrationScreen(),
          loginscreen.idScreen:(context)=>loginscreen(),
          Mainscreen.idScreen:(context)=>Mainscreen(),
          AboutScreen.idScreen:(context)=>AboutScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
