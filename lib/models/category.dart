import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}
