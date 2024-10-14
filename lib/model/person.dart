// To parse this JSON data, do
//
//     final person = personFromJson(jsonString);

import 'dart:convert';

List<Person> personFromJson(String str) => List<Person>.from(json.decode(str).map((x) => Person.fromJson(x)));

String personToJson(List<Person> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJsonWithoutID())));

class Person {
  int? id;
  DateTime? createdAt;
  String? name;
  String? address;
  String? phone;
  DateTime? birthDate;
  List<DateTime>? attendance;
  DateTime? lastAttendDate;

  Person({
    this.id,
    this.createdAt,
    this.name,
    this.address,
    this.phone,
    this.birthDate,
    this.attendance,
    this.lastAttendDate,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json["id"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    name: json["name"],
    address: json["address"],
    phone: json["phone"],
    birthDate: json["birth_date"] == null ? null : DateTime.parse(json["birth_date"]),
    attendance: json["attendance"] == null ? [] : List<DateTime>.from(json["attendance"]!.map((x) => DateTime.parse(x))),
    lastAttendDate: json["last_attend_date"] == null ? null : DateTime.parse(json["last_attend_date"]),
  );

  Map<String, dynamic> toJsonWithoutID() => {
    if(name != null)"name": name,
    if(address != null)"address": address,
    if(phone != null)"phone": phone,
    if(birthDate != null)"birth_date": "${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}",
    "attendance": attendance == null ? [] : List<dynamic>.from(attendance!.map((x) => "${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}")),
    if(lastAttendDate != null)"last_attend_date": "${lastAttendDate!.year.toString().padLeft(4, '0')}-${lastAttendDate!.month.toString().padLeft(2, '0')}-${lastAttendDate!.day.toString().padLeft(2, '0')}",
  };

  Map<String, dynamic> toJson() => {
    if(id != null)"id": id,
    if(createdAt != null)"created_at": createdAt?.toIso8601String(),
    if(name != null)"name": name,
    if(address != null)"address": address,
    if(phone != null)"phone": phone,
    if(birthDate != null)"birth_date": "${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}",
    "attendance": attendance == null ? [] : List<dynamic>.from(attendance!.map((x) => "${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}")),
    if(lastAttendDate != null)"last_attend_date": "${lastAttendDate!.year.toString().padLeft(4, '0')}-${lastAttendDate!.month.toString().padLeft(2, '0')}-${lastAttendDate!.day.toString().padLeft(2, '0')}",
  };
}
