import 'dart:typed_data';

import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/history_penjualan.dart';
import 'package:aindo_kasir/layout/print_history.dart';
import 'package:aindo_kasir/models/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:take_screenshot/take_screenshot.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:tanggal_indonesia/tanggal_indonesia.dart';
import 'package:share_files_and_screenshot_widgets_plus/share_files_and_screenshot_widgets_plus.dart';

class DetailHistory extends StatefulWidget {
  final Penjualan list;
  DetailHistory({required this.list});

  @override
  _DetailHistoryState createState() => _DetailHistoryState();
}

class _DetailHistoryState extends State<DetailHistory> {
  final TakeScreenshotController takeScreenshotController =
      TakeScreenshotController();
  GlobalKey _globalKey = GlobalKey();
  final f = new DateFormat('dd-MM-yyyy HH:mm:ss');
  List<PenjualanDetail> listDetailPenjualan = [];
  List<Barang> listBarang = [];
  var moneyFormat = NumberFormat('#,000');
  int originalSize = 800;

  getAllItemPenjualan() async {
    SQFliteBarang.sql
        .getJoinPenjualanDetail(widget.list.iDTr.toString())
        .then((values) {
      setState(() {
        values.forEach((element) {
          listDetailPenjualan.add(PenjualanDetail(
            iDTr: element.iDTr,
            nama: element.nama,
            iDBarang: element.iDBarang,
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

  Widget? image;

  @override
  void initState() {
    super.initState();
    getAllItemPenjualan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: Text('${widget.list.nomorTr}'),
        leading: GestureDetector(
          child: Icon(Icons.arrow_back),
          onTap: () {
            Navigator.push(
                context,
                PageTransition(
                    child: HistoryPenjualan(), type: PageTransitionType.fade));
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: RepaintBoundary(
          key: _globalKey,
          child: Container(
            height: 500,
            width: 360,
            color: Colors.white,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 30,
                          child: Image.asset(
                            'assets/images/fiesto.png',
                            height: 50,
                            width: 50,
                          ),
                        ),
                      ),
                      Padding(padding: EdgeInsets.all(10)),
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'FIESTO INFORMATIKA INDONESIA',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Text(
                              'Jl. Ngagel Jaya Tengah III, Surabaya',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 50),
                            child: Text(
                              '(031) 505-2747',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 110),
                  child: Container(
                      height: 50,
                      width: 500,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Text(
                            'No. Order : ${widget.list.nomorTr}\nWaktu : ${f.format(DateTime.parse(widget.list.tanggalJual))}'),
                      )),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 150),
                  child: Container(
                    height: 200,
                    width: 500,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: listDetailPenjualan.length,
                              itemBuilder: (BuildContext context, int index) {
                                final barangData = listDetailPenjualan[index];
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${barangData.nama}'),
                                    Text('x ${barangData.kuantiti}'),
                                    Text(rupiah(
                                        int.parse('${barangData.hargaJual}'))),
                                    Text(
                                      rupiah(int.parse(
                                              '${barangData.kuantiti}') *
                                          int.parse('${barangData.hargaJual}')),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                );
                              }),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 350),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      thickness: 3,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 365),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${rupiah(widget.list.nominalJual)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tunai',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${rupiah(widget.list.bayar)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kembali',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${rupiah(widget.list.kembalian)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 440),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'BARANG YANG SUDAH DIBELI',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            'TIDAK BISA DIKEMBALIKAN',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
        // ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton.extended(
                label: Text(
                  'Share',
                  style: TextStyle(fontSize: 20),
                ),
                onPressed: () async {
                  requestPermission();
                  Future.delayed(Duration(seconds: 2), () async {
                    ShareFilesAndScreenshotWidgets().shareScreenshot(
                        _globalKey,
                        originalSize,
                        'ShareSocialMedia',
                        'aindo.png',
                        'image/png',
                        text: 'dibagikan dari AindoKasir');

                    saveToGallery();
                  });
                },
                backgroundColor: Colors.indigo.shade900,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                      context,
                      PageTransition(
                          child: PrintHistory(
                            penjualan: widget.list,
                          ),
                          type: PageTransitionType.fade));
                },
                label: Text(
                  'Print',
                  style: TextStyle(fontSize: 20),
                ),
                backgroundColor: Colors.indigo.shade900,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
  }

  saveToGallery() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    ByteData? byteData =
        await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      final result =
          await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
      print(result);
    }
  }

  toastInfo(String info) {
    Fluttertoast.showToast(
        msg: 'Gambar Tersimpan', toastLength: Toast.LENGTH_LONG);
  }
}
