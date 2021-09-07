import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/history_penjualan.dart';
import 'package:aindo_kasir/layout/menu.dart';
import 'package:aindo_kasir/models/penjualan.dart';
import 'package:aindo_kasir/models/penjualan_detail.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class PrintHistory extends StatefulWidget {
  final Penjualan penjualan;
  PrintHistory({required this.penjualan});

  @override
  _PrintHistoryState createState() => _PrintHistoryState();
}

class _PrintHistoryState extends State<PrintHistory> {
  bool? connected = false;
  List availableBluetoothDevices = [];

  List<PenjualanDetail> listDetailPenjualan = [];

  var moneyFormat = NumberFormat('#,000');

  getAllItemPenjualan() async {
    SQFliteBarang.sql
        .getJoinPenjualanDetail(widget.penjualan.iDTr.toString())
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

  @override
  void initState() {
    super.initState();
    getAllItemPenjualan();
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
                child: MenuKasir(),
              ),
            );
          },
        ),
      ),
      body: WillPopScope(
        onWillPop: backPress,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: connected == false
              ? Column(
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
                        child: Text("Cari Perangkat")),
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
                )
              : Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Bluetooth Telah Terhubung'),
                        Icon(
                          Icons.done,
                          color: Colors.lightGreen,
                        )
                      ]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: connected == true ? this.printTicket : printTicket,
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
    } else if (isConnected == 'false') {
      return;
    }
  }

  Future<void> printGraphics() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getGraphicsTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {}
  }

  final idTime = new DateFormat('dd-MM-yyyy HH:mm:ss');

  Future<List<int>> getGraphicsTicket() async {
    List<int> bytes = [];

    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.qrcode('http://www.fiesto.com');

    bytes += generator.hr();

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
        'No. Order: ${widget.penjualan.nomorTr} \nWaktu: ${idTime.format(DateTime.parse(widget.penjualan.tanggalJual))}',
        styles: PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1));

    bytes += generator.hr();
    // bytes += generator.row([
    //   PosColumn(
    //       text: 'Item',
    //       width: 4,
    //       styles: PosStyles(
    //           align: PosAlign.left, bold: true, height: PosTextSize.size1)),
    //   PosColumn(
    //       text: 'Qty',
    //       width: 2,
    //       styles: PosStyles(align: PosAlign.left, bold: true)),
    //   PosColumn(
    //       text: 'Harga',
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.left, bold: true)),
    //   PosColumn(
    //       text: 'Total',
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.left, bold: true)),
    // ]);

    for (int i = 0; i < listDetailPenjualan.length; i++) {
      bytes += generator.row([
        PosColumn(
            text: '${listDetailPenjualan[i].nama}',
            width: 5,
            styles: PosStyles(
              align: PosAlign.left,
            )),
        // ]);

        // bytes += generator.row([
        PosColumn(
            text: '${listDetailPenjualan[i].kuantiti}',
            width: 1,
            styles: PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: moneyFormat
                .format(int.parse('${listDetailPenjualan[i].hargaJual}')),
            width: 3,
            styles: PosStyles(align: PosAlign.left)),
        PosColumn(
            text: moneyFormat.format(
                int.parse('${listDetailPenjualan[i].kuantiti}') *
                    (int.parse('${listDetailPenjualan[i].hargaJual}'))),
            width: 3,
            styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL :',
          width: 8,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '${moneyFormat.format(widget.penjualan.nominalJual)}',
          width: 4,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'TUNAI :',
          width: 8,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '${moneyFormat.format(widget.penjualan.bayar)}',
          width: 4,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'KEMBALI :',
          width: 8,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '${moneyFormat.format(widget.penjualan.kembalian)}',
          width: 4,
          styles: PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.hr(ch: '=');

    bytes += generator.text('Terima Kasih',
        styles: PosStyles(align: PosAlign.center, bold: true), linesAfter: 1);

    bytes += generator.text(
        'BARANG YANG SUDAH DIBELI\nTIDAK BISA DIKEMBALIKAN.',
        styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.cut();
    return bytes;
  }

  Future<bool> backPress() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade, child: HistoryPenjualan()));
    return false;
  }

  requestBtPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
  }
}
