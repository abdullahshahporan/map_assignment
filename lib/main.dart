import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() => runApp(RealTimeLocationApp());

class RealTimeLocationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RealTimeLocationTracker(),
    );
  }
}

class RealTimeLocationTracker extends StatefulWidget {
  @override
  _RealTimeLocationTrackerState createState() => _RealTimeLocationTrackerState();
}

class _RealTimeLocationTrackerState extends State<RealTimeLocationTracker> {
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  Marker? _currentMarker;
  List<LatLng> _polylineCoordinates = [];
  Polyline _polyline = Polyline(
    polylineId: PolylineId("route"),
    color: Colors.blue,
    width: 5,
    points: [],
  );
  late LatLng _currentLatLng;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndLocate();
  }

  Future<void> _checkLocationPermissionAndLocate() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show a message
      _showMessage("Location services are disabled. Please enable them to continue.");
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied
        _showMessage("Location permission is denied. Please allow it to continue.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission denied forever
      _showMessage("Location permission is permanently denied. Please enable it from settings.");
      return;
    }

    // Fetch the current location and start updates
    _fetchAndUpdateLocation();
    Timer.periodic(Duration(seconds: 10), (timer) => _fetchAndUpdateLocation());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchAndUpdateLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentMarker = Marker(
        markerId: MarkerId("current_location"),
        position: _currentLatLng,
        infoWindow: InfoWindow(
          title: "My Current Location",
          snippet: "${position.latitude}, ${position.longitude}",
        ),
      );

      if (_polylineCoordinates.isNotEmpty) {
        _polylineCoordinates.add(_currentLatLng);
      } else {
        _polylineCoordinates = [_currentLatLng];
      }

      _polyline = Polyline(
        polylineId: PolylineId("route"),
        color: Colors.blue,
        width: 5,
        points: _polylineCoordinates,
      );

      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLatLng, zoom: 15),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Real-Time Location Tracker"),
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(23.7216771, 90.4165835), // Default position
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          _mapController = controller;
        },
        markers: _currentMarker != null ? {_currentMarker!} : {},
        polylines: {_polyline},
      ),
    );
  }
}
