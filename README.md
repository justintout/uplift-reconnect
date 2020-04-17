# Uplift reConnect
> A Flutter app for controlling [Uplift desks](https://www.upliftdesk.com/uplift-v2-standing-desk-v2-or-v2-commercial/) with the Uplift Connect BLE module installed

Since it seems Uplift Connect is no longer on the App or Google Play store, I created this to replace the functionality. 
The app can move the desk up, down, or to saved "sitting" and "standing" heights. You can rename the desk.  

## Installation
Clone this repository then, in the root, `flutter install`.

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

## Built With
Check the in-app License page and `pubspec.yaml` to get a full list of software. In particular, this app uses:
- [FlutterBlue](https://pub.dev/packages/flutter_blue) for BLE communications
- [Provider](https://pub.dev/packages/provider) for state management 