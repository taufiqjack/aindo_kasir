import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/menu.dart';
import 'package:aindo_kasir/layout/payment_details.dart';
import 'package:aindo_kasir/models/barang.dart';
import 'package:aindo_kasir/models/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';

// late final int nomorTr;

class OrderPages extends StatefulWidget {
  final Barang barangData;
  final int item;
  OrderPages({required this.barangData, required this.item});

  @override
  _OrderPagesState createState() => _OrderPagesState();
}

class _OrderPagesState extends State<OrderPages> {
  late String nominalBeli;
  final nomBelController = TextEditingController();
  final kembalianController = TextEditingController();
  String hasilText = '0';

  final GlobalKey<FormState> formKey = GlobalKey();

  Future insertOrder() async {
    var data = {
      'IDTr': null,
      'NomorTr': 'FI00',
      'TanggalJual': DateTime.now().toString(),
      'Diskon': 0.0,
      'DiskonRp': 0,
      'IDUser': 1,
      'NominalJual': widget.item * int.parse(widget.barangData.hargaJual),
      'NominalBeli': widget.item * int.parse(widget.barangData.hargaBeli),
      'Bayar': int.parse(nomBelController.text),
      'Kembalian': int.parse(hasilText),
      'Sinkron': 1
    };

    return SQFliteBarang.sql.insertPenjualan(Penjualan.fromJson(data));
    // ignore: dead_code
    print('menambah $data');
  }

  Future insertOrderPenjualanDetail() async {
    var data = {
      'IDTr': null,
      'IDBarang': widget.barangData.iDBarang,
      'Kuantiti': widget.item,
      'HargaJual': int.parse(widget.barangData.hargaJual),
      'HargaBeli': int.parse(widget.barangData.hargaBeli),
      'DiskonSatuan': 0,
    };

    return SQFliteBarang.sql
        .insertPenjualanDetail(PenjualanDetail.fromJson(data));
    // ignore: dead_code
    print('menambah $data');
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
          onTap: () {
            Navigator.push(
                context,
                PageTransition(
                    type: PageTransitionType.fade,
                    child: MenuKasir(
                      list: [],
                    )));
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  leading: Image.asset(
                    "assets/images/${widget.barangData.gambar}",
                  ),
                  title: Text(
                    widget.barangData.nama,
                    style: TextStyle(color: Colors.indigo.shade600),
                  ),
                  subtitle: Text(
                    '${widget.item} ' +
                        'x ' +
                        rupiah(widget.barangData.hargaJual),
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    rupiah(
                        widget.item * int.parse(widget.barangData.hargaJual)),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {},
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
          )
        ],
      ),
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
                    rupiah(
                        widget.item * int.parse(widget.barangData.hargaJual)),
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: TextButton(
                  onPressed: () {
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
                                          'Total Bayar : ${rupiah(widget.item * int.parse(widget.barangData.hargaJual))}',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(top: 20)),
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
                                                  new BorderRadius.circular(
                                                      8.0),
                                              borderSide: new BorderSide(
                                                  color: Colors.blue.shade800),
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                          onChanged: (value) => setState(() {
                                            int result = int.parse(
                                                    nomBelController.text) -
                                                (widget.item *
                                                    int.parse(widget
                                                        .barangData.hargaJual));
                                            hasilText = result.toString();
                                          }),
                                          validator: (value) {
                                            if (value.toString().isEmpty) {
                                              return 'nominal bayar harus diisi!';
                                            }
                                            return null;
                                          },
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(top: 20)),
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
                                                  new BorderRadius.circular(
                                                      8.0),
                                              borderSide: new BorderSide(
                                                  color: Colors.blue.shade800),
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          // controller: ,
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(top: 15)),
                                        Center(
                                          child: TextButton(
                                            child: Text('Proses'),
                                            style: ButtonStyle(
                                                shape: MaterialStateProperty
                                                    .all(RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20))),
                                                foregroundColor:
                                                    MaterialStateProperty.all(
                                                        Colors.white),
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                        Colors.indigo.shade700),
                                                fixedSize:
                                                    MaterialStateProperty.all(
                                                        Size(150, 40))),
                                            onPressed: () async {
                                              if (formKey.currentState!
                                                  .validate()) {
                                                insertOrder();
                                                insertOrderPenjualanDetail();

                                                Future.delayed(
                                                    Duration(seconds: 3),
                                                    () async {
                                                  Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          type:
                                                              PageTransitionType
                                                                  .fade,
                                                          child: PaymentDetails(
                                                            dataPenjualan:
                                                                widget
                                                                    .barangData,
                                                            itemCount:
                                                                widget.item,
                                                          )));
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
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.indigo.shade900),
                      fixedSize: MaterialStateProperty.all(Size(330, 50)))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomBelController.dispose();
    super.dispose();
  }
}
