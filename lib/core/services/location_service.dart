/// Core service for accessing device GPS and location data.
library;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request location permission
  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current GPS location once
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Live GPS tracking
  Stream<Position> getPositionStream({bool enableBackgroundTracking = false}) {
    final LocationSettings settings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: true,
        foregroundNotificationConfig: enableBackgroundTracking
            ? const ForegroundNotificationConfig(
                notificationTitle: 'MyFuel trip tracking',
                notificationText: 'Your trip location is being tracked.',
                enableWakeLock: true,
              )
            : null,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      );
    }

    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
