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

  List itemList = [];
  List<Map> dataList = [];
  List<Map<String, dynamic>> listPenjualan = [];
  List<Map<dynamic, dynamic>> listSaveItem = [];
  List<Map<String, dynamic>> savedlist = [];

  Future syncPenjualanToAPI(penjualan, penjualanDetail) async {
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
        'Item': [
          for (var j = 0; j < penjualanDetail.length; j++)
            if (penjualanDetail[j].iDTr == penjualan[i].iDTr)
              {
                "IDBarang": penjualanDetail[j].iDBarang.toString(),
                "Kuantiti": penjualanDetail[j].kuantiti.toString(),
                "HargaJual": penjualanDetail[j].hargaJual.toString(),
                "HargaBeli": penjualanDetail[j].hargaBeli.toString(),
                "DiskonSatuan": penjualanDetail[j].diskonSatuan.toString(),
              }
        ]
      };

      dataList.add(dataSync);

      final response = await Dio().post(BaseUrl.sinkronisasiPenjualan,
          data: {'token': tokenID, 'data': dataList});

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
        // print("pesan : $status");
        // print('data item : $data');
        print('data : $dataList');
        print('penjualan : ${penjualan.length}');
        print('detailPenjualan : ${penjualanDetail.length}');

        print("Menyimpan Data...");
      } else {
        print(response.statusCode);
      }
    }
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

  Future<List<PenjualanDetail>> fetchAllPenjualanDetail() async {
    final db = await conn.database;
    List<PenjualanDetail> penjualanDetailList = [];
    try {
      final maps = await db.rawQuery(
          'SELECT PenjualanDetail.IDTr, PenjualanDetail.IDBarang, PenjualanDetail.Kuantiti, PenjualanDetail.HargaBeli, PenjualanDetail.DiskonSatuan FROM PenjualanDetail INNER JOIN Penjualan ON PenjualanDetail.IDTr = Penjualan.IDTr WHERE PenjualanDetail.IDTr = Penjualan.IDTr ORDER BY PenjualanDetail.IDTr ASC');
      for (var item in maps) {
        penjualanDetailList.add(PenjualanDetail.fromJson(item));
      }
    } catch (e) {
      print(e.toString());
    }
    return penjualanDetailList;
  }

  var maps;

  Future<List<PenjualanDetail>?> fetchJoinPenjualanDetail(penjualan) async {
    final db = await conn.database;
    var idtr;
    List<PenjualanDetail> penjualanDetailList = [];

    for (var i = 0; i < penjualan.length; i++) {
      idtr = penjualan[i].iDTr;
      print('item : $idtr');

      maps = await db.query('PenjualanDetail',
          where: 'IDTr = ${penjualan[i].iDTr}');
      print(maps);

      for (var item = 0; item < maps.length; item++) {
        penjualanDetailList.add(PenjualanDetail.fromJson(maps[item]));
        print(maps);
      }
    }
    return penjualanDetailList;
  }
}
