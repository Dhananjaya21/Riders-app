import 'package:firebase_auth/firebase_auth.dart';
import 'package:riderapp/Models/allUsers.dart';

String mapKey = "AIzaSyA_4Tp0KLJHmF23NieDo5O-MT45sckP178";

User? firebaseUser ;

Users? userCurrentInfo;

int driverRequestTimeOut = 40;
String statusRide = "";
String rideStatus = "Driver is Coming";
String carDetailsDriver = "";
String driverName = "";
String driverphone = "";

double starCounter=0.0;
String title="";
String carRideType="";

String serverToken = "key=AAAAHo9PlG0:APA91bGDsfna2DMO64-cOSDIVxvc8MaQF29FJMOwPIKxsi6zXZnYL2jcfRX0FgrPBlZANAoxEm-W2atJazlZt1oClz6858IWelUKsGavcYeF8TcnsLod8U8wtmMK6uBGKBqctpMmCJI1";

