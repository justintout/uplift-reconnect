abstract class PreferenceKey {
  static const SITTING_VALUE = "sitting-value";
  static const STANDING_VALUE = "standing-value";
  static const AUTOCONNECT_ENABLED = "autoconnect-enabled";
}

// TODO: enable extension-methods 

// enum PreferenceKey {
//   STANDING_VALUE, SITTING_VALUE, AUTOCONNECT_ENABLED
// }

// extension Stringer on PreferenceKey {
//   static String _string(PreferenceKey k) {
//     switch(k) {
//       case PreferenceKey.STANDING_VALUE:
//         return "standing-value";
//       case PreferenceKey.SITTING_VALUE:
//         return "sitting-value";
//       case PreferenceKey.AUTOCONNECT_ENABLED:
//         return "autoconnect-enabled";
//     }
//   }

//   String get string => _string(this);
// }

const appTitle = "Uplift reConnect";
const version = "0.0.1";
const summary =
  "This app was created by Justin Tout in 2020 as a personal project. " +
  "It provides support for connecting to and controlling Uplift desks with the " +
  "optional Uplift Connect BLE dongle installed. It seems the company has dropped " +
  "support for their own mobile apps.";