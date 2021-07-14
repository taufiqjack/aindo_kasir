import 'package:data_connection_checker_tv/data_connection_checker.dart';
import 'package:connectivity/connectivity.dart';

class ConnectInternet {
  static Future<bool> isInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      if (await DataConnectionChecker().hasConnection) {
        print("Jaringan data terkoneksi & koneksi internet terkonfirmasi.");
        return true;
      } else {
        print('Tidak ada Jaringan Internet :(');
        return false;
      }
    } else if (connectivityResult == ConnectivityResult.wifi) {
      if (await DataConnectionChecker().hasConnection) {
        print("Jaringan WIFI terkoneksi & koneksi internet terkonfirmasi");
        return true;
      } else {
        print('Tidak ada Jaringan Internet :(');
        return false;
      }
    } else {
      print(
          "Jaringan Data dan WIFI tidak terdeteksi, jaringan internet tidak ditemukan.");
      return false;
    }
  }
}
