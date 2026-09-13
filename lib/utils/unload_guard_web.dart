import 'dart:js_interop';

import 'package:web/web.dart' as web;

JSFunction? _listener;

/// Registers (or removes) a `beforeunload` handler that asks the browser to
/// show its leave-page confirmation. Browsers ignore custom text, so the
/// value only has to be non-empty.
void setUnloadGuard(bool active) {
  if (active) {
    if (_listener != null) return;
    _listener = ((web.Event e) {
      e.preventDefault();
      (e as web.BeforeUnloadEvent).returnValue = 'Grids are still being saved.';
    }).toJS;
    web.window.addEventListener('beforeunload', _listener);
  } else {
    final l = _listener;
    if (l == null) return;
    web.window.removeEventListener('beforeunload', l);
    _listener = null;
  }
}
