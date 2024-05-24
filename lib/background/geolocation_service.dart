// this is primarily here for testing's sake since Geolocator was too hard to Mock

import 'package:geolocator/geolocator.dart';

class GeolocationService{
  Stream<Position> getCurrentLocation(){
    return Geolocator.getPositionStream();
  }
}