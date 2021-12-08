import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:riderapp/AllWidgets/CollectFareDialog.dart';
import 'package:riderapp/AllWidgets/Divider.dart';
import 'package:riderapp/AllWidgets/noDriverAvailableDialog.dart';
import 'package:riderapp/AllWidgets/progressDialog.dart';
import 'package:riderapp/Allscreens/HistoryScreen.dart';
import 'package:riderapp/Allscreens/aboutScreen.dart';
import 'package:riderapp/Allscreens/login%20screen.dart';
import 'package:riderapp/Allscreens/profileTabPage.dart';
import 'package:riderapp/Allscreens/ratingScreen.dart';
import 'package:riderapp/Allscreens/registrationScreen.dart';
import 'package:riderapp/Allscreens/searchScreen.dart';
import 'package:riderapp/Assistants/assistantMethods.dart';
import 'package:riderapp/Assistants/geoFireAssistant.dart';
import 'package:riderapp/DataHandler/appData.dart';
import 'package:riderapp/Models/availableDrivers.dart';
import 'package:riderapp/Models/directionDetials.dart';
import 'package:riderapp/configMaps.dart';
import 'package:riderapp/main.dart';
import 'package:url_launcher/url_launcher.dart';

class Mainscreen extends StatefulWidget {
  static const String idScreen="mainScreen";

  @override
  _MainscreenState createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> with TickerProviderStateMixin
{
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey= new GlobalKey<ScaffoldState>();
  DirectionDetails? tripDirectionDetails;


  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};


  late Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap =0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight=270.0;
  double driverDetailsContainerHeight= 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference? rideRequestRef;

  BitmapDescriptor? availableIcon;

  List<NeabyavailableDrivers>? availableDrivers;

  String state = "normal";

  late StreamSubscription<Event> rideStreamSubscription;

  bool isRequestingPositionDetails = false;

