deviceConfigTemplates =
  "MilightWWCWZone":
    name: "Milight WWCW Zone"
    class: "MilightWWCWZone"
  "MilightRGBWZone":
    name: "Milight RGBW Zone"
    class: "MilightRGBWZone"
  "MilightBridgeLight":
    name: "Milight V6 Bridge Light"
    class: "MilightBridgeLight"
    v6: true
  "MilightFullColorZone":
    name: "Milight V6 Full Color Zone"
    class: "MilightFullColorZone"
    v6: true
  "Milight8ChannelFullColorZone":
    name: "Milight V6 Full Color 8-channel Zone"
    class: "Milight8ChannelFullColorZone"
    v6: true

actionProviders = [
  'milight-color-action'
  'milight-white-action'
  'milight-effect-action'
  'milight-blink-action'
]

# ##The plugin code
module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  uniqBy = require 'lodash.uniqby'

  os = require 'os'
  commons = require('pimatic-plugin-commons')(env)
  Milight = require 'node-milight-promise'

  # ###MilightPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class MilightPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      @base = commons.base @, 'Plugin'
      @base.info("Milight plugin started")

      deviceConfigDef = require("./device-config-schema")
      for own templateName of deviceConfigTemplates
        do (templateName) =>
          device = deviceConfigTemplates[templateName]
          className = device.class
          # convert camel-case classname to kebap-case filename
          filename = className.replace(/([a-z])([0-9]|[A-Z])/g, '$1-$2').toLowerCase()
          classType = require('./devices/' + filename)(env)
          @base.debug "Registering device class #{className}"
          @framework.deviceManager.registerDeviceClass(className, {
            configDef: deviceConfigDef[className],
            createCallback: (config, lastState) =>
              return new classType(config, @, lastState)
          })

      for provider in actionProviders
        className = provider.replace(/(^[a-z])|(\-[a-z])/g, ($1) -> $1.toUpperCase().replace('-','')) + 'Provider'
        classType = require('./predicates_and_actions/' + provider)(env)
        @base.debug "Registering action provider #{className}"
        @framework.ruleManager.addActionProvider(new classType @framework)

      @framework.deviceManager.on('discover', (eventData) =>
        interfaces = @listInterfaces()
        # ping all devices in each net:
        discoveryActions = []
        interfaces.forEach( (iface, ifNum) =>
          base = iface.address.match(/([0-9]+\.[0-9]+\.[0-9]+\.)[0-9]+/)[1]

          @framework.deviceManager.discoverMessage(
            'pimatic-milight-reloaded', "Scanning #{base}0/24"
          )

          discoveryActions.push Milight.discoverBridges(
            address: "#{base}255"
            type: 'all'
          )
        )

        Promise.all(discoveryActions).then((values) =>
          devices =  uniqBy _.flatten(values), 'ip'
          for device in devices
            for own templateName of deviceConfigTemplates
              configTemplate = deviceConfigTemplates[templateName]
              id = @generateDeviceId "#{configTemplate.name.toLowerCase().replace(/\s/g, '-')}"
              if id? and (not configTemplate.v6? or device.type is 'v6')
                config = _.cloneDeep
                  class: configTemplate.class
                  id: id
                  name:  "#{configTemplate.name}"
                  ip: device.ip
                  bridgeVersion: device.type if not configTemplate.v6?

                @framework.deviceManager.discoveredDevice(
                  'pimatic-milight-reloaded', "#{config.name} (#{config.bridgeVersion ? 'v6'}),#{config.ip}", config
                )
        )
      )

      @framework.on "after init", =>
        # Check if the mobile-frontend was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', 'pimatic-milight-reloaded/app/milight.coffee'
          mobileFrontend.registerAssetFile 'css', 'pimatic-milight-reloaded/app/milight.css'
          mobileFrontend.registerAssetFile 'html', 'pimatic-milight-reloaded/app/milight.html'
          mobileFrontend.registerAssetFile 'js', 'pimatic-milight-reloaded/app/vendor/async.js'
        else
          env.logger.warn 'Plugin could not find the mobile-frontend. No GUI will be available'

    generateDeviceId: (prefix) ->
      for x in [1...1000]
        result = "#{prefix}-#{x}"
        matched = @framework.deviceManager.devicesConfig.some (element, iterator) ->
          element.id is result
        return result if not matched

    # get all ip4 non local networks with /24 submask
    listInterfaces: () ->
      interfaces = []
      ifaces = os.networkInterfaces()
      Object.keys(ifaces).forEach( (ifname) ->
        alias = 0
        ifaces[ifname].forEach (iface) ->
          if 'IPv4' isnt iface.family or iface.internal isnt false
            # skip over internal (i.e. 127.0.0.1) and non-ipv4 addresses
            return
          if iface.netmask isnt "255.255.255.0"
            return
          interfaces.push {name: ifname, address: iface.address}
        return
      )
      if interfaces.length is 0
        # fallback to global broadcast
        interfaces.push {name: '255.255.255.255/32', address: "255.255.255.255"}
      return interfaces


  # ###Finally
  # Create a instance of my plugin
  milightPlugin = new MilightPlugin
  # and return it to the framework.
  return milightPlugin