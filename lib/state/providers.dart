/// Riverpod providers: repositories and the initially-loaded values.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_data.dart';
import '../storage/auth_repository.dart';
import '../storage/data_repository.dart';

/// The data file repository.
final Provider<DataRepository> dataRepositoryProvider =
    Provider<DataRepository>((ref) => DataRepository());

/// The platform credential store.
final Provider<SecureStore> secureStoreProvider = Provider<SecureStore>(
  (ref) => const PlatformSecureStore(),
);

/// The password repository.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (ref) => AuthRepository(ref.watch(secureStoreProvider)),
    );

/// State loaded from disk before `runApp`. Overridden by `main()` so no
/// screen has to await a future while rendering.
final Provider<AppData> initialDataProvider = Provider<AppData>(
  (ref) => AppData.initial(const []),
);

/// Whether a password already exists (setup vs. returning-user screen).
final Provider<bool> initialHasPasswordProvider = Provider<bool>(
  (ref) => false,
);
