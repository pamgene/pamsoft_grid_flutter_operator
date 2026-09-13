import 'unload_guard_stub.dart'
    if (dart.library.js_interop) 'unload_guard_web.dart' as impl;

/// Warns the user before the tab closes while a save is in flight.
///
/// Web only; a no-op on desktop. Closing the checker mid-upload leaves the
/// step with an empty result file, so the browser's "leave site?" prompt is
/// the last line of defence while [UnloadGuard.active] is true.
class UnloadGuard {
  static bool _active = false;
  static bool get active => _active;

  static void set(bool active) {
    if (_active == active) return;
    _active = active;
    impl.setUnloadGuard(active);
  }
}
