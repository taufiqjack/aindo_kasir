import 'dart:convert';

import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/menu.dart';
import 'package:aindo_kasir/layout/payment_details.dart';
import 'package:aindo_kasir/models/api.dart';
import 'package:aindo_kasir/models/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// late final int nomorTr;

class OrderPages extends StatefulWidget {
  // final Barang barangData;
  // final int item;

  OrderPages({Key? key}) : super(key: key);
  @override
  _OrderPagesState createState() => _OrderPagesState();
}

class _OrderPagesState extends State<OrderPages> {
  late String nominalBeli;
  final nomBelController = TextEditingController();
  final kembalianController = TextEditingController();
  String hasilText = '0';
  final f = new DateFormat('yyyyMMdd');

  final GlobalKey<FormState> formKey = GlobalKey();

  Future insertOrder() async {
    var data = {
      'IDTr': null,
      'NomorTr': f.format(DateTime.now()).toString() + '0000',
      'TanggalJual': DateTime.now().toString(),
      'Diskon': 0.0,
      'DiskonRp': 0,
      'IDUser': 1,
      'NominalJual': int.parse(jumlahHarga.toString()),
      'NominalBeli': int.parse(totalHargaBeli.toString()),
      'Bayar': int.parse(nomBelController.text),
      'Kembalian': int.parse(hasilText),
      'Sinkron': 0
    };

    return SQFliteBarang.sql.insertPenjualan(Penjualan.fromJson(data));
  }

  Future insertOrderPenjualanDetail(PenjualanDetail penjualanDetail) async {
    var data = {
      'IDTr': penjualanDetail.iDTr,
      'IDBarang': penjualanDetail.iDBarang,
      'Kuantiti': penjualanDetail.kuantiti,
      'HargaJual': penjualanDetail.hargaJual,
      'HargaBeli': penjualanDetail.hargaBeli,
      'DiskonSatuan': penjualanDetail.diskonSatuan,
    };

    return SQFliteBarang.sql
        .insertPenjualanDetail(PenjualanDetail.fromJson(data));
    // ignore: dead_code
    print('menambah $data');
  }

  Map<dynamic, dynamic> savedlistOrder = Map<dynamic, dynamic>();
  List<Map<dynamic, dynamic>> listSaveOrder = [];
  int? jumlahHarga;
  int? newJumlahHarga;
  int? totalHargaBeli;
  int? jumlahHargaScan;
  // int totalHargaBeli = 0;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cart = prefs.getStringList('cart')!;

