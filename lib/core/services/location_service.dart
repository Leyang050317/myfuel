/// Core service for accessing device GPS and location data.

import 'package:geolocator/geolocator.dart';

class LocationService {

  /// Request location permission
  Future<bool> requestPermission() async {

    bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.deniedForever) {
      return false;
    }

    return permission ==
        LocationPermission.always ||
        permission ==
            LocationPermission.whileInUse;
  }

  /// Get current GPS location once
  Future<Position> getCurrentLocation() async {

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

  }

  /// Live GPS tracking
  Stream<Position> getPositionStream() {

    return Geolocator.getPositionStream(

      locationSettings:
      const LocationSettings(

        accuracy: LocationAccuracy.best,

        distanceFilter: 0,

      ),

    );

  }

}
