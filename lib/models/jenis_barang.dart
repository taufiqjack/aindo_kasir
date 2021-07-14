import 'package:flutter/foundation.dart';
import 'dart:convert';

List<JenisBarang> jenisBarangFromJson(String str) => List<JenisBarang>.from(
    json.decode(str).map((x) => JenisBarang.fromJson(x)));

String jenisBarangToJson(List<JenisBarang> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@immutable
class JenisBarang {
  const JenisBarang({
    required this.iDJenis,
    required this.nama,
    required this.statusAktif,
  });

  final int iDJenis;
  final String nama;
  final int statusAktif;

  factory JenisBarang.fromJson(Map<String, dynamic> json) => JenisBarang(
      iDJenis: json['IDJenis'] as int,
      nama: json['Nama'] as String,
      statusAktif: json['StatusAktif'] as int);

  Map<String, dynamic> toJson() =>
      {'IDJenis': iDJenis, 'Nama': nama, 'StatusAktif': statusAktif};

  JenisBarang clone() => JenisBarang(
        iDJenis: iDJenis,
        nama: nama,
        statusAktif: statusAktif,
      );

  JenisBarang copyWith({
    int? iDJenis,
    String? nama,
    int? statusAktif,
  }) =>
      JenisBarang(
        iDJenis: iDJenis ?? this.iDJenis,
        nama: nama ?? this.nama,
        statusAktif: statusAktif ?? this.statusAktif,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JenisBarang &&
          iDJenis == other.iDJenis &&
          nama == other.nama &&
          statusAktif == other.statusAktif;

  @override
  int get hashCode => iDJenis.hashCode ^ nama.hashCode ^ statusAktif.hashCode;
}
