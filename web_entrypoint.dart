import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // Bu import satırı kritik
import 'package:scuba_diving_admin_panel/main.dart' as entrypoint;

void main() {
  usePathUrlStrategy();

  entrypoint.main();
}
