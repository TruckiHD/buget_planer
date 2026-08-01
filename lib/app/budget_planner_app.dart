import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../utils/app_theme.dart';

class BudgetPlannerApp extends StatelessWidget {
  const BudgetPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Planer',
      theme: AppTheme.light(),
      home: const DashboardScreen(),
    );
  }
}
