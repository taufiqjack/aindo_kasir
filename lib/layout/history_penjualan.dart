import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/detail_history.dart';
import 'package:aindo_kasir/layout/menu.dart';
import 'package:aindo_kasir/models/index.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';

class HistoryPenjualan extends StatefulWidget {
  HistoryPenjualan({Key? key}) : super(key: key);

  @override
  _HistoryPenjualanState createState() => _HistoryPenjualanState();
}

class _HistoryPenjualanState extends State<HistoryPenjualan> {
  List<Penjualan> listPenjualan = [];
  List<PenjualanDetail> listDetailPenjualan = [];

  getAllPenjualan() async {
    SQFliteBarang.sql.getPenjualan().then((value) {
      setState(() {
        value.forEach((element) {
          listPenjualan.add(Penjualan(
            iDTr: element.iDTr,
            nomorTr: element.nomorTr,
            tanggalJual: element.tanggalJual,
            diskon: element.diskon,
            diskonRp: element.diskonRp,
            iDUser: element.iDUser,
            nominalJual: element.nominalJual,
            nominalBeli: element.nominalBeli,
            bayar: element.bayar,
            kembalian: element.kembalian,
            sinkron: element.sinkron,
          ));
        });
      });
    }).catchError((error) {
      print(error);
    });
  }

  getAllItemPenjualan() async {
    SQFliteBarang.sql.getPenjualanDetail().then((value) {
      setState(() {
        value.forEach((element) {
          listDetailPenjualan.add(PenjualanDetail(
            iDBarang: element.iDBarang,
            nama: element.nama,
            kuantiti: element.kuantiti,
            hargaJual: element.hargaJual,
            hargaBeli: element.hargaBeli,
            diskonSatuan: element.diskonSatuan,
          ));
        });
      });
    }).catchError((error) {
      print(error);
    });
  }

  @override
  void initState() {
    super.initState();
    getAllPenjualan();
    getAllItemPenjualan();
  }

  final idTime = new DateFormat('dd-MM-yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: Text('History Penjualan'),
        leading: GestureDetector(
          child: Icon(Icons.arrow_back),
          onTap: () {
            Navigator.push(
                context,
                PageTransition(
                    child: MenuKasir(), type: PageTransitionType.fade));
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: listPenjualan.isNotEmpty
            ? ListView.builder(
                itemCount: listPenjualan.length,
                itemBuilder: (BuildContext context, index) {
                  final x = listPenjualan[index];
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      title: Text(
                        'Nomor Transaksi : ${x.nomorTr}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          'Waktu Transaksi : ${tanggal(DateTime.parse(x.tanggalJual))}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            child: DetailHistory(
                              list: x,
                            ),
                            type: PageTransitionType.fade,
                          ),
                        );
                      },
                    ),
                  );
                })
            : Center(
                child: Text('Pesanan Anda Masih Kosong!'),
              ),
      ),
    );
  }
}
