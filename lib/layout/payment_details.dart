import 'dart:typed_data';

import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/orderpages.dart';
import 'package:aindo_kasir/layout/search_printer.dart';
import 'package:aindo_kasir/models/barang.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';
import 'package:intl/intl.dart';
import 'package:take_screenshot/take_screenshot.dart';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:aindo_kasir/controller/global.dart' as global;

class PaymentDetails extends StatefulWidget {
  final Barang dataPenjualan;
  final int itemCount;
  PaymentDetails({required this.dataPenjualan, required this.itemCount});

  @override
  _PaymentDetailsState createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  final TakeScreenshotController takeScreenshotController =
      TakeScreenshotController();
  final GlobalKey _globalKey = GlobalKey();

  final f = new DateFormat('dd-MM-yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: <Color>[Colors.indigo.shade900, Colors.indigo.shade800]),
        )),
        title: Text('Detail Pembayaran'),
        leading: InkWell(
          child: Icon(Icons.arrow_back_sharp),
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                child: OrderPages(
                  barangData: widget.dataPenjualan,
                  item: widget.itemCount,
                ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Center(
          child: TakeScreenshot(
            controller: takeScreenshotController,
            child: RepaintBoundary(
              key: _globalKey,
              child: Container(
                height: 400,
                width: 350,
                color: Colors.white,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 30,
                          child: Image.asset(
                            'assets/images/fiesto.png',
                            height: 50,
                            width: 50,
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(10)),
                        Column(
                          children: [
                            Text(
                              'BEST BRAND',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Padding(padding: EdgeInsets.all(5)),
                            Text(
                              'Jl. Ngagel Jaya Tengah III, Surabaya',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '08123456789',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 500,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                      child: FutureBuilder(
                        future: SQFliteBarang.sql.getPenjualanByLatest(),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          print(
                              'data :${global.globalPenjualan.nomorTr.toString()}');
                          return snapshot.hasData
                              ? ListView.builder(
                                  itemCount: snapshot.data.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final x = snapshot.data[index];

                                    return Text(
                                        'No. Order : ${x.nomorTr}\nWaktu : ${f.format(DateTime.parse(x.tanggalJual))}');
                                  },
                                )
                              : CircularProgressIndicator();
                        },
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                        child: Row(
                          children: [
                            Text('${widget.dataPenjualan.nama}'),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10)),
                            Text('${widget.itemCount}'),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10)),
                            Text(
                                '@${rupiah(int.parse(widget.dataPenjualan.hargaJual))}'),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10)),
                            Text(
                                '${rupiah(widget.itemCount * int.parse(widget.dataPenjualan.hargaJual))}'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          children: [],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Divider(
                          thickness: 2,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 75),
                            ),
                            Text(
                              '${rupiah(widget.itemCount * int.parse(widget.dataPenjualan.hargaJual))}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(30)),
                  Text(
                    'BARANG YANG SUDAH DIBELI',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'TIDAK BISA DIKEMBALIKAN',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
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
                    try {
                      await takeScreenshotController.captureAndShare(
                          pixelRatio: 50);
                    } on Exception catch (e) {
                      print(e);
                    }
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
                          type: PageTransitionType.fade,
                          child: SearchPrintPage(
                            barangCetak: widget.dataPenjualan,
                            index: widget.itemCount,
                          )));
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

  @override
  void initState() {
    super.initState();

    setState(() {
      SQFliteBarang.sql.getPenjualanByLatest();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SQFliteBarang.sql.getPenjualanByLatest();
  }
}
