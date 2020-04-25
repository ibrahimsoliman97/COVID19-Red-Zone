import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:covid19/screens/my_map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  static const routeName = '/map';
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController mapController;
  int distanceRadius = 10;
  Location location = new Location();
  StreamSubscription _locationSubscription;
  Firestore firestore = Firestore.instance;
  Geoflutterfire geo = Geoflutterfire();
  BehaviorSubject<int> radius = BehaviorSubject.seeded(10);
  Stream<dynamic> query;
  StreamSubscription subscriptionCases;
  String userUID;
  GeoFirePoint _center;
  Random randomGen = Random();
  BitmapDescriptor pinLocationIcon;
  BitmapDescriptor myPin;
  ReceivePort port = ReceivePort();
  LocationDto lastLocation;
  static final _isolateName = 'LocatorIsolate';

  bool healthState = true;
  List<Placemark> placemark;
  static const zoomMap = {
    10: 14.0,
    20: 11.0,
  };
  bool tracking = false;
  String trackingLable = 'Going out - Start Tracking';
  Color trackingColor = Colors.black;

  final Set<Marker> _markers = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _getUserLocation();
    if (IsolateNameServer.lookupPortByName(_isolateName) != null) {
      IsolateNameServer.removePortNameMapping(_isolateName);
    }
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);
    port.listen((dynamic data) {});
    initPlatformState();
    setUserUID();
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 3), 'assets/images/virus.png')
        .then((onValue) {
      pinLocationIcon = onValue;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 3), 'assets/images/me.png')
        .then((onValue) {
      myPin = onValue;
    });
  }

  Future<void> initPlatformState() async {
    await BackgroundLocator.initialize();
    await BackgroundLocator.isRegisterLocationUpdate();
  }

  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (tracking == true) {
          BackgroundLocator.unRegisterLocationUpdate();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (tracking == true) {
          _startLocator();
        }
        break;
    }
  }

  void _getUserLocation() async {
    var pos = await location.getLocation();
    setState(() {
      _center = geo.point(latitude: pos.latitude, longitude: pos.longitude);
    });
  }

  Future<void> setUserUID() async {
    final FirebaseUser user = await FirebaseAuth.instance.currentUser();
    userUID = user.uid.toString();
  }

  static void callBackLoc(LocationDto locationDto) async {
    final SendPort send = IsolateNameServer.lookupPortByName(_isolateName);
    send?.send(locationDto);
  }

  static void notificationCallback() {}

  void _startLocator() {
    BackgroundLocator.registerLocationUpdate(
      callBackLoc,
      androidNotificationCallback: notificationCallback,
      settings: LocationSettings(
        notificationTitle: "Tracking on progress",
        notificationMsg:
            "Once you back home safely, please stop the tracking process.",
        wakeLockTime: 20,
        autoStop: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        MoveToBackground.moveTaskToBack();
        return false;
      },
      child: MaterialApp(
        home: Scaffold(
          body: _center == null
              ? Container(
                  child: Center(
                    child: Text(
                      'loading map..',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              : Stack(
                  children: <Widget>[
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      myLocationEnabled: true,
                      markers: _markers,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_center.latitude, _center.longitude),
                        zoom: 14.4746,
                      ),
                      compassEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                IgnorePointer(
                                  ignoring: true,
                                  child: RaisedButton(
                                    padding: EdgeInsets.all(4),
                                    onPressed: () => _updateQuery(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                          '#COVID19_RED_ZONE  #STAY_HOME'),
                                    ),
                                    textColor: Colors.white,
                                    color: Colors.green[700],
                                    shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(5.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              width: double.maxFinite,
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                runSpacing: 0,
                                spacing: 4.0,
                                children: <Widget>[
                                  RaisedButton.icon(
                                    icon: Icon(
                                      Icons.search,
                                      size: 14,
                                    ),
                                    onPressed: () => _updateQuery(10),
                                    label: Text(
                                      'WITHIN 20 KM',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    textColor: Colors.white,
                                    color: Colors.black,
                                    shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(30.0),
                                    ),
                                  ),
                                  RaisedButton.icon(
                                    icon: Icon(
                                      Icons.search,
                                      size: 14,
                                    ),
                                    onPressed: () => _updateQuery(20),
                                    label: Text(
                                      'WITHIN 40 KM',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    textColor: Colors.white,
                                    color: Colors.black,
                                    shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(30.0),
                                    ),
                                  ),
                                  RaisedButton.icon(
                                    onPressed: () => Navigator.of(context)
                                        .pushNamed(MyMapScreen.routeName),
                                    icon: Icon(
                                      Icons.my_location,
                                      size: 14,
                                    ),
                                    label: Text(
                                      'Location History',
                                      style: TextStyle(
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.clip,
                                    ),
                                    textColor: Colors.white,
                                    color: Colors.black,
                                    shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(30.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IgnorePointer(
                              ignoring: true,
                              child: RaisedButton(
                                padding: EdgeInsets.all(4),
                                onPressed: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Image.asset(
                                        'assets/images/virus.png',
                                        height: 16,
                                      ),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(left: 4.0),
                                          child: Text(
                                            'COVID Locations',
                                            style: TextStyle(fontSize: 8),
                                          )),
                                    ],
                                  ),
                                ),
                                textColor: Colors.white,
                                color: Colors.black54,
                                shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: tracking,
                              child: IgnorePointer(
                                ignoring: true,
                                child: RaisedButton(
                                  padding: EdgeInsets.all(4),
                                  onPressed: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Image.asset(
                                          'assets/images/me.png',
                                          height: 16,
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4.0),
                                            child: Text(
                                              'Your Locations',
                                              style: TextStyle(fontSize: 8),
                                            )),
                                      ],
                                    ),
                                  ),
                                  textColor: Colors.white,
                                  color: Colors.black54,
                                  shape: new RoundedRectangleBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.20,
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              height: MediaQuery.of(context).size.height * 0.07,
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              child: RaisedButton(
                                onPressed: () => _trackingTrigger(),
                                child: Text(trackingLable.toUpperCase()),
                                textColor: Colors.white,
                                color: trackingColor,
                                shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.07,
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              child: RaisedButton(
                                onPressed: () => _showHealthyDialog(),
                                child: Text('Update your health condition'
                                    .toUpperCase()),
                                textColor: Colors.white,
                                color: Colors.green[700],
                                shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  _trackingTrigger() {
    if (tracking == false) {
      tracking = true;
      location.changeSettings(interval: 30000, distanceFilter: 100);
      _locationSubscription =
          location.onLocationChanged.listen((LocationData currentLocation) {
        /*var distanceFromLast = calculateDistance(
          _center.latitude,
          _center.longitude,
          currentLocation.latitude,
          currentLocation.longitude,
        );*/
        if (currentLocation.speed < 5) {
          _center = geo.point(
              latitude: currentLocation.latitude,
              longitude: currentLocation.longitude);
          _addGeoPoint(currentLocation);
        }
      });
      setState(() {
        trackingLable = 'Stop Tracking';
        trackingColor = Colors.red;
      });
    } else {
      tracking = false;
      _updateQuery(null);
      _locationSubscription.cancel();
      setState(() {
        trackingLable = 'Going out - Start Tracking';
        trackingColor = Colors.black;
      });
    }
  }

  _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  Future<String> _addGeoPoint(currentLocation) async {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation.latitude, currentLocation.longitude),
          zoom: zoomMap[distanceRadius],
        ),
      ),
    );
    var marker = Marker(
      position: LatLng(currentLocation.latitude, currentLocation.longitude),
      icon: myPin,
      markerId: MarkerId(
        randomGen.nextDouble().toString(),
      ),
    );
    setState(() {
      _markers.add(marker);
    });
    GeoFirePoint point = geo.point(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude);

    var firebaseCollection = 'locations';
    if (placemark[0].country != null) {
      firebaseCollection = firebaseCollection + '_${placemark[0].country}';
    }
    DocumentReference documentReference =
        await firestore.collection(firebaseCollection).add({
      'position': point.data,
      'user': userUID,
      'time': DateTime.now(),
      'health': healthState,
    });
    return documentReference.documentID;
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = document.data['position']['geopoint'];
      String time = document.data['time'].toDate().toString();

      var marker = Marker(
        position: LatLng(pos.latitude, pos.longitude),
        icon: pinLocationIcon,
        infoWindow: InfoWindow(
          title: 'COVID-19 case was here!',
          snippet: '$time',
        ),
        markerId: MarkerId(
          randomGen.nextDouble().toString(),
        ),
      );
      setState(() {
        _markers.add(marker);
      });
    });
  }

  _startQuery() async {
    var pos = await location.getLocation();
    double lat = pos.latitude;
    double lng = pos.longitude;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: zoomMap[distanceRadius],
        ),
      ),
    );
    placemark = await Geolocator().placemarkFromCoordinates(lat, lng);
    var firebaseCollection = 'locations';
    var userCollection = 'users';

    if (placemark[0].country != null) {
      firebaseCollection = firebaseCollection + '_${placemark[0].country}';
      userCollection = userCollection + '_${placemark[0].country}';
    }
    firestore.collection(userCollection).document(userUID).get().then(
      (DocumentSnapshot) {
        if (DocumentSnapshot.data != null) {
          healthState = DocumentSnapshot.data['health'];
        }
      },
    );
    // Make a referece to firestore
    var ref = firestore
        .collection(firebaseCollection)
        .where('health', isEqualTo: false);
    _center = geo.point(latitude: lat, longitude: lng);

    subscriptionCases = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
            center: _center,
            radius: rad.toDouble(),
            field: 'position',
            strictMode: true,
          );
    }).listen(_updateMarkers);
  }

  _updateQuery(int value) async {
    if (value != null) {
      distanceRadius = value;
    }
    var pos = await location.getLocation();
    _center = geo.point(latitude: pos.latitude, longitude: pos.longitude);
    Fluttertoast.showToast(
        msg: 'Reloading COVID19 cases within ${distanceRadius * 2} KM.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
    _markers.clear();
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_center.latitude, _center.longitude),
          zoom: zoomMap[distanceRadius],
        ),
      ),
    );
    setState(() {
      radius.add(distanceRadius);
    });
  }

  void _showHealthyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          titlePadding: EdgeInsets.all(0.0),
          title: Container(
            padding: EdgeInsets.all(16),
            color: Colors.green,
            child: new Text(
              "Have you tested positive for COVID-19?",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    text: 'Your current state: ',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            healthState ? 'Not tested or Negitive' : 'Positive',
                        style: TextStyle(
                            color: healthState ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Once you clicked that you have tested positive, your locations history will be public to other users without your personal information (anonymous).',
                textAlign: TextAlign.justify,
              ),
            ],
          ),
          actions: <Widget>[
            Container(
              width: double.maxFinite,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new RaisedButton(
                    color: Colors.red,
                    child: new Text("Yes, I have tested positive."),
                    onPressed: () => setPositive(),
                  ),
                  new RaisedButton(
                    color: Colors.green,
                    child: new Text("No, I have tested negative."),
                    onPressed: () {
                      healthState = true;
                      var userCollection = 'users';
                      if (placemark[0].country != null) {
                        userCollection =
                            userCollection + '_${placemark[0].country}';
                      }
                      firestore
                          .collection(userCollection)
                          .document(userUID)
                          .setData(
                        {
                          'user': userUID,
                          'time': DateTime.now(),
                          'health': healthState
                        },
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  new RaisedButton(
                    color: Colors.blue,
                    child: new Text("I have not been tested."),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            )
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }

  setPositive() {
    if (userUID == null){
      return;
    }
    var firebaseCollection = 'locations';
    var userCollection = 'users';
    if (placemark[0].country != null) {
      firebaseCollection = firebaseCollection + '_${placemark[0].country}';
      userCollection = userCollection + '_${placemark[0].country}';
    }
    healthState = false;
    firestore
        .collection(firebaseCollection)
        .where('user', isEqualTo: userUID)
        .snapshots()
        .listen(
          (data) => {
            data.documents.forEach((document) {
              firestore
                  .collection(firebaseCollection)
                  .document(document.documentID.toString())
                  .updateData({'health': false});
            })
          },
        );
    firestore.collection(userCollection).document(userUID).setData(
      {'user': userUID, 'time': DateTime.now(), 'health': healthState},
    );
    Navigator.of(context).pop();
  }

  @override
  dispose() {
    IsolateNameServer.removePortNameMapping('LocatorIsolate');
    subscriptionCases.cancel();
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
