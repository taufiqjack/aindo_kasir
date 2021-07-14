import 'dart:async';
import 'dart:ui';
import 'package:aindo_kasir/controller/internet.dart';
import 'package:aindo_kasir/controller/syncToAPI.dart';
import 'package:aindo_kasir/database/SQFLite.dart';
import 'package:aindo_kasir/layout/login.dart';
import 'package:aindo_kasir/layout/orderpages.dart';
import 'package:aindo_kasir/models/barang.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanggal_indonesia/tanggal_indonesia.dart';
import 'package:aindo_kasir/controller/syncToLocal.dart';

class MenuKasir extends StatefulWidget {
  final List list;
  MenuKasir({required this.list});

  @override
  _MenuKasirState createState() => _MenuKasirState();
}

class _MenuKasirState extends State<MenuKasir> {
  int _itemCount = 0;
  String searchText = "";

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      load();
      // _loadFromAPI();
      // _loadFromJenisBarangAPI();
    });
  }

  List<Barang> listBarang = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      SQFliteBarang.sql.getBarang();
      getSQLiteBarang();
    });
    SQFliteBarang.sql.getBarangScan(scanBarcode).then((value) {
      setState(() {
        value.forEach((data) {
          listBarang.add(Barang(
            iDBarang: data.iDBarang,
            nama: data.nama,
            jenis: data.jenis,
            hargaBeli: data.hargaBeli,
            hargaJual: data.hargaJual,
            gambar: data.gambar,
            satuan: data.satuan,
            statusAktif: data.statusAktif,
          ));
        });
      });
    }).catchError((error) {
      print(error);
    });
  }

  var searchbarcontroller = TextEditingController();

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
            height: 1.0,
            child: TextField(
              controller: searchbarcontroller,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  suffixStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari',
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.cancel),
                    iconSize: 18,
                    color: Colors.grey,
                    onPressed: () {
                      setState(() {
                        searchbarcontroller.clear();
                        searchText = '';
                      });
                    },
                  ),
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
          Padding(
            padding: EdgeInsets.all(2),
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

                              Future.delayed(Duration(seconds: 3), () {
                                load();
                                syncPerjualan();
                                syncPerjualanDetail();
                                toastSyncPenjualan();
                                isLoading = false;
                                Navigator.of(context).pop();
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
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: WillPopScope(
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
                                    EdgeInsets.symmetric(horizontal: 50.0),
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
                                              color: Colors.white,
                                              width: 0.5))),
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
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: FutureBuilder(
                                                        future: SQFliteBarang
                                                            .sql
                                                            .getBarang(),
                                                        builder: (BuildContext
                                                                context,
                                                            AsyncSnapshot
                                                                snapshot) {
                                                          return snapshot
                                                                  .hasData
                                                              ? ListView
                                                                  .builder(
                                                                      itemCount: snapshot
                                                                          .data
                                                                          .length,
                                                                      itemBuilder: (BuildContext
                                                                              context,
                                                                          int
                                                                              index) {
                                                                        // final x = productData[i];
                                                                        final x =
                                                                            snapshot.data[index];
                                                                        // print("data : ${x['IDBarang']}");
                                                                        if (searchText
                                                                            .isEmpty) {
                                                                          return SingleChildScrollView(
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                ListTile(
                                                                                    leading: ClipRRect(
                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                      child: Image.asset(
                                                                                        "assets/images/${x.gambar}",
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
                                                                                      "Harga : " + rupiah('${x.hargaJual}'),
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
                                                                                                  leading: Image.asset(
                                                                                                    "assets/images/${x.gambar}",
                                                                                                  ),
                                                                                                  title: Text(
                                                                                                    '${x.nama}',
                                                                                                    style: TextStyle(color: Colors.indigo.shade600),
                                                                                                  ),
                                                                                                  subtitle: Text(
                                                                                                    rupiah('${x.hargaJual}'),
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
                                                                                                                          _itemCount != 0
                                                                                                                              ? new IconButton(
                                                                                                                                  icon: Icon(Icons.remove),
                                                                                                                                  onPressed: () {
                                                                                                                                    setState(() {
                                                                                                                                      viewOrder(snapshot.data[index]);
                                                                                                                                      _itemCount--;
                                                                                                                                    });
                                                                                                                                  })
                                                                                                                              : new Container(),
                                                                                                                          new Text(
                                                                                                                            _itemCount.toString(),
                                                                                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                          ),
                                                                                                                          new IconButton(
                                                                                                                              icon: Icon(Icons.add),
                                                                                                                              onPressed: () async {
                                                                                                                                setState(() {
                                                                                                                                  viewOrder(snapshot.data[index]);
                                                                                                                                  _itemCount++;
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
                                                                                                      Center(
                                                                                                        child: TextButton(
                                                                                                          child: Text('Tambah'),
                                                                                                          style: ButtonStyle(shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), foregroundColor: MaterialStateProperty.all(Colors.white), backgroundColor: MaterialStateProperty.all(Colors.indigo.shade700), fixedSize: MaterialStateProperty.all(Size(150, 40))),
                                                                                                          onPressed: () {
                                                                                                            for (int i = 0; i < snapshot.data.length; i++)
                                                                                                              Navigator.push(
                                                                                                                  context,
                                                                                                                  PageTransition(
                                                                                                                      type: PageTransitionType.fade,
                                                                                                                      child: OrderPages(
                                                                                                                        barangData: snapshot.data[index],
                                                                                                                        item: _itemCount,
                                                                                                                      )));
                                                                                                          },
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  )
                                                                                                ],
                                                                                              );
                                                                                            });
                                                                                          });
                                                                                    }),
                                                                                Padding(padding: EdgeInsets.only(top: 10)),
                                                                                Divider(
                                                                                  thickness: 2,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        } else if (x
                                                                            .nama
                                                                            .toString()
                                                                            .toLowerCase()
                                                                            .contains(searchText.toLowerCase())) {
                                                                          return SingleChildScrollView(
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                ListTile(
                                                                                  leading: ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(5.0),
                                                                                    child: Image.asset(
                                                                                      "assets/images/${x.gambar}",
                                                                                      height: 100,
                                                                                      width: 60,
                                                                                    ),
                                                                                  ),
                                                                                  title: Text(
                                                                                    // "",
                                                                                    '${x.nama}',
                                                                                    style: TextStyle(color: Colors.indigo.shade600),
                                                                                  ),
                                                                                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                                                    Text(
                                                                                      "Harga Beli : " + rupiah('${x.hargaBeli}').toString(),
                                                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    Text(
                                                                                      "Harga Jual : " + rupiah('${x.hargaJual}'),
                                                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ]),
                                                                                  onTap: () {
                                                                                    showDialog(
                                                                                        context: context,
                                                                                        builder: (BuildContext context) {
                                                                                          return StatefulBuilder(builder: (context, setState) {
                                                                                            return AlertDialog(
                                                                                              content: ListTile(
                                                                                                isThreeLine: true,
                                                                                                leading: Image.asset(
                                                                                                  "assets/images/${x.gambar}",
                                                                                                ),
                                                                                                title: Text(
                                                                                                  '${x.nama}',
                                                                                                  style: TextStyle(color: Colors.indigo.shade600),
                                                                                                ),
                                                                                                subtitle: Text(
                                                                                                  rupiah('${x.hargaJual}'),
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
                                                                                                                        _itemCount != 0
                                                                                                                            ? new IconButton(
                                                                                                                                icon: Icon(Icons.remove),
                                                                                                                                onPressed: () {
                                                                                                                                  setState(() {
                                                                                                                                    viewOrder(snapshot.data[index]);
                                                                                                                                    _itemCount--;
                                                                                                                                  });
                                                                                                                                })
                                                                                                                            : new Container(),
                                                                                                                        new Text(
                                                                                                                          _itemCount.toString(),
                                                                                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                        ),
                                                                                                                        new IconButton(
                                                                                                                            icon: Icon(Icons.add),
                                                                                                                            onPressed: () async {
                                                                                                                              setState(() {
                                                                                                                                viewOrder(snapshot.data[index]);
                                                                                                                                _itemCount++;
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
                                                                                                    Center(
                                                                                                      child: TextButton(
                                                                                                        child: Text('Tambah'),
                                                                                                        style: ButtonStyle(shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), foregroundColor: MaterialStateProperty.all(Colors.white), backgroundColor: MaterialStateProperty.all(Colors.indigo.shade700), fixedSize: MaterialStateProperty.all(Size(150, 40))),
                                                                                                        onPressed: () {
                                                                                                          Navigator.push(
                                                                                                              context,
                                                                                                              PageTransition(
                                                                                                                  type: PageTransitionType.fade,
                                                                                                                  child: OrderPages(
                                                                                                                    barangData: snapshot.data[index],
                                                                                                                    item: _itemCount,
                                                                                                                  )));
                                                                                                        },
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                )
                                                                                              ],
                                                                                            );
                                                                                          });
                                                                                        });
                                                                                  },
                                                                                ),
                                                                                Padding(padding: EdgeInsets.only(top: 10)),
                                                                                Divider(
                                                                                  thickness: 2,
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
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: FutureBuilder(
                                                        future: SQFliteBarang
                                                            .sql
                                                            .getBarangFromJenis(),
                                                        builder: (BuildContext
                                                                context,
                                                            AsyncSnapshot
                                                                snapshot) {
                                                          return snapshot
                                                                  .hasData
                                                              ? ListView
                                                                  .builder(
                                                                  itemCount:
                                                                      snapshot
                                                                          .data
                                                                          .length,
                                                                  itemBuilder:
                                                                      (BuildContext
                                                                              context,
                                                                          index) {
                                                                    // final x = productData[i];
                                                                    final x = snapshot
                                                                            .data[
                                                                        index];
                                                                    // print("data : ${x['IDBarang']}");
                                                                    if (searchText
                                                                        .isEmpty) {
                                                                      return SingleChildScrollView(
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            ListTile(
                                                                              leading: ClipRRect(
                                                                                borderRadius: BorderRadius.circular(5.0),
                                                                                child: Image.asset(
                                                                                  "assets/images/${x.gambar}",
                                                                                  height: 100,
                                                                                  width: 60,
                                                                                ),
                                                                              ),
                                                                              title: Text(
                                                                                // "",
                                                                                '${x.nama}',
                                                                                style: TextStyle(color: Colors.indigo.shade600),
                                                                              ),
                                                                              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                                                Text(
                                                                                  "Harga Beli : " + rupiah('${x.hargaBeli}').toString(),
                                                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                                ),
                                                                                Text(
                                                                                  "Harga Jual : " + rupiah('${x.hargaJual}'),
                                                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                                ),
                                                                              ]),
                                                                              onTap: () {
                                                                                showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                      return StatefulBuilder(builder: (context, setState) {
                                                                                        return AlertDialog(
                                                                                          content: ListTile(
                                                                                            isThreeLine: true,
                                                                                            leading: Image.asset(
                                                                                              "assets/images/${x.gambar}",
                                                                                            ),
                                                                                            title: Text(
                                                                                              '${x.nama}',
                                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                                            ),
                                                                                            subtitle: Text(
                                                                                              rupiah('${x.hargaJual}'),
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
                                                                                                                    _itemCount != 0
                                                                                                                        ? new IconButton(
                                                                                                                            icon: Icon(Icons.remove),
                                                                                                                            onPressed: () {
                                                                                                                              setState(() {
                                                                                                                                viewOrder(snapshot.data[index]);
                                                                                                                                _itemCount--;
                                                                                                                              });
                                                                                                                            })
                                                                                                                        : new Container(),
                                                                                                                    new Text(
                                                                                                                      _itemCount.toString(),
                                                                                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                    ),
                                                                                                                    new IconButton(
                                                                                                                        icon: Icon(Icons.add),
                                                                                                                        onPressed: () async {
                                                                                                                          setState(() {
                                                                                                                            viewOrder(snapshot.data[index]);
                                                                                                                            _itemCount++;
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
                                                                                                Center(
                                                                                                  child: TextButton(
                                                                                                      onPressed: () {
                                                                                                        Navigator.push(
                                                                                                            context,
                                                                                                            new MaterialPageRoute(
                                                                                                                builder: (context) => OrderPages(
                                                                                                                      barangData: snapshot.data[index],
                                                                                                                      item: _itemCount,
                                                                                                                    )));
                                                                                                      },
                                                                                                      child: Text('Tambah'),
                                                                                                      style: ButtonStyle(shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), foregroundColor: MaterialStateProperty.all(Colors.white), backgroundColor: MaterialStateProperty.all(Colors.indigo.shade700), fixedSize: MaterialStateProperty.all(Size(150, 40)))),
                                                                                                ),
                                                                                              ],
                                                                                            )
                                                                                          ],
                                                                                        );
                                                                                      });
                                                                                    });
                                                                              },
                                                                            ),
                                                                            Padding(padding: EdgeInsets.only(top: 10)),
                                                                            Divider(
                                                                              thickness: 2,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    } else if (x
                                                                        .nama
                                                                        .toString()
                                                                        .toLowerCase()
                                                                        .contains(
                                                                            searchText.toLowerCase())) {
                                                                      return SingleChildScrollView(
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            ListTile(
                                                                              leading: ClipRRect(
                                                                                borderRadius: BorderRadius.circular(5.0),
                                                                                child: Image.asset(
                                                                                  "assets/images/${x.gambar}",
                                                                                  height: 100,
                                                                                  width: 60,
                                                                                ),
                                                                              ),
                                                                              title: Text(
                                                                                // "",
                                                                                '${x.nama}',
                                                                                style: TextStyle(color: Colors.indigo.shade600),
                                                                              ),
                                                                              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                                                Text(
                                                                                  "Harga Beli : " + rupiah('${x.hargaBeli}').toString(),
                                                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                                ),
                                                                                Text(
                                                                                  "Harga Jual : " + rupiah('${x.hargaJual}'),
                                                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                                                ),
                                                                              ]),
                                                                              onTap: () {
                                                                                showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                      return StatefulBuilder(builder: (context, setState) {
                                                                                        return AlertDialog(
                                                                                          content: ListTile(
                                                                                            isThreeLine: true,
                                                                                            leading: Image.asset(
                                                                                              "assets/images/${x.gambar}",
                                                                                            ),
                                                                                            title: Text(
                                                                                              '${x.nama}',
                                                                                              style: TextStyle(color: Colors.indigo.shade600),
                                                                                            ),
                                                                                            subtitle: Text(
                                                                                              rupiah('${x.hargaJual}'),
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
                                                                                                                    _itemCount != 0
                                                                                                                        ? new IconButton(
                                                                                                                            icon: Icon(Icons.remove),
                                                                                                                            onPressed: () {
                                                                                                                              setState(() {
                                                                                                                                viewOrder(snapshot.data[index]);
                                                                                                                                _itemCount--;
                                                                                                                              });
                                                                                                                            })
                                                                                                                        : new Container(),
                                                                                                                    new Text(
                                                                                                                      _itemCount.toString(),
                                                                                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                                                                                    ),
                                                                                                                    new IconButton(
                                                                                                                        icon: Icon(Icons.add),
                                                                                                                        onPressed: () async {
                                                                                                                          setState(() {
                                                                                                                            viewOrder(snapshot.data[index]);
                                                                                                                            _itemCount++;
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
                                                                                                Center(
                                                                                                  child: TextButton(
                                                                                                    child: Text('Tambah'),
                                                                                                    style: ButtonStyle(shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), foregroundColor: MaterialStateProperty.all(Colors.white), backgroundColor: MaterialStateProperty.all(Colors.indigo.shade700), fixedSize: MaterialStateProperty.all(Size(150, 40))),
                                                                                                    onPressed: () {
                                                                                                      Navigator.push(
                                                                                                          context,
                                                                                                          PageTransition(
                                                                                                              type: PageTransitionType.fade,
                                                                                                              child: OrderPages(
                                                                                                                barangData: snapshot.data[index],
                                                                                                                item: _itemCount,
                                                                                                              )));
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            )
                                                                                          ],
                                                                                        );
                                                                                      });
                                                                                    });
                                                                              },
                                                                            ),
                                                                            Padding(padding: EdgeInsets.only(top: 10)),
                                                                            Divider(
                                                                              thickness: 2,
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
      ),
      floatingActionButton: viewOrder(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  viewOrder(i) {
    setState(() {});
    // print(int.parse(i.hargaJual));
    if (_itemCount == 0) {
      return Container();
    } else {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context,
              PageTransition(
                  type: PageTransitionType.fade,
                  child: OrderPages(
                    barangData: i,
                    item: _itemCount,
                  )));
        },
        label: Text("View Order  " +
            "(${_itemCount.toString()})" +
            "  Rp${int.parse(listBarang.first.hargaJual) * _itemCount.toInt()}"),
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

  String scanBarcode = 'Tidak diketahui';

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;

    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Batal', true, ScanMode.BARCODE);

      print(barcodeScanRes);
    } catch (e) {
      barcodeScanRes = 'Gagal memuat versi!';
    }

    if (!mounted) return;

    setState(() {
      scanBarcode = barcodeScanRes;

      // scanAlertDialog();
    });
    toastResultScanConnected();
    scanAlertDialog();
  }

  toastResultScanConnected() {
    Fluttertoast.showToast(
        msg: '$scanBarcode',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        fontSize: 12.0);
  }

  scanAlertDialog() async {
    scanBarcode != null
        ? showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: ListTile(
                  isThreeLine: true,
                  leading: Image.asset(
                    "assets/images/${listBarang.first.gambar}",
                  ),
                  title: Text(
                    '${listBarang.first.nama}',
                    style: TextStyle(color: Colors.indigo.shade600),
                  ),
                  subtitle: Text(
                    rupiah('${listBarang.first.hargaJual}'),
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
                                            padding: EdgeInsets.only(right: 5),
                                          ),
                                          _itemCount != 0
                                              ? new IconButton(
                                                  icon: Icon(Icons.remove),
                                                  onPressed: () {
                                                    setState(() {
                                                      viewOrder(
                                                          listBarang.first);
                                                      _itemCount--;
                                                    });
                                                  })
                                              : new Container(),
                                          new Text(
                                            _itemCount.toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          new IconButton(
                                              icon: Icon(Icons.add),
                                              onPressed: () async {
                                                setState(() {
                                                  viewOrder(listBarang.first);
                                                  _itemCount++;
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
                      Center(
                        child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                new MaterialPageRoute(
                                  builder: (context) => OrderPages(
                                    barangData: listBarang.first,
                                    item: _itemCount,
                                  ),
                                ),
                              );
                            },
                            child: Text('Tambah'),
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20))),
                                foregroundColor:
                                    MaterialStateProperty.all(Colors.white),
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.indigo.shade700),
                                fixedSize:
                                    MaterialStateProperty.all(Size(150, 40)))),
                      ),
                    ],
                  ),
                ],
              );
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

  late List list;

  Future penjualanList() async {
    list = await SQFliteBarang.sql.getPenjualan();
    setState(() {});
  }

  Future penjualanDetailList() async {
    list = await SQFliteBarang.sql.getPenjualanDetail();
    setState(() {});
  }

  Future syncPerjualan() async {
    await SyncToAPI().fetchAllPenjualan().then((penjualanList) async {
      await SyncToAPI().syncPenjualanToAPI(penjualanList);
    });
  }

  Future syncPerjualanDetail() async {
    await SyncToAPI()
        .fetchAllPenjualanDetail()
        .then((penjualanDetailList) async {
      await SyncToAPI().syncPenjualanDetailToAPI(penjualanDetailList);
    });
  }

  toastSyncPenjualan() {
    Fluttertoast.showToast(
        msg: 'Data Sukses Tersinkron',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 12.0);
  }
}
