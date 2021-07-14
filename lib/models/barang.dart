import 'package:flutter/foundation.dart';
import 'dart:convert';

List<Barang> barangFromJson(String str) =>
    List<Barang>.from(json.decode(str).map((x) => Barang.fromJson(x)));

String barangToJson(List<Barang> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@immutable
class Barang {
  const Barang({
    required this.iDBarang,
    required this.nama,
    required this.jenis,
    required this.hargaBeli,
    required this.hargaJual,
    required this.gambar,
    required this.satuan,
    required this.statusAktif,
  });

  final int iDBarang;
  final String nama;
  final int jenis;
  final String hargaBeli;
  final String hargaJual;
  final String gambar;
  final String satuan;
  final int statusAktif;

  factory Barang.fromJson(Map<String, dynamic> json) => Barang(
      iDBarang: json['IDBarang'],
      nama: json['Nama'],
      jenis: json['Jenis'],
      hargaBeli: json['HargaBeli'],
      hargaJual: json['HargaJual'],
      gambar: json['Gambar'],
      satuan: json['Satuan'],
      statusAktif: json['StatusAktif']);

  Map<String, dynamic> toJson() => {
        'IDBarang': iDBarang,
        'Nama': nama,
        'Jenis': jenis,
        'HargaBeli': hargaBeli,
        'HargaJual': hargaJual,
        'Gambar': gambar,
        'Satuan': satuan,
        'StatusAktif': statusAktif
      };

  Barang clone() => Barang(
      iDBarang: iDBarang,
      nama: nama,
      jenis: jenis,
      hargaBeli: hargaBeli,
      hargaJual: hargaJual,
      gambar: gambar,
      satuan: satuan,
      statusAktif: statusAktif);

  Barang copyWith(
          {int? iDBarang,
          String? nama,
          int? jenis,
          String? hargaBeli,
          String? hargaJual,
          String? gambar,
          String? satuan,
          int? statusAktif}) =>
      Barang(
        iDBarang: iDBarang ?? this.iDBarang,
        nama: nama ?? this.nama,
        jenis: jenis ?? this.jenis,
        hargaBeli: hargaBeli ?? this.hargaBeli,
        hargaJual: hargaJual ?? this.hargaJual,
        gambar: gambar ?? this.gambar,
        satuan: satuan ?? this.satuan,
        statusAktif: statusAktif ?? this.statusAktif,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Barang &&
          iDBarang == other.iDBarang &&
          nama == other.nama &&
          jenis == other.jenis &&
          hargaBeli == other.hargaBeli &&
          hargaJual == other.hargaJual &&
          gambar == other.gambar &&
          satuan == other.satuan &&
          statusAktif == other.statusAktif;

  @override
  int get hashCode =>
      iDBarang.hashCode ^
      nama.hashCode ^
      jenis.hashCode ^
      hargaBeli.hashCode ^
      hargaJual.hashCode ^
      gambar.hashCode ^
      satuan.hashCode ^
      statusAktif.hashCode;
}
