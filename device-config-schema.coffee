module.exports = {
  title: "Milight device config schemas"
  MilightRGBWZone: {
    title: "Milight RGBW Zone configuration"
    type: "object"
    properties:
      ip: 
        description: "The IP address of the Milight bridge"
        type: "string"
        default: "255.255.255.255"
      port:
        description: "The port of the Milight bridge (0 = automatically select default port)"
        type: "integer"
        default: 0
      zoneId:
        description: "The zone to be controlled, [1-4] and 0 for all zones"
        enum: [0, 1, 2, 3, 4]
        default: 1
      bridgeVersion:
        description: "The version of the bridge controller, 'v6' for version 6, and 'legacy' for earlier versions (default)"
        enum: ['legacy', 'v6']
        default: 'legacy'
      commandRepeat:
        description: "The number of transmissions sent to the bridge for a command [1-3], default 1"
        enum: [1, 2, 3]
        default: 1
      delayBetweenCommands:
        description: "The delay time in ms to wait between transmissions, default 75ms"
        type: "integer"
        enum: [75, 100, 125, 150]
        default: 75
      useTwoByteCommands:
        description: "Use 2-byte commands if true (default), otherwise use 3-byte commands"
        type: "boolean"
        default: true
      broadcast:
        description: "If true use IP broadcast mode, unicast mode is used otherwise"
        type: "boolean"
        default: false
      keepDimlevel:
        description: "If true turning on will set the previous dimlevel, otherwise the dimlevel is set to 100"
        type: "boolean"
        default: false
  }
  MilightWWCWZone: {
    title: "Milight WWCW Zone configuration"
    type: "object"
    properties:
      ip:
        description: "The IP address of the Milight bridge"
        type: "string"
        default: "255.255.255.255"
      port:
        description: "The port of the Milight bridge (0 = automatically select default port)"
        type: "integer"
        default: 0
      zoneId:
        description: "The zone to be controlled, [1-4] and 0 for all zones"
        enum: [0, 1, 2, 3, 4]
        default: 1
      bridgeVersion:
        description: "The version of the bridge controller, 'v6' for version 6, and 'legacy' for earlier versions (default)"
        enum: ['legacy', 'v6']
        default: 'legacy'
      commandRepeat:
        description: "The number of transmissions sent to the bridge for a command [1-3], default 1"
        enum: [1, 2, 3]
        default: 1
      delayBetweenCommands:
        description: "The delay time in ms to wait between transmissions, default 75ms"
        type: "integer"
        enum: [75, 100, 125, 150]
        default: 75
      useTwoByteCommands:
        description: "Use 2-byte commands if true (default), otherwise use 3-byte commands"
        type: "boolean"
        default: true
      broadcast:
        description: "If true use IP broadcast mode, unicast mode is used otherwise"
        type: "boolean"
        default: false
  }
  MilightBridgeLight: {
    title: "Milight V6 Bridge Light configuration"
    type: "object"
    properties:
      ip:
        description: "The IP address of the Milight bridge"
        type: "string"
        default: "255.255.255.255"
      port:
        description: "The port of the Milight bridge (0 = automatically select default port)"
        type: "integer"
        default: 0
      delayBetweenCommands:
        description: "The delay time in ms to wait between transmissions, default 75ms"
        type: "integer"
        enum: [75, 100, 125, 150]
        default: 75
      keepDimlevel:
        description: "If true turning on will set the previous dimlevel, otherwise the dimlevel is set to 100"
        type: "boolean"
        default: false
  }
  MilightFullColorZone: {
    title: "Milight V6 Full Color (RGB WW/CW Light configuration"
    type: "object"
    properties:
      ip:
        description: "The IP address of the Milight bridge"
        type: "string"
        default: "255.255.255.255"
      port:
        description: "The port of the Milight bridge (0 = automatically select default port)"
        type: "integer"
        default: 0
      zoneId:
        description: "The zone to be controlled, [1-4] and 0 for all zones"
        enum: [0, 1, 2, 3, 4]
        default: 1
      delayBetweenCommands:
        description: "The delay time in ms to wait between transmissions, default 75ms"
        type: "integer"
        enum: [75, 100, 125, 150]
        default: 75
      keepDimlevel:
        description: "If true turning on will set the previous dimlevel, otherwise the dimlevel is set to 100"
        type: "boolean"
        default: false
  }
  Milight8ChannelFullColorZone: {
    title: "Milight V6 Full Color with 8-channel controller configuration"
    type: "object"
    properties:
      ip:
        description: "The IP address of the Milight bridge"
        type: "string"
        default: "255.255.255.255"
      port:
        description: "The port of the Milight bridge (0 = automatically select default port)"
        type: "integer"
        default: 0
      zoneId:
        description: "The zone to be controlled, [1-8] and 0 for all zones"
        enum: [0, 1, 2, 3, 4, 5, 6, 7, 8]
        default: 1
      delayBetweenCommands:
        description: "The delay time in ms to wait between transmissions, default 75ms"
        type: "integer"
        enum: [75, 100, 125, 150]
        default: 75
      keepDimlevel:
        description: "If true turning on will set the previous dimlevel, otherwise the dimlevel is set to 100"
        type: "boolean"
        default: false
  }
}