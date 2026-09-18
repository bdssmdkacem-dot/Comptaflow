import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Shared responsive application shell.
/// Mobile uses NavigationBar; larger screens use a compact NavigationRail.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.index,
    required this.onIndexChanged,
    required this.body,
  });

  final int index;
  final ValueChanged<int> onIndexChanged;
  final Widget body;

  List<NavigationDestination> _destinations(AppLocalizations l10n) => [
        NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: l10n.dashboard),
        NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long_rounded), label: l10n.invoices),
        NavigationDestination(icon: const Icon(Icons.payments_outlined), selectedIcon: const Icon(Icons.payments_rounded), label: l10n.expenses),
        NavigationDestination(icon: const Icon(Icons.people_outline), selectedIcon: const Icon(Icons.people_rounded), label: l10n.clients),
        NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2_rounded), label: l10n.productsServices),
        NavigationDestination(icon: const Icon(Icons.calculate_outlined), selectedIcon: const Icon(Icons.calculate_rounded), label: l10n.cpu),
        NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: l10n.settings),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = _destinations(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (!wide) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: onIndexChanged,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: destinations,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: onIndexChanged,
                labelType: NavigationRailLabelType.all,
                minWidth: 84,
                groupAlignment: -0.85,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
                    ),
                    child: const Text('C', style: TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                ),
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
