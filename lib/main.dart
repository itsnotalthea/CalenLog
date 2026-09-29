/// Loads persisted state before the first frame, so no screen needs a spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants.dart';
import 'models/app_data.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Placeholder overrides keep container construction legal while the reads
  // run; the seed is non-empty so no provider ever sees an empty habit list.
  final container = ProviderContainer(
    overrides: [
      initialDataProvider.overrideWithValue(
        AppData.initial(buildDefaultHabits()),
      ),
      initialHasPasswordProvider.overrideWithValue(false),
    ],
  );

  final data = await container
      .read(dataRepositoryProvider)
      .load(seed: buildDefaultHabits());
  final hasPassword = await container
      .read(authRepositoryProvider)
      .hasPassword();

  // Same overrides, real values — set before the first frame, no rebuild.
  container.updateOverrides([
    initialDataProvider.overrideWithValue(data),
    initialHasPasswordProvider.overrideWithValue(hasPassword),
  ]);

  runApp(
    UncontrolledProviderScope(container: container, child: const CalenLogApp()),
  );
}
