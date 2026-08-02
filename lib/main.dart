import 'package:flutter/material.dart';

import 'app/budget_planner_app.dart';
import 'services/currency_service.dart';
import 'services/route_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    CurrencyService.init(),
    RouteService.init(),
  ]);
  runApp(const BudgetPlannerApp());
}
