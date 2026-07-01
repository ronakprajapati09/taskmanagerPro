import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/theme/theme_cubit.dart';
import '../widgets/app_card.dart';

/// Settings: theme mode selection (persisted) and app info.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Text('Settings',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Appearance'),
            const SizedBox(height: 8),
            _themeSelector(context),
            const SizedBox(height: 24),
            _sectionTitle(context, 'About'),
            const SizedBox(height: 8),
            const AppCard(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Task Manager Pro'),
                subtitle: Text(
                    'Smart Task Management Made Simple'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary));
  }

  Widget _themeSelector(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return AppCard(
          child: Column(
            children: [
              _themeOption(context, 'System default', Icons.brightness_auto,
                  ThemeMode.system, mode),
              const Divider(height: 1),
              _themeOption(context, 'Light', Icons.light_mode,
                  ThemeMode.light, mode),
              const Divider(height: 1),
              _themeOption(
                  context, 'Dark', Icons.dark_mode, ThemeMode.dark, mode),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption(BuildContext context, String label, IconData icon,
      ThemeMode value, ThemeMode current) {
    final selected = value == current;
    return ListTile(
      leading: Icon(icon,
          color: selected ? Theme.of(context).colorScheme.primary : null),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: () => context.read<ThemeCubit>().setMode(value),
    );
  }
}


