import 'package:riderapp/Models/availableDrivers.dart';

class GeoFireAssistant
{
  static List<NeabyavailableDrivers> nearByAvailableDriversList = [];

  static void removeDriverFromList(String Key)
  {
    int index = nearByAvailableDriversList.indexWhere((element) => element.key == Key);
    nearByAvailableDriversList.removeAt(index);
  }

  static void updateDriverLocation(NeabyavailableDrivers driver)
  {
    int index = nearByAvailableDriversList.indexWhere((element) => element.key == driver.key);

    nearByAvailableDriversList[index].latitude = driver.latitude;
    nearByAvailableDriversList[index].longitude = driver.longitude;

  }
}