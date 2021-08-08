import 'dart:convert';
import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/models/api.dart';
import 'package:aindo_kasir/models/penjualan.dart';
import 'package:aindo_kasir/models/penjualan_detail.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncToAPI {
  final conn = SQFliteBarang.sql;

  void initState() {
    getData();
  }

  String? tokenID;

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var itemList = prefs.getStringList('listItem')!;
    itemList.forEach((item) {
      savedlist.add(jsonDecode(item));
    });

    tokenID = token;
  }

  List<PenjualanDetail> detailPenjualan = [];
  Map<String, dynamic> item = {};
  List<Map> data = [];
  List<Map<String, dynamic>> listItemDetail = [];
  List<Map<dynamic, dynamic>> listSaveItem = [];
  List<Map<String, dynamic>> savedlist = [];

  Future syncPenjualanToAPI(List<Penjualan> penjualan) async {
    List<Map> item = data;
    for (var i = 0; i < penjualan.length; i++) {
      Map<String, dynamic> dataSync = {
        "IDTr": penjualan[i].iDTr.toString(),
        "NomorTr": penjualan[i].nomorTr.toString(),
        "TanggalJual": penjualan[i].tanggalJual.toString(),
        "Diskon": penjualan[i].diskon.toString(),
        "DiskonRp": penjualan[i].diskonRp.toString(),
        'IDUser': penjualan[i].iDUser.toString(),
        'NominalJual': penjualan[i].nominalJual.toString(),
        'NominalBeli': penjualan[i].nominalBeli.toString(),
        'Bayar': penjualan[i].bayar.toString(),
        'Kembalian': penjualan[i].kembalian.toString(),

        // 'Sinkron': penjualan[i].sinkron.toString(),
      };

      final response = await Dio().post(BaseUrl.sinkronisasiPenjualan, data: {
        'token': tokenID,
        'data': [
          dataSync,
          {
            'item': [listItemDetail]
          }
        ]
      });

      if (response.statusCode == 200) {
        var msg = response.data;
        var status = msg['data'][0]['msg'];
        var empty = msg['msg'];

        SharedPreferences prefer = await SharedPreferences.getInstance();
        String? psn = prefer.getString('message');
        String? emptyMes = prefer.getString('empty');
        psn = jsonEncode(status.toString());
        emptyMes = jsonEncode(empty.toString());
        prefer.setString('message', psn);
        prefer.setString('empty', emptyMes);

        print("pesan : $msg");
        print("pesan : $empty");
        print("pesan : $status");
        print('data item : $item');
        print('data : $dataSync');
        print('penjualan : ${penjualan.length}');
        print('detailPenjualan : ${detailPenjualan.length}');

        print("Menyimpan Data...");
      } else {
        print(response.statusCode);
      }
    }
    return data;
  }

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

  /* untuk sync PenjualanDetail */
  /*========================== */

  // List<Map<dynamic, dynamic>> savedlist = [];

  Future syncPenjualanDetailToAPI(detailPenjualan) async {
    for (var i = 0; i < detailPenjualan.length; i++) {
      item = {
        // 'IDTr': detailPenjualan[i].iDTr.toString(),
        "IDBarang": detailPenjualan[i].iDBarang.toString(),
        "Kuantiti": detailPenjualan[i].kuantiti.toString(),
        "HargaJual": detailPenjualan[i].hargaJual.toString(),
        "HargaBeli": detailPenjualan[i].hargaBeli.toString(),
        'DiskonSatuan': detailPenjualan[i].diskonSatuan.toString(),
      };

      data.add(item);
      // await Dio().post(BaseUrl.sinkronisasiPenjualan, data: {
      //   'token': tokenID,
      //   'data': [
      //     {
      //       'item': [listItemDetail]
      //     }
      //   ]
      // });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? itemList = prefs.getStringList('listItem');
      if (itemList == null) itemList = [];
      itemList.add(jsonEncode(savedlist));
      prefs.setStringList('listItem', itemList);

      print("pesan : $item");
      print(data);
      print(detailPenjualan.length);
    }

    return data;
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
