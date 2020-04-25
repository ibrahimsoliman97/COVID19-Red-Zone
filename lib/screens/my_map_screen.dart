import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';

class MyMapScreen extends StatefulWidget {
  static const routeName = '/my_map';
  @override
  _MyMapScreenState createState() => _MyMapScreenState();
}

class _MyMapScreenState extends State<MyMapScreen> with WidgetsBindingObserver {
  GoogleMapController mapController;
  Location location = new Location();
  Firestore firestore = Firestore.instance;
  Geoflutterfire geo = Geoflutterfire();
  String userUID;
  GeoFirePoint _center;
  Random randomGen = Random();
  BitmapDescriptor pinLocationIcon;
  BitmapDescriptor myPin;
  List<Placemark> placemark;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Location History'),
      ),
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
                    zoom: 12,
                  ),
                  compassEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ],
            ),
    );
  }

  _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  _startQuery() async {
    if(userUID == null){
      return;
    }
    var pos = await location.getLocation();
    double lat = pos.latitude;
    double lng = pos.longitude;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 12,
        ),
      ),
    );
    placemark = await Geolocator().placemarkFromCoordinates(lat, lng);
    var firebaseCollection = 'locations';
    if (placemark[0].country != null) {
      firebaseCollection = firebaseCollection + '_${placemark[0].country}';
    }
    firestore
        .collection(firebaseCollection)
        .where('user', isEqualTo: userUID)
        .snapshots()
        .listen(
          (data) => data.documents.forEach(
            (doc) {
              GeoPoint pos = doc.data['position']['geopoint'];
              String time = doc.data['time'].toDate().toString();
              var marker;
              if (doc.data['health'] == true) {
                marker = Marker(
                  position: LatLng(pos.latitude, pos.longitude),
                  icon: myPin,
                  infoWindow: InfoWindow(
                    title: 'You have been here.',
                    snippet: '$time',
                  ),
                  markerId: MarkerId(
                    randomGen.nextDouble().toString(),
                  ),
                );
              } else {
                marker = Marker(
                  position: LatLng(pos.latitude, pos.longitude),
                  icon: pinLocationIcon,
                  infoWindow: InfoWindow(
                    title: 'While you are positive',
                    snippet: '$time',
                  ),
                  markerId: MarkerId(
                    randomGen.nextDouble().toString(),
                  ),
                );
              }
              setState(() {
                _markers.add(marker);
              });
            },
          ),
        );
  }

  @override
  dispose() {
    super.dispose();
  }
}
