import 'package:flutter/foundation.dart';
import 'dart:convert';

List<PenjualanDetail> penjualanDetailFromJson(String str) =>
    List<PenjualanDetail>.from(
        json.decode(str).map((x) => PenjualanDetail.fromJson(x)));

String penjualanDetailToJson(List<PenjualanDetail> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@immutable
class PenjualanDetail {
  const PenjualanDetail({
    this.iDTr,
    required this.iDBarang,
    required this.kuantiti,
    required this.hargaJual,
    required this.hargaBeli,
    required this.diskonSatuan,
  });

  final int? iDTr;
  final int iDBarang;
  final int kuantiti;
  final int hargaJual;
  final int hargaBeli;
  final int diskonSatuan;

  factory PenjualanDetail.fromJson(Map<String, dynamic> json) =>
      PenjualanDetail(
          iDTr: json['IDTr'] != null ? json['IDTr'] as int : null,
          iDBarang: json['IDBarang'] as int,
          kuantiti: json['Kuantiti'] as int,
          hargaJual: json['HargaJual'] as int,
          hargaBeli: json['HargaBeli'] as int,
          diskonSatuan: json['DiskonSatuan'] as int);

  Map<String, dynamic> toJson() => {
        'IDTr': iDTr,
        'IDBarang': iDBarang,
        'Kuantiti': kuantiti,
        'HargaJual': hargaJual,
        'HargaBeli': hargaBeli,
        'DiskonSatuan': diskonSatuan
      };

  PenjualanDetail clone() => PenjualanDetail(
      iDTr: iDTr,
      iDBarang: iDBarang,
      kuantiti: kuantiti,
      hargaJual: hargaJual,
      hargaBeli: hargaBeli,
      diskonSatuan: diskonSatuan);

  PenjualanDetail copyWith(
          {int? iDTr,
          int? iDBarang,
          int? kuantiti,
          int? hargaJual,
          int? hargaBeli,
          int? diskonSatuan}) =>
      PenjualanDetail(
        iDTr: iDTr ?? this.iDTr,
        iDBarang: iDBarang ?? this.iDBarang,
        kuantiti: kuantiti ?? this.kuantiti,
        hargaJual: hargaJual ?? this.hargaJual,
        hargaBeli: hargaBeli ?? this.hargaBeli,
        diskonSatuan: diskonSatuan ?? this.diskonSatuan,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PenjualanDetail &&
          iDTr == other.iDTr &&
          iDBarang == other.iDBarang &&
          kuantiti == other.kuantiti &&
          hargaJual == other.hargaJual &&
          hargaBeli == other.hargaBeli &&
          diskonSatuan == other.diskonSatuan;

  @override
  int get hashCode =>
      iDTr.hashCode ^
      iDBarang.hashCode ^
      kuantiti.hashCode ^
      hargaJual.hashCode ^
      hargaBeli.hashCode ^
      diskonSatuan.hashCode;
}
