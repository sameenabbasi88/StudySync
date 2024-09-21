// web_helper.dart
import 'dart:html' as html;

void addBeforeUnloadListener(void Function() callback) {
  html.window.addEventListener('beforeunload', (event) {
    callback();
  });
}

void removeBeforeUnloadListener() {
  html.window.removeEventListener('beforeunload', null);
}