    final cartJumlahHarga = prefs.getInt('jumlahHarga');
    final cartHargaScan = prefs.getInt('jumlahHargaScan');
    final cartJumlahHargaBeli = prefs.getInt('jumlahHargaBeli');
    setState(() {
      cart.forEach((item) {
        listSaveOrder.add(jsonDecode(item));
      });
    });
    setState(() {
      jumlahHarga = cartJumlahHarga;
      totalHargaBeli = cartJumlahHargaBeli;
      jumlahHargaScan = cartHargaScan;

      print('jumlah hargaJual : $jumlahHarga');
      print('jumlah hargaBeli: $totalHargaBeli');
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
        title: Text('Order'),
        leading: InkWell(
          child: Icon(Icons.arrow_back_sharp),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.getKeys();
            for (String key in prefs.getKeys()) {
              if (key != 'success') {
                prefs.remove(key);
              }
            }
            Navigator.push(
                context,
                PageTransition(
                    type: PageTransitionType.fade, child: MenuKasir()));
          },
        ),
      ),
      body: ListView.builder(
          itemCount: listSaveOrder.length,
          itemBuilder: (BuildContext context, int index) {
            final barangData = listSaveOrder[index];
            return SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    leading: Image.network(
                      "${BaseUrl.pathImage}/${barangData['Gambar']}",
                    ),
                    title: Text(
                      '${barangData['Nama']}',
                      style: TextStyle(color: Colors.indigo.shade600),
                    ),
                    subtitle: Text(
                      '${barangData['quantity']} ' +
                          'x ' +
                          rupiah('${barangData['hargaJual']}'),
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.fill,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            rupiah(
                              int.parse('${barangData['quantity']}') *
                                  int.parse(barangData['hargaJual']),
                            ),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          TextButton(
                              onPressed: () async {
                                var total = jumlahHargaScan;
                                var totalBeli = totalHargaBeli;
                                var hargaList =
                                    int.parse('${barangData['quantity']}') *
                                        int.parse(barangData['hargaJual']);
                                var hargaBeliList =
                                    int.parse('${barangData['quantity']}') *
                                        int.parse(barangData['hargaBeli']);

                                setState(() {
                                  listSaveOrder.removeAt(index);
                                  jumlahHargaScan = 0;
                                  jumlahHargaScan =
                                      (int.parse(total.toString())) - hargaList;
                                  totalHargaBeli = 0;
                                  totalHargaBeli =
                                      (int.parse(totalBeli.toString())) -
                                          hargaBeliList;

                                  print(
                                      'hasil : ${jumlahHargaScan.toString()}');
                                });
                              },
                              child: Text('Batal'),
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.redAccent),
                                  fixedSize:
                                      MaterialStateProperty.all(Size(5, 5)))),
                        ],
                      ),
                    ),
                  ),
                  Padding(padding: EdgeInsets.only(top: 10)),
                  Divider(
                    thickness: 2,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                  ),
                ],
              ),
            );
          }),
      bottomNavigationBar: Container(
        height: 120,
        width: 50,
        color: Colors.grey.shade300,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Total",
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 75),
                  ),
                  Text(
                    rupiah(jumlahHargaScan.toString()),
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: [
                  btnBayar(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget btnBayar(BuildContext context) {
    if (jumlahHargaScan != 0) {
      return Center(
        child: TextButton(
          onPressed: () async {
            for (int i = 0; i < listSaveOrder.length; i++) {
              var barangData = listSaveOrder[i];
              savedlistOrder['idBarang'] = barangData['idBarang'];
              savedlistOrder['Gambar'] = barangData['Gambar'];
              savedlistOrder['Nama'] = barangData['Nama'];
              savedlistOrder['hargaJual'] = barangData['hargaJual'];
              savedlistOrder['hargaBeli'] = barangData['hargaBeli'];
              savedlistOrder['quantity'] = barangData['quantity'];
              SharedPreferences prefs = await SharedPreferences.getInstance();
              List<String>? newCart = prefs.getStringList('newCart');
              String? cartJumlahHarga = prefs.getString('newJumlahHarga');
              String? cartJumlahHargaBeli =
                  prefs.getString('newJumlahHargaBeli');
              cartJumlahHarga = jumlahHargaScan.toString();
              cartJumlahHargaBeli = totalHargaBeli.toString();
              if (newCart == null) newCart = [];
              newCart.add(jsonEncode(savedlistOrder));
              prefs.setStringList('newCart', newCart);
              prefs.setString('newJumlahHarga', cartJumlahHarga);
              prefs.setString('newJumlahHargaBeli', cartJumlahHargaBeli);
            }
            // insertOrder();
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(builder: (context, setState) {
                    return AlertDialog(
                      actions: [
                        Form(
                            key: formKey,
                            child: Column(
                              children: [
                                Text(
                                  'Total Bayar : ' + rupiah(jumlahHargaScan),
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Padding(padding: EdgeInsets.only(top: 20)),
                                TextFormField(
                                  controller: nomBelController,
                                  decoration: new InputDecoration(
                                    labelText: "Nominal Bayar",
                                    labelStyle: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    hintText: '0',
                                    fillColor: Colors.white,
                                    border: new OutlineInputBorder(
                                      borderRadius:
                                          new BorderRadius.circular(8.0),
                                      borderSide: new BorderSide(
                                          color: Colors.blue.shade800),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) => setState(() {
                                    int result = int.parse(
                                            nomBelController.text) -
                                        (int.parse(jumlahHargaScan.toString()));
                                    hasilText = result.toString();
                                  }),
                                  validator: (value) {
                                    if (value.toString() == '0' ||
                                        value.toString() == '00' ||
                                        value.toString().isEmpty) {
                                      return 'nominal bayar harus diisi dan tidak boleh 0!';
                                    }
                                    return null;
                                  },
                                ),
                                Padding(padding: EdgeInsets.only(top: 20)),
                                Text('Kembalian'),
                                SizedBox(
                                  height: 5,
                                ),
                                TextFormField(
                                  decoration: new InputDecoration(
                                    enabled: false,
                                    labelText: '${rupiah(hasilText)}',
                                    labelStyle: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.bold),
                                    fillColor: Colors.white,
                                    border: new OutlineInputBorder(
                                      borderRadius:
                                          new BorderRadius.circular(8.0),
                                      borderSide: new BorderSide(
                                          color: Colors.blue.shade800),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  // controller: ,
                                ),
                                Padding(padding: EdgeInsets.only(top: 15)),
                                Center(
                                  child: TextButton(
                                    child: Text('Proses'),
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20))),
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                                Colors.white),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.indigo.shade700),
                                        fixedSize: MaterialStateProperty.all(
                                            Size(150, 40))),
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        insertOrder();
                                        for (int i = 0;
                                            i < listSaveOrder.length;
                                            i++) {
                                          PenjualanDetail penjualanDetail =
                                              new PenjualanDetail(
                                            iDTr: null,
                                            iDBarang: listSaveOrder[i]
                                                ['idBarang'],
                                            kuantiti: int.parse(
                                                listSaveOrder[i]['quantity']),
                                            hargaJual: int.parse(
                                                listSaveOrder[i]['hargaJual']),
                                            hargaBeli: int.parse(
                                                listSaveOrder[i]['hargaBeli']),
                                            diskonSatuan: 0,
                                          );

                                          SharedPreferences prefs =
                                              await SharedPreferences
                                                  .getInstance();
                                          int? tunai = prefs.getInt('tunai');
                                          tunai =
                                              int.parse(nomBelController.text);
                                          prefs.setInt('tunai', tunai);
                                          int? kembali = prefs.getInt('tunai');
                                          kembali = int.parse(hasilText);
                                          prefs.setInt('kembali', kembali);

                                          insertOrderPenjualanDetail(
                                              penjualanDetail);
                                        }

                                        Future.delayed(Duration(seconds: 3),
                                            () async {
                                          Navigator.push(
                                              context,
                                              PageTransition(
                                                  type: PageTransitionType.fade,
                                                  child: PaymentDetails()));
                                          nomBelController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )),
                      ],
                    );
                  });
                });
          },
          child: Text('Bayar'),
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            backgroundColor: MaterialStateProperty.all(Colors.indigo.shade900),
            fixedSize: MaterialStateProperty.all(
              Size(
                330,
                50,
              ),
            ),
          ),
        ),
      );
    } else {
      return Center(
          child: TextButton(
              child: Text('Kembali ke Menu'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.getKeys();
                for (String key in prefs.getKeys()) {
                  if (key != 'success') {
                    prefs.remove(key);
                  }
                }
                Navigator.push(
                    context,
                    PageTransition(
                        type: PageTransitionType.fade, child: MenuKasir()));
              },
              style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  backgroundColor:
                      MaterialStateProperty.all(Colors.indigo.shade900),
                  fixedSize: MaterialStateProperty.all(
                    Size(
                      330,
                      50,
                    ),
                  ))));
    }
  }

  @override
  void dispose() {
    nomBelController.dispose();
    super.dispose();
  }
}
