import 'package:flutter/material.dart';

enum ResponsiveBreakpoint {
  compact, // Mobile screen < 600dp
  medium,  // Foldables / Small Tablet 600 - 840dp
  expanded // Large Tablet / Landscape / Desktop > 840dp
}

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  ResponsiveBreakpoint breakpoint,
  BoxConstraints constraints,
);

class ResponsiveLayoutBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final ResponsiveBreakpoint breakpoint;

        if (width < 600) {
          breakpoint = ResponsiveBreakpoint.compact;
        } else if (width < 840) {
          breakpoint = ResponsiveBreakpoint.medium;
        } else {
          breakpoint = ResponsiveBreakpoint.expanded;
        }

        return builder(context, breakpoint, constraints);
      },
    );
  }
}
