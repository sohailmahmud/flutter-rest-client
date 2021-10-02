import 'package:meta/meta.dart';

/// Proxy class for the API Client.  This is useful mostly in development to be
/// able to route / trace API calls via something like Fiddler2 / Charles Proxy.
@immutable
class Proxy {
  Proxy({
    this.ignoreBadCertificate = false,
    required this.url,
  });

  /// Instructs the application to ignore SSL errors.
  final bool ignoreBadCertificate;

  /// The URL to the proxy.  The meaning of `localhost` actually differs between
  /// Android and iOS.  For iOS, `localhost` refers to the computer the
  /// Simulator is running on.  For Android, `localhost` refers to the device
  /// itself and to reference the host computer you would instead need to use
  /// the Android Emulator loopback ip: `10.0.2.2`.
  final String url;
}
