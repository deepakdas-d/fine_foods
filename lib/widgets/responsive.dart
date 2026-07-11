/// Centralized responsive breakpoint helper.
///
/// Usage:
///   if (Responsive.isDesktop(context)) { … }
///
/// Matches the existing threshold in billing.dart (> 800).
library;
import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  /// Width above which we show the desktop sidebar layout.
  static const double desktopBreakpoint = 800;

  /// Maximum content-area width so ultra-wide monitors don't stretch layouts.
  static const double maxContentWidth = 1200;

  /// Returns true when the available width exceeds [desktopBreakpoint].
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > desktopBreakpoint;
}
