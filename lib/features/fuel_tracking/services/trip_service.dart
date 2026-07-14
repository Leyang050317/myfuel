import '../models/trip_model.dart';
import 'package:latlong2/latlong.dart';

class TripService {
  TripService._();

  static final TripService instance = TripService._();
  TripModel? _currentTrip;
  double? _plannedDistanceKm;
  Duration? _plannedDuration;
  TripModel? get currentTrip => _currentTrip;
  bool get isTracking => _currentTrip?.isTracking ?? false;
  double? get plannedDistanceKm => _plannedDistanceKm;
  Duration? get plannedDuration => _plannedDuration;

  void startTrip() {
    _currentTrip = TripModel(
      startTime: DateTime.now(),
      isTracking: true,
    );
  }

  void stopTrip() {
    if (_currentTrip == null) return;
    _currentTrip!.endTime = DateTime.now();
    _currentTrip!.isTracking = false;
  }

  void setPlannedRoute({
    required double distanceKm,
    required Duration duration,
  }) {
    _plannedDistanceKm = distanceKm;
    _plannedDuration = duration;
  }

  double get remainingDistanceKm {
    if (_plannedDistanceKm == null || _currentTrip == null) {
      return 0;
    }

    final remaining =
        _plannedDistanceKm! - _currentTrip!.totalDistanceKm;

    return remaining < 0 ? 0 : remaining;
  }

  double get progress {

    if (_plannedDistanceKm == null ||
        _plannedDistanceKm == 0 ||
        _currentTrip == null) {
      return 0;
    }

    return (_currentTrip!.totalDistanceKm /
        _plannedDistanceKm!)
        .clamp(0.0, 1.0);
  }

  Duration get remainingDuration {

    if (_plannedDuration == null) {
      return Duration.zero;
    }

    return Duration(
      seconds: ((_plannedDuration!.inSeconds) *
          (1 - progress))
          .round(),
    );
  }

  void updateLocation(LatLng location) {
    if (_currentTrip == null) return;
    final trip = _currentTrip!;
    if (trip.startLocation == null) {
      trip.startLocation = location;
      trip.previousLocation = location;
      trip.currentLocation = location;

      return;
    }

    final meters = Distance().as(
      LengthUnit.Meter,
      trip.previousLocation!,
      location,
    );
    trip.totalDistanceKm += meters / 1000;
    print("Distance = ${trip.totalDistanceKm.toStringAsFixed(3)} km");

    trip.previousLocation = location;
    trip.currentLocation = location;
  }

}

