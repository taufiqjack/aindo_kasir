import 'dart:io';

import 'package:aindo_kasir/models/barang.dart';
import 'package:aindo_kasir/models/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQFliteBarang {
  static late Database _db;
  static final SQFliteBarang sql = SQFliteBarang._();
  SQFliteBarang._();

  Future<Database> get database async {
    _db = await _initDatabase();
    return _db;
  }

  _initDatabase() async {
    Directory databasePath = await getApplicationDocumentsDirectory();
    final path = join(databasePath.path, 'kasir_manager.db');

    return await openDatabase(path, version: 1, onOpen: (sql) {},
        onCreate: (Database db, int version) async {
      await db.execute(
          'create table Barang( IDBarang INTEGER PRIMARY KEY, Nama TEXT, KodeBarang TEXT UNIQUE, Jenis INTEGER, HargaBeli TEXT, HargaJual TEXT, Gambar TEXT,  Satuan TEXT, StatusAktif INTEGER)');
      await db.execute(
          'create table JenisBarang( IDJenis INTEGER PRIMARY KEY, Nama TEXT, StatusAktif INTEGER)');
      await db.execute(
          'create table Penjualan( IDTr INTEGER PRIMARY KEY AUTOINCREMENT, NomorTr TEXT, TanggalJual default current_timestamp, Diskon NUMERIC, DiskonRp INTEGER, IDUser INTEGER,  NominalJual INTEGER, NominalBeli INTEGER, Bayar INTEGER, Kembalian INTEGER, Sinkron INTEGER)');
      await db.execute(
          'CREATE TRIGGER IF NOT EXISTS NomorTr AFTER INSERT ON Penjualan BEGIN UPDATE Penjualan SET NomorTr = NomorTr || new.IDTr WHERE IDTr = new.IDTr; END');
      await db.execute(
          'create table PenjualanDetail( IDTr INTEGER PRIMARY KEY AUTOINCREMENT, IDBarang INTEGER, Kuantiti INTEGER, HargaJual INTEGER, HargaBeli INTEGER, DiskonSatuan INTEGER)');
    });
  }

/* untuk database barang */
/*====================================== */

  insertBarang(Barang model) async {
    var row = {
      'IDBarang': model.iDBarang,
      'KodeBarang': model.kodeBarang,
      'Nama': model.nama,
      'Jenis': model.jenis,
      'HargaBeli': model.hargaBeli,
      'HargaJual': model.hargaJual,
      'Gambar': model.gambar,
      'Satuan': model.satuan,
      'StatusAktif': model.statusAktif,
    };
    await deleteAllBarang();
    final db = await database;
    final create = await db.insert('Barang', row);
    return create;
  }

  Future<int> deleteAllBarang() async {
    final db = await database;
    final del = await db.rawDelete('DELETE FROM Barang');

    return del;
  }

  Future<List<Barang>> getBarang() async {
    Database db = await database;

    var allData = await db.rawQuery('SELECT * FROM Barang WHERE Jenis=1');
    List<Barang> list = allData.isNotEmpty
        ? allData.map((e) => Barang.fromJson(e)).toList()
        : [];

    return list;
  }

  Future<List<Barang>> getBarangFromJenis() async {
    Database db = await database;

    var allData = await db.rawQuery('SELECT * FROM Barang WHERE Jenis=2');
    List<Barang> list = allData.isNotEmpty
        ? allData.map((e) => Barang.fromJson(e)).toList()
        : [];

    return list;
  }

/* untuk database jenisBarang */
/*====================================== */
  insertJenisBarang(JenisBarang model) async {
    var row = {
      'IDJenis': model.iDJenis,
      'Nama': model.nama,
      'StatusAktif': model.statusAktif,
    };
    await deleteAllJenisBarang();
    final db = await database;
    final create = await db.insert('JenisBarang', row);
    return create;
  }

  Future<int> deleteAllJenisBarang() async {
    final db = await database;
    final del = await db.rawDelete('DELETE FROM JenisBarang');

    return del;
  }

  Future<List<JenisBarang>> getJenisBarang() async {
    Database db = await database;

    var allData = await db.rawQuery("SELECT * FROM JenisBarang");
    List<JenisBarang> list = allData.isNotEmpty
        ? allData.map((e) => JenisBarang.fromJson(e)).toList()
        : [];

    return list;
  }

/* untuk database penjualan */
/*====================================== */

  insertPenjualan(Penjualan model) async {
    var row = {
      'IDTr': model.iDTr,
      'NomorTr': model.nomorTr,
      'TanggalJual': model.tanggalJual,
      'Diskon': model.diskon,
      'DiskonRp': model.diskonRp,
      'IDUser': model.iDUser,
      'NominalJual': model.nominalJual,
      'NominalBeli': model.nominalBeli,
      'Bayar': model.bayar,
      'Kembalian': model.kembalian,
      'Sinkron': model.sinkron,
    };

    final db = await database;
    final create = await db.insert('Penjualan', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return create;
  }

  Future<int> createPenjualan(Penjualan penjualan) async {
    final db = await database;
    int result = 1;
    try {
      result = await db.insert(
        'Penjualan',
        penjualan.toJson(),
      );
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<int> deleteAllPenjualan() async {
    final db = await database;
    final del = await db.rawDelete('DELETE FROM Penjualan');

    return del;
  }

  Future<List<Penjualan>> getPenjualanByLatest() async {
    Database db = await database;

    var allData =
        await db.rawQuery('SELECT * FROM Penjualan ORDER BY IDTr DESC LIMIT 1');
    List<Penjualan> list = allData.isNotEmpty
        ? allData.map((e) => Penjualan.fromJson(e)).toList()
        : [];

    return list;
  }

  Future<List<Penjualan>> getPenjualan() async {
    Database db = await database;

    var allData = await db.rawQuery('SELECT * FROM Penjualan');
    List<Penjualan> list = allData.isNotEmpty
        ? allData.map((e) => Penjualan.fromJson(e)).toList()
        : [];

    return list;
  }

/* untuk tabel penjualandetail */
/*====================================== */

  insertPenjualanDetail(PenjualanDetail model) async {
    var row = {
      'IDTr': model.iDTr,
      'IDBarang': model.iDBarang,
      'Kuantiti': model.kuantiti,
      'HargaJual': model.hargaJual,
      'HargaBeli': model.hargaBeli,
      'DiskonSatuan': model.diskonSatuan,
    };

    final db = await database;
    final create = await db.insert('PenjualanDetail', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return create;
  }

  Future<int> deleteAllPenjualanDetail() async {
    final db = await database;
    final del = await db.rawDelete('DELETE FROM PenjualanDetail');

    return del;
  }

  Future<List<PenjualanDetail>> getPenjualanDetail() async {
    Database db = await database;

    var allData = await db.rawQuery('SELECT * FROM PenjualanDetail');
    List<PenjualanDetail> list = allData.isNotEmpty
        ? allData.map((e) => PenjualanDetail.fromJson(e)).toList()
        : [];

    return list;
  }

  Future<List<Barang>> getBarangScan(String kodeBarang) async {
    Database db = await database;

    var result = await db
        .rawQuery('SELECT * FROM BARANG WHERE KodeBarang LIKE $kodeBarang');
    List<Barang> list =
        result.isNotEmpty ? result.map((e) => Barang.fromJson(e)).toList() : [];
    return list;
  }
}
