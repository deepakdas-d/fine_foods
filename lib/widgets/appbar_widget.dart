import 'package:flutter/material.dart';

PreferredSizeWidget buildAppbar({
  required Color color,
  required Widget title,
  required Color forecolor,
}) {
  return AppBar(
    backgroundColor: color,
    title: title,
    foregroundColor: forecolor,
  );
}
