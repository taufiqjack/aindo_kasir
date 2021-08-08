import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'dart:ui';
import 'package:aindo_kasir/controller/internet.dart';
import 'package:aindo_kasir/controller/syncToAPI.dart';
import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/login.dart';
import 'package:aindo_kasir/layout/orderpages.dart';
import 'package:aindo_kasir/main.dart';
import 'package:aindo_kasir/models/api.dart';
import 'package:aindo_kasir/models/barang.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';
import 'package:aindo_kasir/controller/syncToLocal.dart';
import 'package:animated_search_bar/animated_search_bar.dart';

class MenuKasir extends StatefulWidget {
  MenuKasir({Key? key}) : super(key: key);

  @override
  _MenuKasirState createState() => _MenuKasirState();
}

class _MenuKasirState extends State<MenuKasir> {
  late List list;

  List<int> _itemCount = [];
  List<int> _itemCountBeli = [];
  String searchText = "";
  int itemIndex = 0;
  int itemIndexBeli = 0;
  int jumlahHarga = 0;
  int jumlahHargaBeli = 0;
  int jumlahHargaScan = 0;

  bool isAsync = false;
  bool isLoading = false;

  Future getSQLiteBarang() async {
    setState(() {
      isLoading = true;
    });
    Future.delayed(Duration(seconds: 2), () {
      SQFliteBarang.sql.getBarang();
    });
  }

  Timer? timer;
  late double progress;

  void load() {
    setState(() {
      isAsync = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      getSQLiteBarang();
      getSQLiteJenisBarang();
      isLoading = false;
    });
  }

  Future getSQLiteJenisBarang() async {
    setState(() {
      isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      SQFliteBarang.sql.getJenisBarang();
      SQFliteBarang.sql.getBarangFromJenis();
      SQFliteBarang.sql.getBarangFromJenis3();
      SQFliteBarang.sql.getBarangFromJenis4();
    });
  }

  Future loadFromAPI() async {
    setState(() {
      var apiProvider = SyncToLocal();
      apiProvider.getAllBarangtoLocal();
      SQFliteBarang.sql.getBarang();
      SQFliteBarang.sql.getBarangFromJenis();
    });

    print(SQFliteBarang.sql.getBarang.toString());
  }

  Future loadFromJenisBarangAPI() async {
    setState(() {
      var apiProvider = SyncToLocal();
      apiProvider.getAllJenisBarangtoLocal();
      SQFliteBarang.sql.getJenisBarang();
    });

    print(SQFliteBarang.sql.getJenisBarang().toString());
  }

  List<Barang> listBarang = [];
  Map<dynamic, dynamic> savedlistOrder = Map<dynamic, dynamic>();

  List itemList = itemsNotifier.value;

  List<int> jumlahHargaItem = [];
  List<int> jumlahHargaBeliItem = [];
  List<int> jumlahHargaScanItem = [];

  String? harga;
  String? message;

  getStatusSync() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final psn = prefs.getString('message');

