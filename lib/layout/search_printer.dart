import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/payment_details.dart';
import 'package:aindo_kasir/models/barang.dart';
import 'package:aindo_kasir/models/penjualan.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';
import 'package:intl/intl.dart';

class SearchPrintPage extends StatefulWidget {
  final Barang barangCetak;
  final int index;
  SearchPrintPage({required this.barangCetak, required this.index});

  @override
  _SearchPrintPageState createState() => _SearchPrintPageState();
}

class _SearchPrintPageState extends State<SearchPrintPage> {
  bool connected = false;
  List availableBluetoothDevices = [];

  List<Penjualan> listBarang = [];

  @override
  void initState() {
    super.initState();
    SQFliteBarang.sql.getPenjualan().then((value) {
      setState(() {
        value.forEach((data) {
          listBarang.add(Penjualan(
            nomorTr: data.nomorTr,
            tanggalJual: data.tanggalJual,
            diskon: data.diskon,
            diskonRp: data.diskonRp,
            iDUser: data.iDUser,
            nominalJual: data.nominalJual,
            nominalBeli: data.nominalBeli,
            bayar: data.bayar,
            kembalian: data.kembalian,
            sinkron: data.sinkron,
          ));
        });
      });
    }).catchError((error) {
      print(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: <Color>[Colors.indigo.shade900, Colors.indigo.shade800]),
        )),
        title: Text('Cetak Nota'),
        leading: InkWell(
          child: Icon(Icons.arrow_back_sharp),
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                child: PaymentDetails(
                  dataPenjualan: widget.barangCetak,
                  itemCount: widget.index,
                ),
              ),
            );
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bluetooth Yang Tersedia"),
            TextButton(
              onPressed: () {
                requestBtPermission();
                setState(() {
                  this.getBluetooth();
                });
              },
              child: Text("Cari Perangkat"),
            ),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: availableBluetoothDevices.length > 0
                    ? availableBluetoothDevices.length
                    : 0,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      String select = availableBluetoothDevices[index];
                      List list = select.split("#");
                      // String name = list[0];
                      String mac = list[1];
                      this.setConnect(mac);
                    },
                    title: Text('${availableBluetoothDevices[index]}'),
                    subtitle: Text("Click to connect"),
                  );
                },
              ),
            ),
            SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: connected ? this.printTicket : null,
        label: Text(
          'Print Nota',
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.indigo.shade900,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  late FToast fToast;

  toastInfo() {
    Widget toast = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.greenAccent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check),
            SizedBox(
              width: 12.0,
            ),
            Text("This is a Custom Toast"),
          ],
        ));
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );
  }

  toastBluetoothConnected() {
    Fluttertoast.showToast(
        msg: 'Tersambung ke Bluetooth',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 12.0);
  }

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    print("Print $bluetooths");
    setState(() {
      availableBluetoothDevices = bluetooths!;
    });
  }

  Future<void> setConnect(String mac) async {
    final String? result = await BluetoothThermalPrinter.connect(mac);
    print("state conneected $result");
    if (result == "true") {
      setState(() {
        connected = true;
        toastBluetoothConnected();
      });
    }
  }

  Future<void> printTicket() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      toastInfo();
      print("Print $result");
    } else {}
  }

  Future<void> printGraphics() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getGraphicsTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  final idTime = new DateFormat('dd-MM-yyyy HH:mm:ss');

  Future<List<int>> getGraphicsTicket() async {
    List<int> bytes = [];

    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // Print QR Code using native function
    bytes += generator.qrcode('http://www.fiesto.com');

    bytes += generator.hr();

    // Print Barcode using native function
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> getTicket() async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.text("Fiesto Informatika Indonesia",
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
        linesAfter: 1);

    bytes += generator.text("Jl. Ngagel Jaya Tengah III,\nSurabaya",
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('(031) 505-2747',
        styles: PosStyles(align: PosAlign.center), linesAfter: 1);

    bytes += generator.text(
        'No. Order: ${listBarang.last.nomorTr} \nWaktu: ${idTime.format(DateTime.parse(listBarang.last.tanggalJual))}',
        styles: PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1));

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Item',
          width: 4,
          styles: PosStyles(
              align: PosAlign.left, bold: true, height: PosTextSize.size1)),
      PosColumn(
          text: 'Qty',
          width: 2,
          styles: PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Harga',
          width: 3,
          styles: PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Total',
          width: 3,
          styles: PosStyles(align: PosAlign.left, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: '${widget.barangCetak.nama}',
          width: 12,
          styles: PosStyles(
            align: PosAlign.left,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: '${widget.index}',
          width: 2,
          styles: PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(text: 'x', width: 2, styles: PosStyles(align: PosAlign.left)),
      PosColumn(
          text: '@${rupiah(widget.barangCetak.hargaJual)}',
          width: 4,
          styles: PosStyles(align: PosAlign.left)),
      PosColumn(
          text:
              '${rupiah(widget.index * int.parse(widget.barangCetak.hargaJual))}',
          width: 4,
          styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL',
          width: 4,
          styles: PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text:
              '${rupiah(widget.index * int.parse(widget.barangCetak.hargaJual))}',
          width: 8,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);

    bytes += generator.text('Terima Kasih',
        styles: PosStyles(align: PosAlign.center, bold: true), linesAfter: 1);

    bytes += generator.text(
        'BARANG YANG SUDAH DIBELI\nTIDAK BISA DIKEMBALIKAN.',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.cut();
    return bytes;
  }

  requestBtPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
  }
}