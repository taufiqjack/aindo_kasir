import 'package:flutter/foundation.dart';
import 'dart:convert';

List<Penjualan> penjualanFromJson(String str) =>
    List<Penjualan>.from(json.decode(str).map((x) => Penjualan.fromJson(x)));

String penjualanToJson(List<Penjualan> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@immutable
class Penjualan {
  const Penjualan({
    this.iDTr,
    this.nomorTr,
    required this.tanggalJual,
    required this.diskon,
    required this.diskonRp,
    required this.iDUser,
    required this.nominalJual,
    required this.nominalBeli,
    required this.bayar,
    required this.kembalian,
    required this.sinkron,
  });

  final int? iDTr;
  final String? nomorTr;
  final String tanggalJual;
  final num diskon;
  final int diskonRp;
  final int iDUser;
  final int nominalJual;
  final int nominalBeli;
  final int bayar;
  final int kembalian;
  final int sinkron;

  factory Penjualan.fromJson(Map<String, dynamic> json) => Penjualan(
      iDTr: json['IDTr'] != null ? json['IDTr'] as int : null,
      nomorTr: json['NomorTr'] != null ? json['NomorTr'] as String : null,
      tanggalJual: json['TanggalJual'] as String,
      diskon: json['Diskon'] as num,
      diskonRp: json['DiskonRp'] as int,
      iDUser: json['IDUser'] as int,
      nominalJual: json['NominalJual'] as int,
      nominalBeli: json['NominalBeli'] as int,
      bayar: json['Bayar'] as int,
      kembalian: json['Kembalian'] as int,
      sinkron: json['Sinkron'] as int);

  Map<String, dynamic> toJson() => {
        'IDTr': iDTr,
        'NomorTr': nomorTr,
        'TanggalJual': tanggalJual,
        'Diskon': diskon,
        'DiskonRp': diskonRp,
        'IDUser': iDUser,
        'NominalJual': nominalJual,
        'NominalBeli': nominalBeli,
        'Bayar': bayar,
        'Kembalian': kembalian,
        'Sinkron': sinkron
      };

  Penjualan clone() => Penjualan(
      iDTr: iDTr,
      nomorTr: nomorTr,
      tanggalJual: tanggalJual,
      diskon: diskon,
      diskonRp: diskonRp,
      iDUser: iDUser,
      nominalJual: nominalJual,
      nominalBeli: nominalBeli,
      bayar: bayar,
      kembalian: kembalian,
      sinkron: sinkron);

  Penjualan copyWith(
          {int? iDTr,
          String? nomorTr,
          String? tanggalJual,
          num? diskon,
          int? diskonRp,
          int? iDUser,
          int? nominalJual,
          int? nominalBeli,
          int? bayar,
          int? kembalian,
          int? sinkron}) =>
      Penjualan(
        iDTr: iDTr ?? this.iDTr,
        nomorTr: nomorTr ?? this.nomorTr,
        tanggalJual: tanggalJual ?? this.tanggalJual,
        diskon: diskon ?? this.diskon,
        diskonRp: diskonRp ?? this.diskonRp,
        iDUser: iDUser ?? this.iDUser,
        nominalJual: nominalJual ?? this.nominalJual,
        nominalBeli: nominalBeli ?? this.nominalBeli,
        bayar: bayar ?? this.bayar,
        kembalian: kembalian ?? this.kembalian,
        sinkron: sinkron ?? this.sinkron,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Penjualan &&
          iDTr == other.iDTr &&
          nomorTr == other.nomorTr &&
          tanggalJual == other.tanggalJual &&
          diskon == other.diskon &&
          diskonRp == other.diskonRp &&
          iDUser == other.iDUser &&
          nominalJual == other.nominalJual &&
          nominalBeli == other.nominalBeli &&
          bayar == other.bayar &&
          kembalian == other.kembalian &&
          sinkron == other.sinkron;

  @override
  int get hashCode =>
      iDTr.hashCode ^
      nomorTr.hashCode ^
      tanggalJual.hashCode ^
      diskon.hashCode ^
      diskonRp.hashCode ^
      iDUser.hashCode ^
      nominalJual.hashCode ^
      nominalBeli.hashCode ^
      bayar.hashCode ^
      kembalian.hashCode ^
      sinkron.hashCode;
}