  String uName = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    AssistantMethods.getCurrentOnlineUserInfo();

  }

  void saveRideRequest()
  {
    rideRequestRef = FirebaseDatabase.instance.reference().child("Ride Requests").push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap =
    {
      "latitude": pickUp!.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocMap =
    {
      "latitude": dropOff!.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap =
    {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo!.name,
      "rider_phone": userCurrentInfo!.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
      "ride_type": carRideType,
    };

    rideRequestRef!.set(rideInfoMap);

    rideStreamSubscription = rideRequestRef!.onValue.listen((event) async {
      if(event.snapshot.value == null)
      {
        return;
      }

      if(event.snapshot.value["vehicle_details"] != null)
      {
        setState(() {
          carDetailsDriver = event.snapshot.value["vehicle_details"].toString();
        });
      }
      if(event.snapshot.value["driver_name"] != null)
      {
        setState(() {
          driverName = event.snapshot.value["driver_name"].toString();
        });
      }
      if(event.snapshot.value["driver_phone"] != null)
      {
        setState(() {
          driverphone = event.snapshot.value["driver_phone"].toString();
        });
      }

      if(event.snapshot.value["driver_location"] != null)
      {
        double driverLat = double.parse(event.snapshot.value["driver_location"]["latitude"].toString());
        double driverLng = double.parse(event.snapshot.value["driver_location"]["longitude"].toString());
        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

        if(statusRide == "accepted")
        {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        }
        else if(statusRide == "onride")
        {
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        }
        else if(statusRide == "arrived")
        {
          setState(() {
            rideStatus = "Driver has Arrived.";
          });
        }
      }

      if(event.snapshot.value["status"] != null)
      {
        statusRide = event.snapshot.value["status"].toString();
      }
      if(statusRide == "accepted")
      {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofileMarkers();
      }
      if(statusRide == "ended")
      {
        if(event.snapshot.value["fares"] != null)
        {
          int fare = int.parse(event.snapshot.value["fares"].toString());
          var res = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context)=> CollectFareDialog(paymentMethod: "cash", fareAmount: fare,),
          );

          String driverId="";
          if(res == "close")
          {
            if(event.snapshot.value["driver_id"] != null)
            {
              driverId = event.snapshot.value["driver_id"].toString();
            }

            Navigator.of(context).push(MaterialPageRoute(builder: (context) => RatingScreen(driverId: driverId)));

            rideRequestRef!.onDisconnect();
            rideRequestRef = null;
            rideStreamSubscription.cancel();
            //rideStreamSubscription = null;   //yooooooooooooooooo
            resetApp();
          }
        }
      }
    });
  }

  void deleteGeofileMarkers()
  {
    setState(() {
      markersSet.removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async
  {
    if(isRequestingPositionDetails == false)
    {
      isRequestingPositionDetails = true;

      var positionUserLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);
      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, positionUserLatLng);
      if(details == null)
      {
        return;
      }
      setState(() {
        rideStatus = "Driver is Coming - " +"\n"+ details.durationText!+"\n" +details.distanceText!;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async
  {
    if(isRequestingPositionDetails == false)
    {
      isRequestingPositionDetails = true;

      var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffUserLatLng = LatLng(dropOff!.latitude!, dropOff.longitude!);

      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, dropOffUserLatLng);
      if(details == null)
      {
        return;
      }
      setState(() {
        rideStatus = "Going to Destination - " +"\n"+ details.durationText!+"\n" +details.distanceText!;
      });

      isRequestingPositionDetails = false;
    }
  }

  void cancelRiderRequest()
  {
    rideRequestRef!.remove();
    setState(() {
      state = "normal";
    });
  }

  void displayDriverDetailsContainer()
  {
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 300.0;
      driverDetailsContainerHeight = 310.0;
    });
  }

  void displayRequestRideContainer()
  {
    setState(() {
      requestRideContainerHeight = 250.0;
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 0.0;
      drawerOpen = true ;

    });

    saveRideRequest();
  }

  static const colorizeColors = [
    Colors.black54,
    Colors.black,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 55.0,
    fontFamily: 'Condensed',
  );

  resetApp()
  {
    setState(() {
      drawerOpen = true;

      searchContainerHeight = 270.0;
      rideDetailsContainerHeight = 0.0;
      requestRideContainerHeight = 0.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();

      statusRide = "";
      driverName = "";
      driverphone = "";
      carDetailsDriver = "";
      rideStatus = "Driver is Coming";
      driverDetailsContainerHeight = 0.0;
    });

    locatePosition();
  }

  void displayRiderDetailsContainer() async
  {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 270.0;
      bottomPaddingOfMap = 290;
      drawerOpen = false;

    });
  }

  void locatePosition() async
  {
    Position position=await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    currentPosition= position;

    LatLng latLatPosition = LatLng(position.latitude, position.longitude);


    CameraPosition cameraPosition= new CameraPosition(target: latLatPosition,zoom: 14);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));


    String address = await AssistantMethods.searchingCoordinateAddress(position,context);
    print("This is your address :: " + address);

    initGeoFireListner();

    uName = userCurrentInfo!.name!;

    AssistantMethods.retrieveHistoryInfo(context);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(7.710223268628142, 80.61482552092644),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        color: Colors.white70,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              //Drawer Header
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset("images/user_icon.png", height: 65.0, width: 65.0,),
                      SizedBox(width: 16.0,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(uName, style: TextStyle(fontSize: 16.0, fontFamily: "Brand Bold"),),
                          SizedBox(height: 6.0,),
                          GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfileTabPage()));
                              },
                              child: Text("Visit Profile")
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              DividerWidget(),

              SizedBox(height: 12.0,),

              //Drawer Body Contrllers
              /*GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> HistoryScreen()));
                },
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text("Search by bus route number", style: TextStyle(fontSize: 15.0),),
                ),
              ),*/



              GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> HistoryScreen()));
                },
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text("History", style: TextStyle(fontSize: 15.0),),
                ),
              ),
              GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfileTabPage()));
                },
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text("Visit Profile", style: TextStyle(fontSize: 15.0),),
                ),
              ),
              GestureDetector(
                onTap: ()
                {
                  Navigator.pushNamedAndRemoveUntil(context, AboutScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text("About", style: TextStyle(fontSize: 15.0),),
                ),
              ),
              GestureDetector(
                onTap: ()
                {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, loginscreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text("Sign Out", style: TextStyle(fontSize: 15.0),),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack (
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller){
              _controllerGoogleMap.complete(controller);
              newGoogleMapController =  controller;

              setState(() {
                bottomPaddingOfMap=270.0;
              });

              locatePosition();

            },
          ),

          //drawer button
          Positioned(
            top: 45.0,
            left: 22.0,
            child: GestureDetector(
              onTap: (){
                if(drawerOpen)
                  {
                    scaffoldKey.currentState!.openDrawer();
                  }
                else
                  {
                    resetApp();
                  }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen) ? Icons.menu : Icons.close ,color: Colors.black,),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //Search UI
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0),topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start ,
                    children: [
                      Text("Hey there!",style: TextStyle(fontSize: 30.0),),
                      Text("Where do you want to go",style: TextStyle(fontSize: 18.0,fontFamily:"Brand Bold"),),
                      SizedBox(height: 10.0,),
                      GestureDetector(
                        onTap: () async
                        {
                          var res = await Navigator.push(context, MaterialPageRoute(builder: (context)=>SearchScreen()));

                          if (res == "obtainDirection")
                            {
                              displayRiderDetailsContainer();
                            }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7,0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.search,color: Colors.blue,),
                                SizedBox(width: 20.0,),
                                Text("Search location",style: TextStyle(color: Colors.grey),)
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.0,),
                      Row(
                        children: [
                          Icon(Icons.home, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  Provider.of<AppData>(context).pickUpLocation !=null ?Provider.of<AppData>(context).pickUpLocation!.placeName! :"add home"
                              ),
                              SizedBox(height: 4.0,),
                              Text("Your home address", style: TextStyle(color: Colors.grey,fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: 10.0,),
                    DividerWidget(),
                    SizedBox(height: 16.0,),
                    /*Row(
                          children: [
                          Icon(Icons.work, color: Colors.grey,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Work"),
                              SizedBox(height: 4.0,),
                              Text("Your Office address", style: TextStyle(color: Colors.grey,fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),*/
                    ],
                  ),
                ),
              ),
            ),
          ),


          //Ride details
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7,0.7),
                    )
                  ]
                ),

                child: Padding(
                  padding:  EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: ()
                        {
                          displayToastMessage("searching a semi-luxury bus...", context);

                          setState(() {
                            state = "requesting";
                            carRideType = "semi luxury";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireAssistant.nearByAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset("images/bus-icon-png.png", height: 70.0, width: 80.0,),
                                SizedBox(width: 16.0,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Semi-luxury", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold",),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! : '') , style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null) ? 'RS.${AssistantMethods.calculateFares(tripDirectionDetails!)*2}' : ''), style: TextStyle(fontFamily: "Brand Bold",),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10.0,),
                      Divider(height: 2.0, thickness: 2.0,),
                      SizedBox(height: 10.0,),

                      GestureDetector(
                        onTap: ()
                        {
                          displayToastMessage("searching a luxury bus...", context);

                          setState(() {
                            state = "requesting";
                            carRideType = "luxury";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireAssistant.nearByAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset("images/bus-icon-png.png", height: 70.0, width: 80.0,),
                                SizedBox(width: 16.0,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Luxury", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold",),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! : ' ') , style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null) ? 'RS.${(AssistantMethods.calculateFares(tripDirectionDetails!))*3}' : ''), style: TextStyle(fontFamily: "Brand Bold",),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10.0,),
                      Divider(height: 2.0, thickness: 2.0,),
                      SizedBox(height: 10.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckAlt, size: 18.0, color: Colors.black54,),
                            SizedBox(width: 16.0,),
                            Text("Cash"),
                            SizedBox(width: 6.0,),
                            Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 16.0,),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.0,),

                    ],
                  ),
                ),
              ),
            ),
          ),

          //request or cancel UI
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7,0.7),
                  ),
                ]
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    //SizedBox(height: 2.0,),

                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting a Ride',
                            textAlign: TextAlign.center,
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                          ),
                          ColorizeAnimatedText(
                            'Please wait...',
                            textAlign: TextAlign.center,
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),

                    SizedBox(height: 12.0,),

                    GestureDetector(
                      onTap: (){
                        cancelRiderRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(width: 2.0,color: Colors.grey),
                        ),
                        child: Icon(Icons.close,size: 26.0,),
                      ),
                    ),

                    SizedBox(height: 22.0,),

                    Container(
                      width: double.infinity,
                      child: Text( "Cancel ride", textAlign: TextAlign.center,style: TextStyle(fontSize: 12.0),),
                    )
                  ],
                ),
              ),
            ),
          ),

          //Display assigned driver info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
              child: Container(
                decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
                height: driverDetailsContainerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(rideStatus, textAlign: TextAlign.center, style: TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"),),
                          ],
                      ),
                          SizedBox(height: 22.0,),

                          Divider(height: 2.0, thickness: 2.0,),

                          SizedBox(height: 22.0,),

                          Text(carDetailsDriver, style: TextStyle(color: Colors.grey),),

                          Text(driverName, style: TextStyle(fontSize: 20.0),),

                          SizedBox(height: 22.0,),

                          Divider(height: 2.0, thickness: 2.0,),

                          SizedBox(height: 22.0,),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [

                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: RaisedButton(
                                  shape: new RoundedRectangleBorder(
                                    borderRadius: new BorderRadius.circular(24.0),
                                  ),
                                  onPressed: () async
                                  {
                                    launch(('tel://${driverphone}'));
                                  },
                                  color: Colors.black87,
                                  child: Padding(
                                    padding: EdgeInsets.all(17.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text("Call Driver   ", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                        Icon(Icons.call, color: Colors.white, size: 26.0,),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),


                ),


            ),




          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async
  {
    var initialPos = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos!.latitude!, initialPos.longitude!);
    var dropOffLatLng = LatLng(finalPos!.latitude!, finalPos.longitude!);
    
    showDialog(
        context: context,
        builder: (BuildContext context)=> ProgressDialog(message: "Please wait...")
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    print("this is Encoded Points::");
    print(details!.encodedPoints);


    PolylinePoints polylinePoints= PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResults = polylinePoints.decodePolyline(details.encodedPoints!);

    pLineCoordinates.clear();

    if(decodedPolyLinePointsResults.isNotEmpty)
      {
        decodedPolyLinePointsResults.forEach((PointLatLng pointLatLng) {
            pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
        });
      }

    polylineSet.clear();

    setState(() {
      Polyline polyline= Polyline(
        color: Colors.black54,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if(pickUpLatLng.latitude> dropOffLatLng.latitude && pickUpLatLng.longitude > dropOffLatLng.longitude)
      {
        latLngBounds = LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
      }
    else if(pickUpLatLng.longitude> dropOffLatLng.longitude )
    {
      latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude), northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    }
    else if(pickUpLatLng.latitude> dropOffLatLng.latitude )
    {
      latLngBounds = LatLngBounds(southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    }
    else
      {
        latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
      }
    
    newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: initialPos.placeName,snippet: "my Location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: finalPos.placeName,snippet: "dropoff Location"),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blue,
      center: pickUpLatLng,
      radius: 8,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.red,
      center: dropOffLatLng,
      radius: 8,
      strokeWidth: 4,
      strokeColor: Colors.redAccent,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGeoFireListner()
  {
    Geofire.initialize("availableDrivers");

    Geofire.queryAtLocation(currentPosition.latitude, currentPosition.longitude, 5)!.listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NeabyavailableDrivers availableDrivers = NeabyavailableDrivers();
            availableDrivers.key = map['key'];
            availableDrivers.latitude = map['latitude'];
            availableDrivers.longitude = map['longitude'];
            GeoFireAssistant.nearByAvailableDriversList.add(availableDrivers);
            if(nearbyAvailableDriverKeysLoaded == true)
              {
                updateAvailableDriversOnMap();
              }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NeabyavailableDrivers availableDrivers = NeabyavailableDrivers();
            availableDrivers.key = map['key'];
            availableDrivers.latitude = map['latitude'];
            availableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverLocation(availableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});
    });
  }

  void updateAvailableDriversOnMap()
  {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMarkers = Set<Marker>();
    for(NeabyavailableDrivers driver in GeoFireAssistant.nearByAvailableDriversList )
      {
        LatLng driverAvailablePosition =LatLng(driver.latitude!, driver.longitude!);

        Marker marker = Marker(
          markerId: MarkerId('driver${driver.key}'),
          position: driverAvailablePosition,
          icon: availableIcon!,
          rotation: AssistantMethods.createRandomNumber(360),
        );

        tMarkers.add(marker);
      }
    setState(() {

      markersSet = tMarkers;
    });
  }

  void createIconMarker()
  {
    if(availableIcon == null)
      {
        ImageConfiguration imageConfiguration = createLocalImageConfiguration(context,size: Size(1, 1));
        BitmapDescriptor.fromAssetImage(imageConfiguration,"images/bus2.png")
        .then((value)
          {
            availableIcon = value;
          });
      }
  }


  void noDriverFound()
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => NoDriverAvailableDialog(),
    );
  }


  void searchNearestDriver()
  {
    if(availableDrivers!.length == 0)
    {
      cancelRiderRequest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers![0];

    driversRef.child(driver.key!).child("vehicle_details").child("type").once().then((DataSnapshot snap) async
    {
      if(await snap.value != null)
      {
        String carType = snap.value.toString();
        if(carType == carRideType)
        {
          notifyDriver(driver);
          availableDrivers!.removeAt(0);
        }
        else
        {
          displayToastMessage(carRideType + " drivers not available. Try again.", context);
        }
      }
      else
      {
        displayToastMessage("No car found. Try again.", context);
      }
    });
  }

  void notifyDriver(NeabyavailableDrivers driver)
  {
    driversRef.child(driver.key!).child("newRide").set(rideRequestRef!.key);

    driversRef.child(driver.key!).child("token").once().then((DataSnapshot snap){
      if (snap.value !=null)
        {
          String token = snap.toString();
          AssistantMethods.sendNotificationToDriver(snap,token, context, rideRequestRef!.key);
        }
      else
      {
        return;
      }

      const oneSecondPassed = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecondPassed, (timer) {
        if(state != "requesting")
        {
          driversRef.child(driver.key!).child("newRide").set("cancelled");
          driversRef.child(driver.key!).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();
        }

        driverRequestTimeOut = driverRequestTimeOut - 1;

        driversRef.child(driver.key!).child("newRide").onValue.listen((event) {
          if(event.snapshot.value.toString() == "accepted")
          {
            driversRef.child(driver.key!).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }
        });

        if(driverRequestTimeOut == 0)
        {
          driversRef.child(driver.key!).child("newRide").set("timeout");
          driversRef.child(driver.key!).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          searchNearestDriver();
        }
      });

    });
  }
}
