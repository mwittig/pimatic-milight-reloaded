# Release History

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