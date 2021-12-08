import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:riderapp/Assistants/requestAssistant.dart';
import 'package:riderapp/DataHandler/appData.dart';
import 'package:riderapp/Models/address.dart';
import 'package:riderapp/Models/allUsers.dart';
import 'package:riderapp/Models/directionDetials.dart';
import 'package:http/http.dart' as http;
import 'package:riderapp/Models/history.dart';
import 'package:riderapp/main.dart';
import '../configMaps.dart';

class AssistantMethods
{
  static Future<String> searchingCoordinateAddress(Position position,context) async
  {
    String placeAddress= "";
    String st1,st2,st3,st4;
    String url="https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyA_4Tp0KLJHmF23NieDo5O-MT45sckP178";

    var response= await RequestAssistant.getRequest(url);

    if (response != "Failed"){
      //placeAddress = response["results"][0]["formatted_address"];address_components
      st1 = response["results"][0]["address_components"][0]["long_name"];
      st2 = response["results"][0]["address_components"][3]["long_name"];
      st3 = response["results"][0]["address_components"][4]["long_name"];
      st4 = response["results"][0]["address_components"][6]["long_name"];
      placeAddress = st1+", "+ st2 + ", "+st3 ;//+", " +st4;

      Address userPickupAddress = new Address();
      userPickupAddress.longitude = position.longitude;
      userPickupAddress.latitude = position.latitude ;
      userPickupAddress.placeName = placeAddress;

      Provider.of<AppData>(context,listen: false).updatePickUpLocationAddress(userPickupAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails?> obtainPlaceDirectionDetails(LatLng initialPosition, LatLng finalPosition) async
  {
    String directionUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=AIzaSyA_4Tp0KLJHmF23NieDo5O-MT45sckP178";

    var res =await RequestAssistant.getRequest(directionUrl);

    if(res=="failed")
      {
        return null;
      }


    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.encodedPoints = res["routes"][0]["overview_polyline"]["points"];

    directionDetails.distanceText = res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue = res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText = res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue = res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;

  }

  static int calculateFares(DirectionDetails directionDetails)
  {
    //double timeTraveledFare = directionDetails.durationValue!.toDouble();
    double distanceTraveledFare = (directionDetails.distanceValue!.toDouble() / 1000);
    double totalFareAmount ;

    if (distanceTraveledFare<=7){
      totalFareAmount = 17;

    }
    else if (distanceTraveledFare<=9){
      totalFareAmount = 23;
    }
    else if (distanceTraveledFare<=13){
      totalFareAmount = 28;
    }
    else if (distanceTraveledFare<=16){
      totalFareAmount = 33;
    }
    else if (distanceTraveledFare<=19){
      totalFareAmount = 39;
    }
    else if (distanceTraveledFare<=22){
      totalFareAmount = 44;
    }
    else if (distanceTraveledFare<=26){
      totalFareAmount = 47;
    }
    else if (distanceTraveledFare<=30){
      totalFareAmount = 50;
    }
    else if (distanceTraveledFare<=33){
      totalFareAmount = 53;
    }
    else if (distanceTraveledFare<=36){
      totalFareAmount = 56;
    }
    else if (distanceTraveledFare<=40){
      totalFareAmount = 60;
    }
    else if (distanceTraveledFare<=45){
      totalFareAmount = 66;
    }
    else if (distanceTraveledFare<=49){
      totalFareAmount = 70;
    }
    else if (distanceTraveledFare<=54){
      totalFareAmount = 75;
    }
    else if (distanceTraveledFare<=60){
      totalFareAmount = 78;
    }
    else if (distanceTraveledFare<=65){
      totalFareAmount = 82;
    }
    else if (distanceTraveledFare<=69){
      totalFareAmount = 85;
    }
    else if (distanceTraveledFare<=73){
      totalFareAmount = 94;
    }
    else if (distanceTraveledFare<=78){
      totalFareAmount = 103;
    }
    else if (distanceTraveledFare<=82){
      totalFareAmount = 113;
    }
    else if (distanceTraveledFare<=89){
      totalFareAmount = 122;
    }
    else if (distanceTraveledFare<=94){
      totalFareAmount = 128;
    }
    else if (distanceTraveledFare<=100){
      totalFareAmount = 132;
    }
    else if (distanceTraveledFare<=114){
      totalFareAmount = 135;
    }
    else if (distanceTraveledFare<=120){
      totalFareAmount = 141;
    }
    else if (distanceTraveledFare<=135){
      totalFareAmount = 144;
    }

    else
      {
        totalFareAmount = 150;
      }




    return totalFareAmount.truncate();
  }

  static void getCurrentOnlineUserInfo() async
  {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser!.uid;
    DatabaseReference reference = FirebaseDatabase.instance.reference().child("users").child(userId);

    reference.once().then((DataSnapshot dataSnapShot)
    {
      if (dataSnapShot.value !=null)
        {
          userCurrentInfo = Users.fromSnapshot(dataSnapShot);
        }
    });
  }

  static double createRandomNumber(int num)
  {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }

  static sendNotificationToDriver(DataSnapshot snap, String token, context, String ride_request_id)
  async {
    var destination = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map notificationMap =
        {
          'body':'DropOff Address, ${destination!.placeName}',
          'title': 'New Ride Request',
        };
    Map dataMap =
        {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id':'1',
          'status':'done',
          'ride_request_id':ride_request_id,
        };

    Map sendNotificationMap =
        {
          "notification" : notificationMap,
          "data" : dataMap,
          "priority" : "high",
          "to": token,
        };

    var res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
      'ContentType': 'application/json',
      'Authorization':serverToken,
      },

      body: jsonEncode(sendNotificationMap),
    );
  }

  static String formatTripDate(String date)
  {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate = "${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.jm().format(dateTime)}";

    return formattedDate;
  }

  static void retrieveHistoryInfo(context)
  {
    //retrieve and display Trip History
    newRequestsRef.orderByChild("rider_name").once().then((DataSnapshot dataSnapshot)
    {
      if(dataSnapshot.value != null)
      {
        //update total number of trip counts to provider
        Map<dynamic, dynamic> keys = dataSnapshot.value;
        int tripCounter = keys.length;
        Provider.of<AppData>(context, listen: false).updateTripsCounter(tripCounter);

        //update trip keys to provider
        List<String> tripHistoryKeys = [];
        keys.forEach((key, value)
        {
          tripHistoryKeys.add(key);
        });
        Provider.of<AppData>(context, listen: false).updateTripKeys(tripHistoryKeys);
        obtainTripRequestsHistoryData(context);
      }
    });
  }

  static void obtainTripRequestsHistoryData(context)
  {
    var keys = Provider.of<AppData>(context, listen: false).tripHistoryKeys;

    for(String key in keys)
    {
      newRequestsRef.child(key).once().then((DataSnapshot snapshot) {
        if(snapshot.value != null)
        {
          newRequestsRef.child(key).child("rider_name").once().then((DataSnapshot snap)
          {
            String name = snap.value.toString();
            if(name == userCurrentInfo!.name)
            {
              var history = History.fromSnapshot(snapshot);
              Provider.of<AppData>(context, listen: false).updateTripHistoryData(history);
            }
          });
        }
      });
    }
  }

}