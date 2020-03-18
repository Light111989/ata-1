import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps;

/// A custom Flutter Google Map.
/// Have some features:
/// 1. Specify current location of device
/// 2. Pin any marker on map and move it
/// 3. Show circle around marked position with deviation radius
/// 4. Calulate distance between current location and marked position
/// Example code :
///
/// #admin user
/// ```dart
/// AtaMap(
///    isMoveableMarker: true,
///)
/// ```
/// #normal user
/// ```dart
/// AtaMap(
///    titleMarkedPosition: 'Office Position',
///    markedLat: 10.762622,
///    markedLng:  106.660172,
///)
/// ```
class AtaMap extends StatefulWidget {
  final Function onLongPress;
  final double markedLat;
  final double markedLng;
  final bool isMoveableMarker;
  final double authRange;
  final String titleMarkedPosition;

  AtaMap({
    this.markedLat = 10.7440878,
    this.markedLng = 106.7007886,
    this.isMoveableMarker = false,
    this.authRange = 100,
    this.titleMarkedPosition = "Office Location",
    this.onLongPress,
  });

  @override
  State<AtaMap> createState() => AtaMapState();
}

class AtaMapState extends State<AtaMap> {
  double currentMarkedLat;
  double currentMarkedLng;
  double currentLocationLat;
  double currentLocationLng;
  bool _isMapReady = false;
  static const double DEFAULT_ZOOM = 17;
  CameraPosition get defaultCamera {
    return CameraPosition(
      target: LatLng(currentMarkedLat, currentMarkedLng),
      zoom: DEFAULT_ZOOM,
    );
  }

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set();
  Set<Circle> _circles = Set();
  BitmapDescriptor markedLocationIcon;
  @override
  void initState() {
    super.initState();
    currentMarkedLat = widget.markedLat;
    currentMarkedLng = widget.markedLng;
    _setCustomMapIcons();
  }

  void _setCustomMapIcons() async {
    markedLocationIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(128, 128)), 'assets/images/marked-location-icon.png');
  }

  Future<Position> _getCurrentLocation() async => await Geolocator().getCurrentPosition();

  void _catchGpsOff(PlatformException e) {
    if (e.code == 'PERMISSION_DENIED') {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(title: Text("PERMISSION_DENIED"), content: Text('GPS device is OFF, please turn ON !'));
          });
    }
  }

  void _animateMap(LatLng position) async {
    try {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: DEFAULT_ZOOM)));
      if (_markers.length == 0) _addMarker(LatLng(currentMarkedLat, currentMarkedLng));
    } on MissingPluginException catch (e) {
      print(e.toString());
    }
  }

  void _goToOfficeLocation() async {
    try {
      if (_isMapReady) _animateMap(LatLng(currentMarkedLat, currentMarkedLng));
    } on PlatformException catch (e) {
      _catchGpsOff(e);
    }
  }

  void _goToCurrentLocation() async {
    try {
      Position currentPosition = await _getCurrentLocation();
      _animateMap(LatLng(currentPosition.latitude, currentPosition.longitude));
      currentLocationLat = currentPosition.latitude;
      currentLocationLng = currentPosition.longitude;
    } on PlatformException catch (e) {
      _catchGpsOff(e);
    }
  }

  void _addMarker(LatLng point) {
    if (mounted)
      setState(() {
        _markers.clear();
        _circles.clear();
        currentMarkedLat = point.latitude;
        currentMarkedLng = point.longitude;
        _markers.add(Marker(
            markerId: MarkerId(point.toString()),
            position: point,
            infoWindow: InfoWindow(
                title: widget.isMoveableMarker ? '$currentMarkedLat, $currentMarkedLng' : '${widget.titleMarkedPosition}',
                snippet: 'Distance to Office :${_calcDistance()} m'),
            icon: markedLocationIcon,
            draggable: widget.isMoveableMarker,
            onDragEnd: ((newPoint) {
              if (widget.isMoveableMarker) _addMarker(newPoint);
            })));
        _circles.add(Circle(
            circleId: CircleId(point.toString()),
            center: point,
            radius: widget.authRange,
            strokeWidth: 1,
            strokeColor: Colors.blue.withOpacity(0.3),
            fillColor: Colors.blue.withOpacity(0.2)));
      });
  }

  void _handleLongPress(LatLng point) {
    if (widget.isMoveableMarker && _isMapReady) _addMarker(point);
    if (widget.onLongPress != null) widget.onLongPress(point);
  }

  int _calcDistance() {
    try {
      return maps.SphericalUtil.computeDistanceBetween(
              maps.LatLng(currentMarkedLat, currentMarkedLng), maps.LatLng(currentLocationLat, currentLocationLng))
          .round();
    } on Exception catch (e) {
      print(e.toString());
      return 9999;
    }
  }

  bool isCheckinable() => _calcDistance() <= widget.authRange;
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
          //* This fixes GoogleMaps gestures within ScrollView
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            new Factory<OneSequenceGestureRecognizer>(
              () => new EagerGestureRecognizer(),
            ),
          ].toSet(),
          mapType: MapType.normal,
          initialCameraPosition: defaultCamera,
          onMapCreated: (GoogleMapController controller) async {
            _controller.complete(controller);
            Position currentLocation = await _getCurrentLocation();
            currentLocationLat = currentLocation.latitude;
            currentLocationLng = currentLocation.longitude;
            _addMarker(LatLng(widget.markedLat, widget.markedLng));
            _isMapReady = true;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _markers,
          circles: _circles,
          onLongPress: _handleLongPress),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 48.0, right: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
                height: 40.0,
                width: 45.0,
                padding: const EdgeInsets.only(right: 5),
                child: FloatingActionButton(
                  heroTag: "GoToOfficeLocation",
                  onPressed: _goToOfficeLocation,
                  backgroundColor: Colors.white70,
                  foregroundColor: Colors.black54,
                  child: Icon(Icons.home),
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.white70, width: 1)),
                )),
            Container(
                height: 40.0,
                width: 45.0,
                padding: const EdgeInsets.only(right: 5),
                child: FloatingActionButton(
                  heroTag: "GoToDeviceLocation",
                  onPressed: _goToCurrentLocation,
                  backgroundColor: Colors.white70,
                  foregroundColor: Colors.black54,
                  child: Icon(Icons.my_location),
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.white70, width: 1)),
                )),
          ],
        ),
      ),
    );
  }
}
