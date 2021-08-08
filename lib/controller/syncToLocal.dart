import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/models/api.dart';
import 'package:aindo_kasir/models/barang.dart';
import 'package:aindo_kasir/models/index.dart';
import 'package:dio/dio.dart';

class SyncToLocal {
  Future getAllBarangtoLocal() async {
    var url = BaseUrl.sinkronisasiBarang;
    Response response = await Dio().get(url);

    // productData = data["barang"];

    return (response.data['barang']).map((barang) {
      print('menambah $barang');
      // print(response.data.toString());

      SQFliteBarang.sql.insertBarang(Barang.fromJson(barang));
    }).toList();
  }

  Future getAllJenisBarangtoLocal() async {
    var url = BaseUrl.sinkronisasiBarang;
    Response response = await Dio().get(url);

    // productData = data["barang"];

    return (response.data['jenis']).map((jenis) {
      print('menambah $jenis');
      // print(response.data.toString());

      SQFliteBarang.sql.insertJenisBarang(JenisBarang.fromJson(jenis));
    }).toList();
  }
}
