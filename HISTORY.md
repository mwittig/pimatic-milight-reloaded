# Release History

* 20171230, V0.9.17
    * Fixed state handling on device initialization to avoid zone being switched on if it was switched off, issue #17
* 20171228, V0.9.16
    * Fixed RGBW hue attribute set to invalid value, issue #19
* 20171227, V0.9.15
    * Added support for the 8-channel remote control which can manage up to 8-zones
    * Added support for rgb() color action parameter to pass color given as three decimal RGB values
* 20170719, V0.9.14
    * Effect mode, night mode, color, and white mode actions now automatically turn the light on.
    * Fixture of chamgeDimlevelTo/changeStateTo - reverted to standard behaviour to make it consistent with the 
      default behaviour in pimatic, i.e. turning the dimmer on will set it 100%
    * Added 'keepDimlevel' device configuration property. This can used to activate the old behavior, i.e. 
      turning the dimmer on will set it to the previously set dimlevel if greater than 0
    * Updated to node-milight-promise@0.2.2 to include bug fixes in the base driver
* 20170715, V0.9.13
    * Fixed state change event not being triggered for devices based on DimmerActuator, issue #12
* 20170715, V0.9.12
    * Various bug fixes for RGBW and FullColor setColor method
* 20170715, V0.9.11
    * Updated to node-milight-promise@0.2.1 to enable proper synchronization across multiple devices
* 20170615, V0.9.10
    * Added nightMode action for MilightBridgeLight, MilightRGBWZone, and MilightFullColorZone
* 20170612, V0.9.9
    * Fixed dim behaviour when dim level is 0, issue #10
* 20170612, V0.9.8
    * Added actions for effect mode support for MilightBridgeLight, MilightRGBWZone, and MilightFullColorZone
    * Updated dependencies 
* 20170501, V0.9.7
    * Implemented blink action to let the lights flash for given number of times
    * Updated dependencies
* 20170318, V0.9.6
    * Implemented basic support for V6 full color bulbs (color temperature and saturation missing to date)
    * Implemented actions to control white color temperature and brightness for MilightWWCWZone
    * Improved MilightBridgeLight implementation
    * Changed UI for WW/CW color temperature: swapped functions linked to plus and minus buttons
    * Added Language localization support for WW/CW power switch
* 20170312, V0.9.5
    * Fixed packaging
* 20170312, V0.9.4
    * Implemented basic support for new Milight iBox Wifi controller which use the new V6 protocol
    * Implemented device type MilightBridgeLight to support the light integrated into iBox2
    * Implemented milight color action for MilightRGBWZone and MilightBridgeLight
    * Updated dependencies
    * Refactoring and cleanup
    * Revised README
    * Updated Travis CI build descriptor
* 20160601, V0.9.3
    * Improved device discovery
* 20160601, V0.9.2
    * Fixed setting of broadcast options property for MilightRGBWZone and MilightRGBZone
    * Added broadcast property for MilightWWCWZone to schema
* 20160601, V0.9.1
    * Fixed setting of ip options property     
* 20160601, V0.9.0
    * Initial Release