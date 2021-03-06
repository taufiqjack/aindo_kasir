import 'dart:convert';
import 'dart:typed_data';

import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/menu.dart';
import 'package:aindo_kasir/layout/search_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_files_and_screenshot_widgets_plus/share_files_and_screenshot_widgets_plus.dart';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';
import 'package:intl/intl.dart';
import 'package:take_screenshot/take_screenshot.dart';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentDetails extends StatefulWidget {
  PaymentDetails({Key? key}) : super(key: key);

  @override
  _PaymentDetailsState createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  final TakeScreenshotController takeScreenshotController =
      TakeScreenshotController();
  final GlobalKey _globalKey = GlobalKey();
  int originalSize = 800;

  final f = new DateFormat('dd-MM-yyyy HH:mm:ss');

  List<Map<dynamic, dynamic>> listSaveOrder = [];
  String? jumlahHarga;
  String? tunai;
  String? kembali;

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cart = prefs.getStringList('newCart')!;
    final cartJumlahHarga = prefs.getString('newJumlahHarga');
    final jumlahTunai = prefs.getInt('tunai');
    final jumlahKembalian = prefs.getInt('kembali');
    setState(() {
      cart.forEach((item) {
        listSaveOrder.add(jsonDecode(item));
      });
    });
    setState(() {
      jumlahHarga = cartJumlahHarga.toString();
      tunai = jumlahTunai.toString();
      kembali = jumlahKembalian.toString();
    });
  }

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
                child: MenuKasir(),
              ),
            );
          },
        ),
      ),
      body: WillPopScope(
        onWillPop: backPress,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15),
          child: Center(
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 3),
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
                          child: FutureBuilder(
                            future: SQFliteBarang.sql.getPenjualanByLatest(),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              return snapshot.hasData
                                  ? ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
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
                                  // shrinkWrap: true,
                                  itemCount: listSaveOrder.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final barangData = listSaveOrder[index];
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${barangData['Nama']}'),
                                        Text('x ${barangData['quantity']}'),
                                        Text(rupiah(
                                            '@${barangData['hargaJual']}')),
                                        Text(
                                          rupiah(int.parse(
                                                  '${barangData['quantity']}') *
                                              int.parse(
                                                  barangData['hargaJual'])),
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
                                    '${rupiah(jumlahHarga)}',
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
                                  '${rupiah(tunai)}',
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
                                  '${rupiah(kembali)}',
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
                          type: PageTransitionType.fade,
                          child: SearchPrintPage()));
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

  Future<bool> backPress() async {
    Navigator.push(context,
        PageTransition(type: PageTransitionType.fade, child: MenuKasir()));
    return false;
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      SQFliteBarang.sql.getPenjualanByLatest();
    });
    getData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SQFliteBarang.sql.getPenjualanByLatest();
  }
}
