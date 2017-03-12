# pimatic-milight-reloaded

[![Npm Version](https://badge.fury.io/js/pimatic-milight-reloaded.svg)](http://badge.fury.io/js/pimatic-milight-reloaded)
[![Build Status](https://travis-ci.org/mwittig/pimatic-milight-reloaded.svg?branch=master)](https://travis-ci.org/mwittig/pimatic-milight-reloaded)
[![Dependency Status](https://david-dm.org/mwittig/pimatic-milight-reloaded.svg)](https://david-dm.org/mwittig/pimatic-milight-reloaded)

A pimatic plugin to control Milight LED bulbs and OEM equivalents auch as Rocket LED, Limitless LED Applamp, 
Easybulb, s`luce, iLight, iBulb, and Kreuzer.

## Status of Implementation

Since the first release the following features have been implemented:
* Support for the Milight controller iBix1 and iBox2, including auto-discovery
* Improved auto-discovery supporting multi-homed hosts
* Support for bridge light of the iBox2 controller
* Milight color action to control color of MilightRGBWZone and MilightBridgeLight. Note, the action currently only 
  changes the hue value of the light. I can add brightness control, but unfortunately it is not possible to control 
  saturation which limits the color rendition, drastically
  
The next steps are to add actions to control color temperature and brightnessfor MilightWWCWZone and to add support for 
the new full color bulbs.

## Contributions

Contributions to the project are  welcome. You can simply fork the project and create a pull request with 
your contribution to start with. If you like this plugin, please consider &#x2605; starring 
[the project on github](https://github.com/mwittig/pimatic-milight-reloaded).

## Configuration

### Plugin Configuration

```json
{
	"plugin" : "milight-reloaded"
}
```

The plugin has the following configuration properties:

| Property          | Default  | Type    | Description                                 |
|:------------------|:---------|:--------|:--------------------------------------------|
| debug             | false    | Boolean | Debug mode. Writes debug messages to the pimatic log, if set to true |


### Device Configuration

It is suggested to use device discovery to choose the required device types from the 
list of discovered devices and to edit them with device editor.

#### MilightRGBWZone

MilightRGBWZone is used for the RGB-WW LED bulbs and strip controllers. 

```json
{
      "class": "MilightRGBWZone",
      "id": "milight-rgbw-zone-1",
      "name": "Milight RGBW Zone 1",
      "ip": "192.168.0.77",
      "bridgeVersion": "v6",
      "zoneId": 1
    }
```

The device has the following configuration properties:

| Property            | Default  | Type    | Description                                 |
|:--------------------|:---------|:--------|:--------------------------------------------|
| ip                  |          | String  | The IP address if the Wifi controller       |
| port                | 0        | Number  | The port of the Wifi controller. 0 will automatically select the appropriate port |
| bridgeVersion       | "legacy" | String  | The protocol version supported by the Wifi bridge: Use 'v6' for iBox1 & iBox2, or 'legacy' for older controllers |
| zoneId              | 0        | Number  | The Milight zone to control. 0 will control all zone if supported by the controller |
| delayBetweenCommands| 75 (100) | Number  | The delay time in ms to wait between transmissions, default 75ms. For 'v6' the minimum is 100ms |
| useTwoByteCommands  | true     | Boolean | Use 2-byte commands if true (default), otherwise use 3-byte commands. Only applicable for 'legacy' protocol |
| broadcast           | false    | Boolean | If true use IP broadcast mode, use unicast mode is used otherwise |

The following predicates and actions are supported:
* {device} is turned on|off
* switch {device} on|off
* toggle {device}
* dim {device} to {value}, where {Value} is the percentage of brightness (0-100)
* milight set color {device} to {value}

#### MilightWWCWZone

MilightWWCWZone is used for the WW-CW LED bulbs and strip controllers. 

```json
    {
      "class": "MilightWWCWZone",
      "id": "milight-wwcw-zone-2",
      "name": "Milight WWCW Zone 2",
      "ip": "192.168.0.77",
      "bridgeVersion": "v6",
      "zoneId": 2
    }
```

The device has the following configuration properties:

| Property            | Default  | Type    | Description                                 |
|:--------------------|:---------|:--------|:--------------------------------------------|
| ip                  |          | String  | The IP address if the Wifi controller       |
| port                | 0        | Number  | The port of the Wifi controller. 0 will automatically select the appropriate port |
| bridgeVersion       | "legacy" | String  | The protocol version supported by the Wifi bridge: Use 'v6' for iBox1 & iBox2, or 'legacy' for older controllers |
| zoneId              | 0        | Number  | The Milight zone to control. 0 will control all zone if supported by the controller |
| delayBetweenCommands| 75 (100) | Number  | The delay time in ms to wait between transmissions, default 75ms. For 'v6' the minimum is 100ms |
| useTwoByteCommands  | true     | Boolean | Use 2-byte commands if true (default), otherwise use 3-byte commands. Only applicable for 'legacy' protocol |
| broadcast           | false    | Boolean | If true use IP broadcast mode, use unicast mode is used otherwise |

The following predicates and actions are supported:
* {device} is turned on|off
* switch {device} on|off
* toggle {device}

#### MilightBridgeLight

MilightBridgeLight is used for the bridge light of the iBox2 controller. 

```json
    {
          "class": "MilightBridgeLight",
          "id": "milight-v6-bridge-light-1",
          "name": "Milight V6 Bridge Light",
          "ip": "192.168.0.77"
    }
```

The device has the following configuration properties:

| Property            | Default  | Type    | Description                                 |
|:--------------------|:---------|:--------|:--------------------------------------------|
| ip                  |          | String  | The IP address if the Wifi controller       |
| port                | 0        | Number  | The port of the Wifi controller. 0 will automatically select the appropriate port |
| delayBetweenCommands| 75 (100) | Number  | The delay time in ms to wait between transmissions, default 75ms. For 'v6' the minimum is 100ms |

The following predicates and actions are supported:
* {device} is turned on|off
* switch {device} on|off
* toggle {device}
* dim {device} to {value}, where {Value} is the percentage of brightness (0-100)
* milight set color {device} to {value}

## History

See [Release History](https://github.com/mwittig/pimatic-milight-reloaded/blob/master/HISTORY.md).

## License 

Copyright (c) 2015-2017, Marcus Wittig and contributors. All rights reserved.

[AGPL-3.0](https://github.com/mwittig/pimatic-milight-reloaded/blob/master/LICENSE)