    setState(() {
      message = psn;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      SQFliteBarang.sql.getBarang();
      getSQLiteBarang();
    });
    getStatusSync();
    clearLoadOrder();
    getImagesNet();
  }

  clearLoadOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getKeys();
    for (String key in prefs.getKeys()) {
      if (key != 'success') {
        prefs.remove(key);
      }
    }
  }

  var searchbarcontroller = TextEditingController();

  List<Barang> cartList = <Barang>[];

  getImagesNet() async {
    final ByteData imageData = await NetworkAssetBundle(
            Uri.parse('${BaseUrl.pathImage}/default-item.jpg'))
        .load("");
    bytes = imageData.buffer.asUint8List();
  }

  Uint8List? bytes;

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
        title: Text('Menu'),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(
              vertical: 5,
            ),
            width: 200.0,
            height: 0,
            child: AnimatedSearchBar(
              searchDecoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  suffixStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari',
                  hintStyle: TextStyle(color: Colors.grey),
                  alignLabelWithHint: true,
                  enabledBorder: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: BorderSide(color: Colors.white, width: 2.0))),
              onChanged: (value) {
                setState(
                  () {
                    searchText = value;
                  },
                );
              },
            ),
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/barcode.jpg',
              height: 20,
              width: 20,
            ),
            onPressed: () {
              scanBarcodeNormal();
            },
          ),
        ],
      ),
      drawer: SafeArea(
        child: Drawer(
          child: ModalProgressHUD(
            inAsyncCall: isAsync,
            progressIndicator: CircularProgressIndicator(),
            opacity: 0.7,
            child: Column(
              children: [
                Flexible(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: Icon(Icons.sync),
                        title: Text("Sinkronkan Data"),
                        onTap: () {
                          ConnectInternet.isInternet().then((connection) {
                            if (connection) {
                              setState(() {
                                isLoading = false;
                              });
                              syncPenjualanDetail();

                              Future.delayed(Duration(seconds: 3), () {
                                syncPenjualan();

                                isLoading = true;
                                Navigator.pop(context);
                                syncAlert();
                              });
                              print("Koneksi Internet Tersedia");
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Icon(
                                          Icons.warning,
                                          color: Colors.red,
                                          size: 30,
                                        ),
                                        content: Text(
                                          "Tidak ada koneksi Internet!\nSilahkan Hidupkan Koneksi Anda",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        actions: [
                                          Center(
                                            child: TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text('OK'),
                                                style: ButtonStyle(
                                                    shape: MaterialStateProperty.all(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20))),
                                                    foregroundColor:
                                                        MaterialStateProperty
                                                            .all(Colors.white),
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .all(Colors.grey),
                                                    fixedSize:
                                                        MaterialStateProperty.all(
                                                            Size(150, 40)))),
                                          ),
                                        ]);
                                  });
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  child: Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: Container(
                      child: Column(
                        children: [
                          Divider(
                            thickness: 2,
                          ),
                          ListTile(
                            leading: Icon(Icons.logout),
                            title: Text("Logout"),
                            onTap: () {
                              setState(() {
                                isLoading = true;
                              });

                              Future.delayed(Duration(seconds: 3), () async {
                                logout();
                                isLoading = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: WillPopScope(
        onWillPop: exitApp,
        child: ModalProgressHUD(
          inAsyncCall: isAsync = false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: FutureBuilder(
              future: SQFliteBarang.sql.getJenisBarang(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  List<Tab> tabs = <Tab>[];

                  for (int i = 0; i < snapshot.data.length; i++) {
                    tabs.add(Tab(
                      child: Text(
                        snapshot.data[i].nama,
                        style: TextStyle(color: Colors.black),
                      ),
                    ));
                  }

                  return DefaultTabController(
                    length: snapshot.data.length,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Stack(
                          children: [
                            TabBar(
                              labelPadding:
                                  EdgeInsets.symmetric(horizontal: 20.0),
                              labelColor: Colors.black,
                              isScrollable: true,
                              tabs: tabs,
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                height: 600,
                                decoration: BoxDecoration(
                                    border: Border(
                                        top: BorderSide(
                                            color: Colors.white, width: 0.5))),
                                child: Stack(
                                  children: [
                                    TabBarView(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              child: Stack(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(10),
                                                    child: FutureBuilder(
                                                      future: SQFliteBarang.sql
                                                          .getBarang(),
                                                      builder:
                                                          (BuildContext context,
                                                              AsyncSnapshot
                                                                  snapshot) {
                                                        return snapshot.hasData
                                                            ? ListView.builder(
                                                                itemCount:
                                                                    snapshot
                                                                        .data
                                                                        .length,
                                                                itemBuilder:
                                                                    (BuildContext
                                                                            context,
                                                                        int
                                                                            index) {
                                                                  final x = snapshot
                                                                          .data[
                                                                      index];
                                                                  if (searchText
                                                                      .isEmpty) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }

                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                              leading: ClipRRect(
                                                                                borderRadius: BorderRadius.circular(5.0),
                                                                                child: Image.network(
                                                                                  "${BaseUrl.pathImage}/${x.gambar}",
                                                                                  //   Image.memory(
                                                                                  // bytes!,
                                                                                  // width: 100.0,
                                                                                  // height: 60.0,
                                                                                  // ),
                                                                                  height: 100,
                                                                                  width: 60,
                                                                                ),
                                                                              ),
                                                                              title: Text(
                                                                                // "",
                                                                                '${x.nama}',
                                                                                style: TextStyle(color: Colors.indigo.shade600),
                                                                              ),
                                                                              trailing: Text(
                                                                                "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                              ),
                                                                              onTap: () {
                                                                                showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                      return StatefulBuilder(builder: (context, setState) {
                                                                                        return AlertDialog(
                                                                                          content: ListTile(
                                                                                            isThreeLine: true,
                                                                                            leading: Image.network(
                                                                                              "${BaseUrl.pathImage}/${x.gambar}",
                                                                                            ),
                                                                                            title: Text(
                                                                                              '${x.nama}',
                                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                                            ),
                                                                                            subtitle: Text(
                                                                                              rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                              style: TextStyle(fontWeight: FontWeight.bold),
                                                                                            ),
                                                                                          ),
                                                                                          actions: [
                                                                                            Column(
                                                                                              children: [
                                                                                                Container(
                                                                                                  child: Row(
                                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                                    children: [
                                                                                                      Card(
                                                                                                        child: Container(
                                                                                                          height: 50,
                                                                                                          width: 120,
                                                                                                          child: Row(
                                                                                                            children: [
                                                                                                              Container(
                                                                                                                alignment: Alignment.center,
                                                                                                                child: Row(
                                                                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                  children: [
                                                                                                                    Padding(
                                                                                                                      padding: EdgeInsets.only(right: 5),
                                                                                                                    ),
                                                                                                                    _itemCount[index] != 0 && _itemCountBeli[index] != 0
                                                                                                                        ? new IconButton(
                                                                                                                            icon: Icon(Icons.remove),
                                                                                                                            onPressed: () async {
                                                                                                                              setState(() {
                                                                                                                                _itemCount[index]--;
                                                                                                                                _itemCountBeli[index]--;
                                                                                                                                itemIndex--;
                                                                                                                                jumlahHargaItem[index] = int.parse(x.hargaJual) * _itemCount[index];
                                                                                                                                jumlahHargaBeliItem[index] = int.parse(x.hargaBeli) * _itemCountBeli[index];
                                                                                                                                print(jumlahHargaItem[index]);
                                                                                                                                print(jumlahHargaBeliItem[index]);
                                                                                                                              });
                                                                                                                            })
                                                                                                                        : IconButton(
                                                                                                                            icon: Icon(Icons.remove),
                                                                                                                            onPressed: null,
                                                                                                                          ),
                                                                                                                    new Text(
                                                                                                                      _itemCount[index].toString(),
                                                                                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                    ),
                                                                                                                    new IconButton(
                                                                                                                        icon: Icon(Icons.add),
                                                                                                                        onPressed: () async {
                                                                                                                          setState(() {
                                                                                                                            _itemCount[index]++;
                                                                                                                            _itemCountBeli[index]++;
                                                                                                                            itemIndex++;
                                                                                                                            jumlahHargaItem[index] = int.parse(x.hargaJual) * _itemCount[index];
                                                                                                                            jumlahHargaBeliItem[index] = int.parse(x.hargaBeli) * _itemCountBeli[index];
                                                                                                                            print(jumlahHargaItem[index]);
                                                                                                                            print(jumlahHargaBeliItem[index]);
                                                                                                                          });
                                                                                                                        }),
                                                                                                                  ],
                                                                                                                ),
                                                                                                              )
                                                                                                            ],
                                                                                                          ),
                                                                                                        ),
                                                                                                      )
                                                                                                    ],
                                                                                                  ),
                                                                                                ),
                                                                                                Padding(padding: EdgeInsets.only(top: 10)),
                                                                                                ButtonBar(
                                                                                                  alignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    btnTambah(context, snapshot.data[index], index),
                                                                                                  ],
                                                                                                ),
                                                                                              ],
                                                                                            )
                                                                                          ],
                                                                                        );
                                                                                      });
                                                                                    });
                                                                              }),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else if (x
                                                                      .nama
                                                                      .toString()
                                                                      .toLowerCase()
                                                                      .contains(
                                                                          searchText
                                                                              .toLowerCase())) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }
                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                            leading:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                              child: Image.network(
                                                                                "${BaseUrl.pathImage}/${x.gambar}",
                                                                                height: 100,
                                                                                width: 60,
                                                                              ),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              // "",
                                                                              '${x.nama}',
                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                            ),
                                                                            trailing:
                                                                                Text(
                                                                              "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(builder: (context, setState) {
                                                                                      return AlertDialog(
                                                                                        content: ListTile(
                                                                                          isThreeLine: true,
                                                                                          leading: Image.network(
                                                                                            "${BaseUrl.pathImage}/${x.gambar}",
                                                                                          ),
                                                                                          title: Text(
                                                                                            '${x.nama}',
                                                                                            style: TextStyle(color: Colors.indigo.shade600),
                                                                                          ),
                                                                                          subtitle: Text(
                                                                                            rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        actions: [
                                                                                          Column(
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    Card(
                                                                                                      child: Container(
                                                                                                        height: 50,
                                                                                                        width: 120,
                                                                                                        child: Row(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              alignment: Alignment.center,
                                                                                                              child: Row(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                children: [
                                                                                                                  Padding(
                                                                                                                    padding: EdgeInsets.only(right: 5),
                                                                                                                  ),
                                                                                                                  _itemCount[index] != 0
                                                                                                                      ? new IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: () async {
                                                                                                                            setState(() {
                                                                                                                              _itemCount[index]--;
                                                                                                                              _itemCountBeli[index]--;

                                                                                                                              itemIndex--;
                                                                                                                              jumlahHargaItem[index] = int.parse(x.hargaJual) * _itemCount[index];
                                                                                                                              jumlahHargaBeliItem[index] = int.parse(x.hargaBeli) * _itemCountBeli[index];
                                                                                                                            });
                                                                                                                          })
                                                                                                                      : IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: null,
                                                                                                                        ),
                                                                                                                  new Text(
                                                                                                                    _itemCount[index].toString(),
                                                                                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                  ),
                                                                                                                  new IconButton(
                                                                                                                      icon: Icon(Icons.add),
                                                                                                                      onPressed: () async {
                                                                                                                        setState(() {
                                                                                                                          _itemCount[index]++;
                                                                                                                          _itemCountBeli[index]++;

                                                                                                                          itemIndex++;
                                                                                                                          jumlahHargaItem[index] = int.parse(x.hargaJual) * _itemCount[index];
                                                                                                                          jumlahHargaBeliItem[index] = int.parse(x.hargaBeli) * _itemCountBeli[index];
                                                                                                                        });
                                                                                                                      }),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Padding(padding: EdgeInsets.only(top: 10)),
                                                                                              ButtonBar(
                                                                                                alignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  btnTambah(context, snapshot.data[index], index),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          )
                                                                                        ],
                                                                                      );
                                                                                    });
                                                                                  });
                                                                            },
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    return Container();
                                                                  }
                                                                })
                                                            : Center(
                                                                child:
                                                                    CircularProgressIndicator());
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              child: Stack(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(10),
                                                    child: FutureBuilder(
                                                      future: SQFliteBarang.sql
                                                          .getBarangFromJenis(),
                                                      builder:
                                                          (BuildContext context,
                                                              AsyncSnapshot
                                                                  snapshot) {
                                                        return snapshot.hasData
                                                            ? ListView.builder(
                                                                itemCount:
                                                                    snapshot
                                                                        .data
                                                                        .length,
                                                                itemBuilder:
                                                                    (BuildContext
                                                                            context,
                                                                        index) {
                                                                  final x = snapshot
                                                                          .data[
                                                                      index];
                                                                  if (searchText
                                                                      .isEmpty) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }
                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                            leading:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                              child: Image.network(
                                                                                "${BaseUrl.pathImage}/${x.gambar}",
                                                                                height: 100,
                                                                                width: 60,
                                                                              ),
                                                                            ),
                                                                            title: Text(
                                                                                // "",
                                                                                '${x.nama}',
                                                                                style: TextStyle(
                                                                                  color: Colors.indigo.shade600,
                                                                                  fontSize: 14,
                                                                                )),
                                                                            trailing:
                                                                                Text(
                                                                              "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(builder: (context, setState) {
                                                                                      return AlertDialog(
                                                                                        content: ListTile(
                                                                                          isThreeLine: true,
                                                                                          leading: Image.network(
                                                                                            "${BaseUrl.pathImage}/${x.gambar}",
                                                                                          ),
                                                                                          title: Text(
                                                                                            '${x.nama}',
                                                                                            style: TextStyle(color: Colors.indigo.shade600),
                                                                                          ),
                                                                                          subtitle: Text(
                                                                                            rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        actions: [
                                                                                          Column(
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    Card(
                                                                                                      child: Container(
                                                                                                        height: 50,
                                                                                                        width: 120,
                                                                                                        child: Row(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              alignment: Alignment.center,
                                                                                                              child: Row(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                children: [
                                                                                                                  Padding(
                                                                                                                    padding: EdgeInsets.only(right: 5),
                                                                                                                  ),
                                                                                                                  _itemCount[_itemCount.length - 1] != 0
                                                                                                                      ? new IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: () {
                                                                                                                            setState(() {
                                                                                                                              _itemCount[_itemCount.length - 1]--;
                                                                                                                              _itemCountBeli[_itemCount.length - 1]--;

                                                                                                                              itemIndex--;
                                                                                                                              jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                              jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                            });
                                                                                                                          })
                                                                                                                      : IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: null,
                                                                                                                        ),
                                                                                                                  new Text(
                                                                                                                    _itemCount[_itemCount.length - 1].toString(),
                                                                                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                  ),
                                                                                                                  new IconButton(
                                                                                                                      icon: Icon(Icons.add),
                                                                                                                      onPressed: () async {
                                                                                                                        setState(() {
                                                                                                                          _itemCount[_itemCount.length - 1]++;
                                                                                                                          _itemCountBeli[_itemCount.length - 1]++;

                                                                                                                          itemIndex++;
                                                                                                                          jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                          jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                        });
                                                                                                                      }),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Padding(padding: EdgeInsets.only(top: 10)),
                                                                                              ButtonBar(
                                                                                                alignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  btnTambah(context, snapshot.data[index], _itemCount.length - 1),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    });
                                                                                  });
                                                                            },
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else if (x
                                                                      .nama
                                                                      .toString()
                                                                      .toLowerCase()
                                                                      .contains(
                                                                          searchText
                                                                              .toLowerCase())) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }
                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                            leading:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                              child: Image.network(
                                                                                "${BaseUrl.pathImage}/${x.gambar}",
                                                                                height: 100,
                                                                                width: 60,
                                                                              ),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              // "",
                                                                              '${x.nama}',
                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                            ),
                                                                            trailing:
                                                                                Text(
                                                                              "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(builder: (context, setState) {
                                                                                      return AlertDialog(
                                                                                        content: ListTile(
                                                                                          isThreeLine: true,
                                                                                          leading: Image.network(
                                                                                            "${BaseUrl.pathImage}/${x.gambar}",
                                                                                          ),
                                                                                          title: Text(
                                                                                            '${x.nama}',
                                                                                            style: TextStyle(color: Colors.indigo.shade600),
                                                                                          ),
                                                                                          subtitle: Text(
                                                                                            rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        actions: [
                                                                                          Column(
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    Card(
                                                                                                      child: Container(
                                                                                                        height: 50,
                                                                                                        width: 120,
                                                                                                        child: Row(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              alignment: Alignment.center,
                                                                                                              child: Row(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                children: [
                                                                                                                  Padding(
                                                                                                                    padding: EdgeInsets.only(right: 5),
                                                                                                                  ),
                                                                                                                  _itemCount[_itemCount.length - 1] != 0
                                                                                                                      ? new IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: () async {
                                                                                                                            setState(() {
                                                                                                                              _itemCount[_itemCount.length - 1]--;
                                                                                                                              _itemCountBeli[_itemCount.length - 1]--;
                                                                                                                              itemIndex--;
                                                                                                                              jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                              jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                            });
                                                                                                                          })
                                                                                                                      : IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: null,
                                                                                                                        ),
                                                                                                                  new Text(
                                                                                                                    _itemCount[_itemCount.length - 1].toString(),
                                                                                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                  ),
                                                                                                                  new IconButton(
                                                                                                                      icon: Icon(Icons.add),
                                                                                                                      onPressed: () async {
                                                                                                                        setState(() {
                                                                                                                          _itemCount[_itemCount.length - 1]++;
                                                                                                                          _itemCountBeli[_itemCount.length - 1]++;
                                                                                                                          itemIndex++;
                                                                                                                          jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                          jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                        });
                                                                                                                      }),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Padding(padding: EdgeInsets.only(top: 10)),
                                                                                              ButtonBar(
                                                                                                alignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  btnTambah(context, snapshot.data[index], _itemCount.length - 1),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          )
                                                                                        ],
                                                                                      );
                                                                                    });
                                                                                  });
                                                                            },
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    return Container();
                                                                  }
                                                                },
                                                              )
                                                            : Center(
                                                                child:
                                                                    CircularProgressIndicator());
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              child: Stack(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(10),
                                                    child: FutureBuilder(
                                                      future: SQFliteBarang.sql
                                                          .getBarangFromJenis3(),
                                                      builder:
                                                          (BuildContext context,
                                                              AsyncSnapshot
                                                                  snapshot) {
                                                        return snapshot.hasData
                                                            ? ListView.builder(
                                                                itemCount:
                                                                    snapshot
                                                                        .data
                                                                        .length,
                                                                itemBuilder:
                                                                    (BuildContext
                                                                            context,
                                                                        index) {
                                                                  final x = snapshot
                                                                          .data[
                                                                      index];
                                                                  if (searchText
                                                                      .isEmpty) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }
                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                            leading:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                              child: Image.network(
                                                                                "${BaseUrl.pathImage}/${x.gambar}",
                                                                                height: 100,
                                                                                width: 60,
                                                                              ),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              // "",
                                                                              '${x.nama}',
                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                            ),
                                                                            trailing:
                                                                                Text(
                                                                              "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(builder: (context, setState) {
                                                                                      return AlertDialog(
                                                                                        content: ListTile(
                                                                                          isThreeLine: true,
                                                                                          leading: Image.network(
                                                                                            "${BaseUrl.pathImage}/${x.gambar}",
                                                                                          ),
                                                                                          title: Text(
                                                                                            '${x.nama}',
                                                                                            style: TextStyle(color: Colors.indigo.shade600),
                                                                                          ),
                                                                                          subtitle: Text(
                                                                                            rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        actions: [
                                                                                          Column(
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    Card(
                                                                                                      child: Container(
                                                                                                        height: 50,
                                                                                                        width: 120,
                                                                                                        child: Row(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              alignment: Alignment.center,
                                                                                                              child: Row(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                children: [
                                                                                                                  Padding(
                                                                                                                    padding: EdgeInsets.only(right: 5),
                                                                                                                  ),
                                                                                                                  _itemCount[_itemCount.length - 1] != 0
                                                                                                                      ? new IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: () {
                                                                                                                            setState(() {
                                                                                                                              _itemCount[_itemCount.length - 1]--;
                                                                                                                              _itemCountBeli[_itemCount.length - 1]--;

                                                                                                                              itemIndex--;
                                                                                                                              jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                              jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                            });
                                                                                                                          })
                                                                                                                      : IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: null,
                                                                                                                        ),
                                                                                                                  new Text(
                                                                                                                    _itemCount[_itemCount.length - 1].toString(),
                                                                                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                  ),
                                                                                                                  new IconButton(
                                                                                                                      icon: Icon(Icons.add),
                                                                                                                      onPressed: () async {
                                                                                                                        setState(() {
                                                                                                                          _itemCount[_itemCount.length - 1]++;
                                                                                                                          _itemCountBeli[_itemCount.length - 1]++;

                                                                                                                          itemIndex++;
                                                                                                                          jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                          jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                        });
                                                                                                                      }),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Padding(padding: EdgeInsets.only(top: 10)),
                                                                                              ButtonBar(
                                                                                                alignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  btnTambah(context, snapshot.data[index], _itemCount.length - 1),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    });
                                                                                  });
                                                                            },
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else if (x
                                                                      .nama
                                                                      .toString()
                                                                      .toLowerCase()
                                                                      .contains(
                                                                          searchText
                                                                              .toLowerCase())) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }
                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                            leading:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                              child: Image.network(
                                                                                "${BaseUrl.pathImage}/${x.gambar}",
                                                                                height: 100,
                                                                                width: 60,
                                                                              ),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              // "",
                                                                              '${x.nama}',
                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                            ),
                                                                            trailing:
                                                                                Text(
                                                                              "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(builder: (context, setState) {
                                                                                      return AlertDialog(
                                                                                        content: ListTile(
                                                                                          isThreeLine: true,
                                                                                          leading: Image.network(
                                                                                            "${BaseUrl.pathImage}/${x.gambar}",
                                                                                          ),
                                                                                          title: Text(
                                                                                            '${x.nama}',
                                                                                            style: TextStyle(color: Colors.indigo.shade600),
                                                                                          ),
                                                                                          subtitle: Text(
                                                                                            rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        actions: [
                                                                                          Column(
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    Card(
                                                                                                      child: Container(
                                                                                                        height: 50,
                                                                                                        width: 120,
                                                                                                        child: Row(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              alignment: Alignment.center,
                                                                                                              child: Row(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                children: [
                                                                                                                  Padding(
                                                                                                                    padding: EdgeInsets.only(right: 5),
                                                                                                                  ),
                                                                                                                  _itemCount[_itemCount.length - 1] != 0
                                                                                                                      ? new IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: () async {
                                                                                                                            setState(() {
                                                                                                                              _itemCount[_itemCount.length - 1]--;
                                                                                                                              _itemCountBeli[_itemCount.length - 1]--;
                                                                                                                              itemIndex--;
                                                                                                                              jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                              jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                            });
                                                                                                                          })
                                                                                                                      : IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: null,
                                                                                                                        ),
                                                                                                                  new Text(
                                                                                                                    _itemCount[_itemCount.length - 1].toString(),
                                                                                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                  ),
                                                                                                                  new IconButton(
                                                                                                                      icon: Icon(Icons.add),
                                                                                                                      onPressed: () async {
                                                                                                                        setState(() {
                                                                                                                          _itemCount[_itemCount.length - 1]++;
                                                                                                                          _itemCountBeli[_itemCount.length - 1]++;
                                                                                                                          itemIndex++;
                                                                                                                          jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                          jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                        });
                                                                                                                      }),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Padding(padding: EdgeInsets.only(top: 10)),
                                                                                              ButtonBar(
                                                                                                alignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  btnTambah(context, snapshot.data[index], _itemCount.length - 1),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          )
                                                                                        ],
                                                                                      );
                                                                                    });
                                                                                  });
                                                                            },
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    return Container();
                                                                  }
                                                                },
                                                              )
                                                            : Center(
                                                                child:
                                                                    CircularProgressIndicator());
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              child: Stack(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(10),
                                                    child: FutureBuilder(
                                                      future: SQFliteBarang.sql
                                                          .getBarangFromJenis4(),
                                                      builder:
                                                          (BuildContext context,
                                                              AsyncSnapshot
                                                                  snapshot) {
                                                        return snapshot.hasData
                                                            ? ListView.builder(
                                                                itemCount:
                                                                    snapshot
                                                                        .data
                                                                        .length,
                                                                itemBuilder:
                                                                    (BuildContext
                                                                            context,
                                                                        index) {
                                                                  final x = snapshot
                                                                          .data[
                                                                      index];
                                                                  if (searchText
                                                                      .isEmpty) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }
                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                            leading:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                              child: Image.network(
                                                                                "${BaseUrl.pathImage}/${x.gambar}",
                                                                                height: 100,
                                                                                width: 60,
                                                                              ),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              // "",
                                                                              '${x.nama}',
                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                            ),
                                                                            trailing:
                                                                                Text(
                                                                              "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(builder: (context, setState) {
                                                                                      return AlertDialog(
                                                                                        content: ListTile(
                                                                                          isThreeLine: true,
                                                                                          leading: Image.network(
                                                                                            "${BaseUrl.pathImage}/${x.gambar}",
                                                                                          ),
                                                                                          title: Text(
                                                                                            '${x.nama}',
                                                                                            style: TextStyle(color: Colors.indigo.shade600),
                                                                                          ),
                                                                                          subtitle: Text(
                                                                                            rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        actions: [
                                                                                          Column(
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    Card(
                                                                                                      child: Container(
                                                                                                        height: 50,
                                                                                                        width: 120,
                                                                                                        child: Row(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              alignment: Alignment.center,
                                                                                                              child: Row(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                children: [
                                                                                                                  Padding(
                                                                                                                    padding: EdgeInsets.only(right: 5),
                                                                                                                  ),
                                                                                                                  _itemCount[_itemCount.length - 1] != 0
                                                                                                                      ? new IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: () {
                                                                                                                            setState(() {
                                                                                                                              _itemCount[_itemCount.length - 1]--;
                                                                                                                              _itemCountBeli[_itemCount.length - 1]--;

                                                                                                                              itemIndex--;
                                                                                                                              jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                              jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                            });
                                                                                                                          })
                                                                                                                      : IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: null,
                                                                                                                        ),
                                                                                                                  new Text(
                                                                                                                    _itemCount[_itemCount.length - 1].toString(),
                                                                                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                  ),
                                                                                                                  new IconButton(
                                                                                                                      icon: Icon(Icons.add),
                                                                                                                      onPressed: () async {
                                                                                                                        setState(() {
                                                                                                                          _itemCount[_itemCount.length - 1]++;
                                                                                                                          _itemCountBeli[_itemCount.length - 1]++;

                                                                                                                          itemIndex++;
                                                                                                                          jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                          jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                        });
                                                                                                                      }),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Padding(padding: EdgeInsets.only(top: 10)),
                                                                                              ButtonBar(
                                                                                                alignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  btnTambah(context, snapshot.data[index], _itemCount.length - 1),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    });
                                                                                  });
                                                                            },
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else if (x
                                                                      .nama
                                                                      .toString()
                                                                      .toLowerCase()
                                                                      .contains(
                                                                          searchText
                                                                              .toLowerCase())) {
                                                                    for (int i =
                                                                            0;
                                                                        i < snapshot.data.length;
                                                                        i++) {
                                                                      _itemCount
                                                                          .add(
                                                                              0);
                                                                      jumlahHargaItem
                                                                          .add(
                                                                              0);
                                                                      for (int i =
                                                                              0;
                                                                          i < snapshot.data.length;
                                                                          i++) {
                                                                        _itemCountBeli
                                                                            .add(0);
                                                                        jumlahHargaBeliItem
                                                                            .add(0);
                                                                      }
                                                                    }
                                                                    return SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          ListTile(
                                                                            leading:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(5.0),
                                                                              child: Image.network(
                                                                                "${BaseUrl.pathImage}/${x.gambar}",
                                                                                height: 100,
                                                                                width: 60,
                                                                              ),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              // "",
                                                                              '${x.nama}',
                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                            ),
                                                                            trailing:
                                                                                Text(
                                                                              "Harga : " + rupiah('${x.hargaJual}', trailing: '.00'),
                                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return StatefulBuilder(builder: (context, setState) {
                                                                                      return AlertDialog(
                                                                                        content: ListTile(
                                                                                          isThreeLine: true,
                                                                                          leading: Image.network(
                                                                                            "${BaseUrl.pathImage}/${x.gambar}",
                                                                                          ),
                                                                                          title: Text(
                                                                                            '${x.nama}',
                                                                                            style: TextStyle(color: Colors.indigo.shade600),
                                                                                          ),
                                                                                          subtitle: Text(
                                                                                            rupiah('${x.hargaJual}', trailing: '.00'),
                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        actions: [
                                                                                          Column(
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: [
                                                                                                    Card(
                                                                                                      child: Container(
                                                                                                        height: 50,
                                                                                                        width: 120,
                                                                                                        child: Row(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              alignment: Alignment.center,
                                                                                                              child: Row(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                children: [
                                                                                                                  Padding(
                                                                                                                    padding: EdgeInsets.only(right: 5),
                                                                                                                  ),
                                                                                                                  _itemCount[_itemCount.length - 1] != 0
                                                                                                                      ? new IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: () async {
                                                                                                                            setState(() {
                                                                                                                              _itemCount[_itemCount.length - 1]--;
                                                                                                                              _itemCountBeli[_itemCount.length - 1]--;
                                                                                                                              itemIndex--;
                                                                                                                              jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                              jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                            });
                                                                                                                          })
                                                                                                                      : IconButton(
                                                                                                                          icon: Icon(Icons.remove),
                                                                                                                          onPressed: null,
                                                                                                                        ),
                                                                                                                  new Text(
                                                                                                                    _itemCount[_itemCount.length - 1].toString(),
                                                                                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                  ),
                                                                                                                  new IconButton(
                                                                                                                      icon: Icon(Icons.add),
                                                                                                                      onPressed: () async {
                                                                                                                        setState(() {
                                                                                                                          _itemCount[_itemCount.length - 1]++;
                                                                                                                          _itemCountBeli[_itemCount.length - 1]++;
                                                                                                                          itemIndex++;
                                                                                                                          jumlahHargaItem[_itemCount.length - 1] = int.parse(x.hargaJual) * _itemCount[_itemCount.length - 1];
                                                                                                                          jumlahHargaBeliItem[_itemCount.length - 1] = int.parse(x.hargaBeli) * _itemCountBeli[_itemCount.length - 1];
                                                                                                                        });
                                                                                                                      }),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Padding(padding: EdgeInsets.only(top: 10)),
                                                                                              ButtonBar(
                                                                                                alignment: MainAxisAlignment.center,
                                                                                                children: [
                                                                                                  btnTambah(context, snapshot.data[index], _itemCount.length - 1),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          )
                                                                                        ],
                                                                                      );
                                                                                    });
                                                                                  });
                                                                            },
                                                                          ),
                                                                          Padding(
                                                                              padding: EdgeInsets.only(top: 10)),
                                                                          Divider(
                                                                            thickness:
                                                                                2,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    return Container();
                                                                  }
                                                                },
                                                              )
                                                            : Center(
                                                                child:
                                                                    CircularProgressIndicator());
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) print(snapshot.error.toString());
                return Scaffold(
                  body: Center(
                      child: Text(snapshot.hasError
                          ? snapshot.error.toString()
                          : "Loading...")),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: viewOrder(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<String> selectList = [];

  viewOrder(i) {
    setState(() {});
    if (itemIndex == 0) {
      return Container();
    } else {
      return FloatingActionButton.extended(
        onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setInt('jumlahHargaScan', jumlahHarga);

          Navigator.push(
              context,
              PageTransition(
                  type: PageTransitionType.fade, child: OrderPages()));
        },
        label: Text("View Order  " +
            "(${itemIndex.toString()})" +
            "  ${rupiah(jumlahHarga)}"),
        backgroundColor: Colors.indigo.shade900,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      );
    }
  }

  void logout() async {
    setState(() {
      isAsync = true;
    });
    Future.delayed(Duration(seconds: 3), () async {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      sharedPreferences.clear();
      Navigator.push(context,
          PageTransition(type: PageTransitionType.fade, child: LoginApps()));
    });
  }

  Future<bool> exitApp() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Keluar"),
          content: Text("Apa anda yakin ingin keluar dari aplikasi ini?"),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Tidak",
              ),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.black),
                textStyle: MaterialStateProperty.all(
                    TextStyle(fontWeight: FontWeight.bold)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Ya"),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.black),
                textStyle: MaterialStateProperty.all(
                    TextStyle(fontWeight: FontWeight.bold)),
              ),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
    return false;
  }

  int? barcodeBarang;
  String? scanBarcode;
  final scanBarcodeController = TextEditingController();
  String? barcodeScanRes;

  Future<void> scanBarcodeNormal() async {
    scanBarcode = scanBarcodeController.text;

    scanBarcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'Batal', true, ScanMode.BARCODE);

    print(' print : $scanBarcode');

    setState(() {
      SQFliteBarang.sql.getBarangScan(scanBarcode!).then((value) {
        value.forEach((data) {
          listBarang.add(Barang(
            iDBarang: data.iDBarang,
            kodeBarang: data.kodeBarang,
            nama: data.nama,
            jenis: data.jenis,
            hargaBeli: data.hargaBeli,
            hargaJual: data.hargaJual,
            gambar: data.gambar,
            satuan: data.satuan,
            statusAktif: data.statusAktif,
          ));
        });
      }).catchError((error) {
        print('message : $error');
      });
    });

    for (int i = 0; i < listBarang.length; i++) {
      _itemCount.add(0);
      jumlahHargaItem.add(0);
    }

    listBarang.clear();
    _itemCount.clear();

    Future.delayed(Duration(milliseconds: 500), () {
      getBarangByBarcode();
    });
  }

  getBarangByBarcode() {
    SQFliteBarang.sql.getBarangScan(scanBarcode!).then((value) {
      barcodeBarang = value.length;
      scanAlertDialog();
      print(value.length);
    });
  }

  scanAlertDialog() {
    _itemCount.add(0);
    jumlahHargaItem.add(0);
    _itemCountBeli.add(0);
    jumlahHargaBeliItem.add(0);
    scanBarcode != '-1' && barcodeBarang != 0 && scanBarcode != null
        ? showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(builder: (context, setState) {
                return AlertDialog(
                  content: ListTile(
                    isThreeLine: true,
                    leading: Image.network(
                      "${BaseUrl.pathImage}/${listBarang.first.gambar}",
                    ),
                    title: Text(
                      '${listBarang.first.nama}',
                      style: TextStyle(color: Colors.indigo.shade600),
                    ),
                    subtitle: Text(
                      rupiah('${listBarang.first.hargaJual}', trailing: '.00'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  actions: [
                    Column(
                      children: [
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Card(
                                child: Container(
                                  height: 50,
                                  width: 120,
                                  child: Row(
                                    children: [
                                      Container(
                                        alignment: Alignment.center,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 5),
                                            ),
                                            _itemCount[_itemCount.length - 1] !=
                                                    0
                                                ? new IconButton(
                                                    icon: Icon(Icons.remove),
                                                    onPressed: () async {
                                                      setState(() {
                                                        _itemCount[
                                                            _itemCount.length -
                                                                1]--;
                                                        _itemCountBeli[
                                                            _itemCount.length -
                                                                1]--;

                                                        itemIndex--;
                                                        jumlahHargaItem[_itemCount
                                                                .length -
                                                            1] = int.parse(
                                                                listBarang.first
                                                                    .hargaJual) *
                                                            _itemCount[_itemCount
                                                                    .length -
                                                                1];
                                                        jumlahHargaBeliItem[
                                                                _itemCount
                                                                        .length -
                                                                    1] =
                                                            int.parse(listBarang
                                                                    .first
                                                                    .hargaBeli) *
                                                                _itemCountBeli[
                                                                    _itemCount
                                                                            .length -
                                                                        1];

                                                        print(jumlahHargaItem[
                                                            _itemCount.length -
                                                                1]);
                                                      });
                                                    })
                                                : IconButton(
                                                    icon: Icon(Icons.remove),
                                                    onPressed: null,
                                                  ),
                                            new Text(
                                              _itemCount[_itemCount.length - 1]
                                                  .toString(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            new IconButton(
                                                icon: Icon(Icons.add),
                                                onPressed: () async {
                                                  setState(() {
                                                    _itemCount[
                                                        _itemCount.length -
                                                            1]++;
                                                    _itemCountBeli[
                                                        _itemCountBeli.length -
                                                            1]++;

                                                    itemIndex++;
                                                    jumlahHargaItem[
                                                            jumlahHargaItem
                                                                    .length -
                                                                1] =
                                                        int.parse(listBarang
                                                                .first
                                                                .hargaJual) *
                                                            _itemCount[_itemCount
                                                                    .length -
                                                                1];
                                                    jumlahHargaBeliItem[
                                                            jumlahHargaItem
                                                                    .length -
                                                                1] =
                                                        int.parse(listBarang
                                                                .first
                                                                .hargaBeli) *
                                                            _itemCountBeli[
                                                                _itemCountBeli
                                                                        .length -
                                                                    1];

                                                    print('jumlahHarga' +
                                                        jumlahHargaItem[
                                                                jumlahHargaItem
                                                                        .length -
                                                                    1]
                                                            .toString());
                                                  });
                                                }),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.only(top: 10)),
                        ButtonBar(
                          alignment: MainAxisAlignment.center,
                          children: [
                            btnScanTambah(context, listBarang.first,
                                _itemCount.length - 1),
                          ],
                        )
                      ],
                    ),
                  ],
                );
              });
            })
        : showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text(
                  'Tak ada Data!',
                  textAlign: TextAlign.center,
                ),
                actions: [],
              );
            });
  }

  Widget btnTambah(BuildContext context, x, int index) {
    if (_itemCount[index] != 0) {
      return Center(
          child: TextButton(
              child: Text('Tambah'),
              style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  backgroundColor:
                      MaterialStateProperty.all(Colors.indigo.shade700),
                  fixedSize: MaterialStateProperty.all(Size(150, 40))),
              onPressed: () async {
                jumlahHarga = 0;
                for (int i = 0; i < jumlahHargaItem.length; i++) {
                  jumlahHarga = jumlahHarga + jumlahHargaItem[i];
                }
                jumlahHargaBeli = 0;
                for (int i = 0; i < jumlahHargaBeliItem.length; i++) {
                  jumlahHargaBeli = jumlahHargaBeli + jumlahHargaBeliItem[i];
                }
                if (_itemCount[index] > 0) {
                  viewOrder(x);
                  savedlistOrder['idBarang'] = x.iDBarang;
                  savedlistOrder['Gambar'] = x.gambar;
                  savedlistOrder['Nama'] = x.nama;
                  savedlistOrder['hargaJual'] = x.hargaJual;
                  savedlistOrder['hargaBeli'] = x.hargaBeli;
                  savedlistOrder['quantity'] = _itemCount[index].toString();
                }

                SharedPreferences prefs = await SharedPreferences.getInstance();
                List<String>? cart = prefs.getStringList('cart');
                int? cartJumlahHarga = prefs.getInt('jumlahHarga');
                int? cartJumlahHargaBeli = prefs.getInt('jumlahHargaBeli');
                if (cart == null) cart = [];
                cart.add(jsonEncode(savedlistOrder));
                cartJumlahHarga = jumlahHarga.toInt();
                cartJumlahHargaBeli = jumlahHargaBeli.toInt();
                prefs.setStringList('cart', cart);
                prefs.setInt('jumlahHarga', cartJumlahHarga);
                prefs.setInt('jumlahHargaBeli', cartJumlahHargaBeli);

                Navigator.pop(context);
              }));
    } else {
      return Container();
    }
  }

  Widget btnScanTambah(BuildContext context, brng, int itemScan) {
    if (_itemCount[_itemCount.length - 1] != 0) {
      return Center(
        child: TextButton(
            onPressed: () async {
              jumlahHarga = 0;
              for (int i = 0; i < jumlahHargaItem.length; i++) {
                jumlahHarga = jumlahHarga + jumlahHargaItem[i];
              }
              jumlahHargaBeli = 0;
              for (int i = 0; i < jumlahHargaBeliItem.length; i++) {
                jumlahHargaBeli = jumlahHargaBeli + jumlahHargaBeliItem[i];
              }
              jumlahHargaScan = 0;
              for (int i = 0; i < jumlahHargaScanItem.length; i++) {
                jumlahHargaScan = jumlahHargaScan + jumlahHargaScanItem[i];
              }

              viewOrder(brng);
              savedlistOrder['idBarang'] = brng.iDBarang;
              savedlistOrder['Gambar'] = brng.gambar;
              savedlistOrder['Nama'] = brng.nama;
              savedlistOrder['hargaJual'] = brng.hargaJual;
              savedlistOrder['hargaBeli'] = brng.hargaBeli;
              savedlistOrder['quantity'] =
                  _itemCount[_itemCount.length - 1].toString();

              SharedPreferences prefs = await SharedPreferences.getInstance();
              List<String>? cart = prefs.getStringList('cart');
              int? cartJumlahHarga = prefs.getInt('jumlahHarga');
              int? cartJumlahHargaBeli = prefs.getInt('jumlahHargaBeli');
              if (cart == null) cart = [];
              cart.add(jsonEncode(savedlistOrder));
              cartJumlahHarga = jumlahHarga.toInt();
              cartJumlahHargaBeli = jumlahHargaBeli.toInt();
              prefs.setStringList('cart', cart);
              prefs.setInt('jumlahHarga', cartJumlahHarga);
              prefs.setInt('jumlahHargaBeli', cartJumlahHargaBeli);

              Navigator.pop(context);
            },
            child: Text('Tambah'),
            style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                backgroundColor:
                    MaterialStateProperty.all(Colors.indigo.shade700),
                fixedSize: MaterialStateProperty.all(Size(150, 40)))),
      );
    } else {
      return Container();
    }
  }

  // Future penjualanList() async {
  //   list = await SQFliteBarang.sql.getPenjualan();
  //   setState(() {});
  // }

  // Future penjualanDetailList() async {
  //   list = await SQFliteBarang.sql.getPenjualanDetail();
  //   setState(() {});
  // }

  Future syncPenjualan() async {
    await SyncToAPI().fetchAllPenjualan().then((penjualanList) async {
      await SyncToAPI().syncPenjualanToAPI(penjualanList);
    });
  }

  Future syncPenjualanDetail() async {
    await SyncToAPI()
        .fetchAllPenjualanDetail()
        .then((penjualanDetailList) async {
      await SyncToAPI().syncPenjualanDetailToAPI(penjualanDetailList);
    });
  }

  // toastSyncPenjualan() {
  //   Fluttertoast.showToast(
  //       msg: '$message',
  //       toastLength: Toast.LENGTH_SHORT,
  //       gravity: ToastGravity.CENTER,
  //       timeInSecForIosWeb: 1,
  //       fontSize: 12.0);
  // }

  syncAlert() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 50,
              ),
              content: Text(
                "Status Sinkron : $message",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                Center(
                  child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
                      style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey),
                          fixedSize: MaterialStateProperty.all(Size(100, 30)))),
                ),
              ]);
        });
  }
}
