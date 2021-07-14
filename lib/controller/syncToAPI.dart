import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/models/api.dart';
import 'package:aindo_kasir/models/penjualan.dart';
import 'package:aindo_kasir/models/penjualan_detail.dart';
import 'package:dio/dio.dart';

class SyncToAPI {
  final conn = SQFliteBarang.sql;

  Future fetchDataPenjualan() async {
    var db = await conn.database;
    List userList = [];
    try {
      List<Map<String, dynamic>> maps =
          await db.query('Penjualan', orderBy: 'IDTr');
      for (var item in maps) {
        userList.add(item);
      }
    } catch (e) {
      print(e.toString());
    }
    return userList;
  }

  Future<List<Penjualan>> fetchAllPenjualan() async {
    final db = await conn.database;
    List<Penjualan> penjualanList = [];
    try {
      final maps = await db.query('Penjualan');
      for (var item in maps) {
        penjualanList.add(Penjualan.fromJson(item));
      }
    } catch (e) {
      print(e.toString());
    }
    return penjualanList;
  }

  Future syncPenjualanToAPI(List<Penjualan> penjualan) async {
    for (var i = 0; i < penjualan.length; i++) {
      Map<String, dynamic> data = {
        "IDTr": penjualan[i].iDTr.toString(),
        "NomorTr": penjualan[i].nomorTr,
        "TanggalJual": penjualan[i].tanggalJual,
        "Diskon": penjualan[i].diskon.toString(),
        "DiskonRp": penjualan[i].diskonRp.toString(),
        'IDUser': penjualan[i].iDUser.toString(),
        'NominalJual': penjualan[i].nominalJual.toString(),
        'NominalBeli': penjualan[i].nominalBeli.toString(),
        'Bayar': penjualan[i].bayar.toString(),
        'Kembalian': penjualan[i].kembalian.toString(),
        'Sinkron': penjualan[i].sinkron.toString(),
      };
      final response =
          await Dio().post(BaseUrl.penjualanSync, data: {'data': data});
      if (response.statusCode == 200) {
        print("Menyimpan Data...");
      } else {
        print(response.statusCode);
      }
    }
  }

  /* untuk sync PenjualanDetail */
  /*========================== */

  Future syncPenjualanDetailToAPI(List<PenjualanDetail> detailPenjualan) async {
    for (var i = 0; i < detailPenjualan.length; i++) {
      Map<String, dynamic> item = {
        'IDTr': detailPenjualan[i].iDTr.toString(),
        "IDBarang": detailPenjualan[i].iDBarang.toString(),
        "Kuantiti": detailPenjualan[i].kuantiti.toString(),
        "HargaJual": detailPenjualan[i].hargaJual.toString(),
        "HargaBeli": detailPenjualan[i].hargaBeli.toString(),
        'DiskonSatuan': detailPenjualan[i].diskonSatuan.toString(),
      };
      final response = await Dio().post(BaseUrl.penjualanSync, data: {
        'data': {'Item': item}
      });
      if (response.statusCode == 200) {
        print("Menyimpan Data Penjualan Detail...");
      } else {
        print(response.statusCode);
      }
    }
  }

  Future fetchDataPenjualanDetail() async {
    var db = await conn.database;
    List userList = [];
    try {
      List<Map<String, dynamic>> maps =
          await db.query('PenjualanDetail', orderBy: 'IDTr');
      for (var item in maps) {
        userList.add(item);
      }
    } catch (e) {
      print(e.toString());
    }
    return userList;
  }

  Future<List<PenjualanDetail>> fetchAllPenjualanDetail() async {
    final db = await conn.database;
    List<PenjualanDetail> penjualanDetailList = [];
    try {
      final maps = await db.query('PenjualanDetail');
      for (var item in maps) {
        penjualanDetailList.add(PenjualanDetail.fromJson(item));
      }
    } catch (e) {
      print(e.toString());
    }
    return penjualanDetailList;
  }
}
