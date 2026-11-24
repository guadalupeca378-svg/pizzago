import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({required this.uid, required this.name, required this.email, this.phone = '', this.address = ''});

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
    phone: map['phone'] as String? ?? '',
    address: map['address'] as String? ?? '',
  );

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  AppUser copyWith({String? name, String? phone, String? address}) => AppUser(
    uid: uid,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
  );

  Map<String, dynamic> toMap() => {'uid': uid, 'name': name, 'email': email, 'phone': phone, 'address': address};
}
