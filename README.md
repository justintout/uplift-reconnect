# Uplift reConnect
> A Flutter app for controlling [Uplift desks](https://www.upliftdesk.com/uplift-v2-standing-desk-v2-or-v2-commercial/) with the Uplift Connect BLE module installed

Since it seems Uplift Connect is no longer on the App or Google Play store, I created this to replace the functionality. 
The app can move the desk up, down, or to the desk's own stored "sitting" and "standing" presets. You can rename the desk.

The sit and stand buttons use the presets held in the desk's controller rather than a height saved in the app, which is
how the desk's physical button pad works. Hold either button to overwrite that preset with the desk's current height.

## Installation
Clone this repository, then from the root run `flutter pub get` and `flutter run` with a phone or emulator
attached. The desk needs the Uplift Connect dongle plugged in and Bluetooth switched on. The app asks for
the Bluetooth permissions it needs the first time it starts.

To produce builds, run `make`. That builds Android and iOS, regenerating the licence list first so
the shipped app carries it. `make android` or `make ios` builds one platform. Shipping needs signing:
`flutter build appbundle` for Play, or `flutter build ipa` for the App Store.

## Settings
- **Reconnect automatically** — connect to the last desk used whenever the app opens. The dongle keeps its
  link to the phone, so this usually just picks up the connection the OS already established.
- **Height units** — show the height in inches or centimetres. The desk reports the same byte either way.
- **Held button repeat** — how often the up and down buttons re-send while held. The desk keeps moving for a
  moment after the last command arrives, so a shorter interval stops it sooner when you let go.

## BLE API 
The Uplift BLE API was reverse engineered by capturing communication between the Uplift Connect Android app and dongle. Captures were made with the Android "Bluetooth HCI Logging" developer option and by sniffing BLE packets using an [Ubertooth One](https://greatscottgadgets.com/ubertoothone/).

## Services and Characteristics 
> scanned with [nRF Connect](https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp&hl=en_US), custom service characteristic names gathered from descriptor

| Service Name       | Service UUID                          | Characteristic Name                       | Characteristic UUID                    | READ | WRITE | WRITE NO RESPONSE | NOTIFY | INDICATE | Descriptor Name | Descriptor UUID |
|--------------------|---------------------------------------|-------------------------------------------|----------------------------------------|------|-------|-------------------|--------|----------|-----------------|-----------------|
| Generic Access     | 0x1800                                | Device Name                               | 0x2a00                                 | ✓    |       |                   |        |          |                 |                 |
| Generic Access     | 0x1800                                | Appearance                                | 0x2a01                                 | ✓    |       |                   |        |          |                 |                 |
| Generic Access     | 0x1800                                | Peripheral Privacy Flag                   | 0x2a02                                 | ✓    | ✓     |                   |        |          |                 |                 |
| Generic Access     | 0x1800                                | Reconnection Address                      | 0x2a03                                 |      | ✓     |                   |        |          |                 |                 |
| Generic Access     | 0x1800                                | Periperal Preferred Connection Parameters | 0x2a04                                 | ✓    |       |                   |        |          |                 |                 |
| Generic Attribute  | 0x1801                                | Service Changed                           | 0x2a05                                 |      |       |                   |        | ✓        | CCCD            | 0x2902          |
| Device Information | 0x180a                                | System ID                                 | 0x2a23                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | Model Number String                       | 0x2a24                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | Serial Number String                      | 0x2a25                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | Fimware Revision String                   | 0x2a26                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | Hardware Revision String                  | 0x2a27                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | Software Revision String                  | 0x2a28                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | Manufacturer Name String                  | 0x2a29                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | IEEE 11073-20601 Regulatory Certification | 0x2a2a                                 | ✓    |       |                   |        |          |                 |                 |
| Device Information | 0x180a                                | PnP ID                                    | 0x2a50                                 | ✓    |       |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Data In                                   | 0000ff01-0000-1000-8000-008005F9B34FB  |      |       | ✓                 |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Data Out                                  | 0000ff02-0000-1000-8000-008005F9B34FB  |      |       |                   | ✓      |          | CCCD            | 0x2902          |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Baundrate [sic]                           | 0000ff03-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Link interval                             | 0000ff04-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Pair Code                                 | 0000ff05-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | BT name                                   | 0000ff06-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Pair Code En                              | 0000ff07-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | ADV Interval                              | 0000ff08-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Tx Power                                  | 0000ff09-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | MCU Delay                                 | 0000ff0a-0000-1000-8000-008005F9B34FB  | ✓    | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Factoryset                                | 0000fff0-0000-1000-8000-008005F9B34FB  |      | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | Reset                                     | 0000ffff1-0000-1000-8000-008005F9B34FB |      | ✓     |                   |        |          |                 |                 |
| Custom Service     | 0000FF12-0000-1000-8000-008005F9B34FB | FW Version                                | 0000fff2-0000-1000-8000-008005F9B34FB  | ✓    |       |                   |        |          |                 |                 |

### Custom Service Notes (`0000FF12-0000-1000-8000-008005F9B34FB`)

#### Data In	(`0000ff01-0000-1000-8000-008005F9B34FB`)
- `WRITE NO RESPONSE`, characteristics commands are sent IN on
- `WRITE`: `0xf2, 0xf2, 0x01, 0x03, 0x01, 0xd0, 0x07, 0xdc, 0x7e`
    - sent from sitting height
    - nothing happens 

Commands take the shape `0xf1, 0xf1, <command>, 0x00, <command>, 0x7e`: a fixed prefix, the command byte,
then the command repeated after a zero and terminated with `0x7e`.

| Command     | Packet                     | Effect                                              |
|-------------|----------------------------|-----------------------------------------------------|
| up          | `f1, f1, 01, 00, 01, 7e`   | move up while held                                  |
| down        | `f1, f1, 02, 00, 02, 7e`   | move down while held                                |
| save stand  | `f1, f1, 03, 00, 03, 7e`   | store the current height as the desk's stand preset |
| save sit    | `f1, f1, 04, 00, 04, 7e`   | store the current height as the desk's sit preset   |
| stand       | `f1, f1, 05, 00, 05, 7e`   | move to the desk's stored stand preset              |
| sit         | `f1, f1, 06, 00, 06, 7e`   | move to the desk's stored sit preset                |
| query       | `f1, f1, 07, 00, 07, 7e`   | ask the desk to report its current height           |

The capture these commands came from labelled 05 `sit` and 06 `stand`, but a real desk does the opposite,
and 03 and 04 swap with them: 06 recalls the sitting height and 03 stores it, 05 recalls the standing
height and 04 stores it. The table above is what the hardware does.

The sit and stand presets live in the desk's controller rather than in the app, so they survive a
reinstall and match what the physical button pad uses. Saving a preset is not acknowledged; the desk
simply starts reporting the new position.

#### Data Out (`0000ff02-0000-1000-8000-008005F9B34FB`)
- `NOTIFY`, responds out to commands/height changes
- does include changes from the physical buttonpad
- only bytes 5 and 7 seem to change, and change linearly 
- sample values
    - standing: `0xf2,0xf2,0x01,0x03,0x01,0xd0,0x07,0xdc,0x7e`
    - ~halfway: `0xf2,0xf2,0x01,0x03,0x01,0x7e,0x07,0x8a,0x7e`
    - sitting:  `0xf2,0xf2,0x01,0x03,0x01,0x30,0x07,0x3c,0x7e`
- notifications at different desk heights 
    - 28": `0x1f,0x07,0x2b` (`[ 31, 7, 43 ]`)
    - 30": `0x33,0x07,0x3f` (`[ 51, 7, 63 ]`)
    - 36": `0x6f,0x07,0x7b` (`[ 111, 7, 123 ]`)
    - 40": `0x97,0x07,0xa3` (`[ 151, 7, 163 ]`)
- seems like height value could be a mapping 0-255 to desk height. 
- height values displayed in the app are based on the estimate that each change in byte 5 is ~0.1 inch. this seems to get the height very close 
  for desks on the Uplift V2 frame. 

#### Baundrate [sic]
- `READ`: `0x02`

#### Link interval
- `READ`: `0x24,0x00`

#### Pair Code
- `READ`: `0x30,0x30,0x30,0x30,0x30,0x31`, `"000001"`
- maybe unused since no encryption is used? 

#### BT name
- `READ`: `"BLE Device-926871"`
- Current device name
- Writing changes name, `WRITE`: `"Justins Desk"`
- Keeps name after disconnect, advertises with new name
- writing this does change `0x2a00` 

#### Pair Code En
- `READ`: `0x01`
- En: "enter?" "enable?"
- `WRITE`: `"000001"`
    - no change


#### ADV Interval
- `READ`: `0x0a, 0x00`
- advertising interval? can check with adv scan

#### TX Power
- `READ`: `0x02`

#### MCU Delay
- `READ`: `0x00`

#### Factoryset
- factory reset 
- `WRITE`: `0x01`
    - disconnected
    - autoconnected after delay in nRF 
    - `BT Name` reset to default

#### Reset
- `WRITE`: `0x01`
    - disconnected
    - kept value at `BT name` written previously 
    - might cycle device power? 

#### FW Version
- not the actual Firmware Revision String characteristic? 
- `READ`: `0x02, 0x01`

## Licences
The in-app licence page is Flutter's `showLicensePage`, so it lists the Dart packages from the
`NOTICES` asset Flutter generates. That asset knows nothing about the libraries the native builds
pull in, so `assets/native_licenses.json` carries those: the Maven artefacts Gradle resolves, and
the pods CocoaPods installs.

That file is generated. After any dependency change, run `make licenses` to regenerate it. That
builds both platforms first if they have never been built, because Gradle and CocoaPods have to have
produced something to read. The equivalent by hand is:

```
flutter build apk --debug
flutter build ios --debug --no-codesign
dart run tool/update_native_licenses.dart
```

The script fails if it meets a library with no licence rather than leaving it out, so a new
dependency cannot go unattributed by accident.

## Built With
Check the in-app License page and `pubspec.yaml` to get a full list of software. In particular, this app uses:
- [UniversalBLE](https://pub.dev/packages/universal_ble) for BLE communications 