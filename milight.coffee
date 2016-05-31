# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the 
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code
module.exports = (env) ->

  t = env.require('decl-api').types
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'

  os = require 'os'
  commons = require('pimatic-plugin-commons')(env)
  Milight = require('node-milight-promise');


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
      env.logger.info("Milight plugin started")

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("MilightWWCWZone", {
        configDef: deviceConfigDef.MilightWWCWZone,
        createCallback: (config, lastState) => new MilightWWCWZone(config, lastState)
      })
      @framework.deviceManager.registerDeviceClass("MilightRGBWZone", {
        configDef: deviceConfigDef.MilightRGBWZone, 
        createCallback: (config, lastState) => new MilightRGBWZone(config, lastState)
      })

      @framework.deviceManager.on('discover', (eventData) =>
        interfaces = @listInterfaces()
        # ping all devices in each net:
        interfaces.forEach( (iface, ifNum) =>
          base = iface.address.match(/([0-9]+\.[0-9]+\.[0-9]+\.)[0-9]+/)[1]

          @framework.deviceManager.discoverMessage(
            'pimatic-milight-reloaded', "Scanning #{base}0/24"
          )

          Milight.discoverBridges().then (devices) =>
            x = 0
            for device in devices
              displayName = 'Milight WWCW Zone'
              config = _.cloneDeep
                class: 'MilightWWCWZone'
                id: "#{displayName.toLowerCase()}-#{x++}"
                name:  "#{displayName}@#{device.ip}".replace(/\./g, '-')
                ip: device.ip

              @framework.deviceManager.discoveredDevice(
                'pimatic-milight-reloaded', "#{config.name}", config
              )

              displayName = 'Milight RGBW Zone'
              config = _.cloneDeep
                class: 'MilightRGBWZone'
                id: "#{displayName.toLowerCase()}-#{x++}"
                name:  "#{displayName}@#{device.ip}".replace(/\./g, '-')
                ip: device.ip

              @framework.deviceManager.discoveredDevice(
                'pimatic-milight-reloaded', "#{config.name}", config
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

  class MilightWWCWZone extends env.devices.SwitchActuator
    template: 'milight-cwww'

    constructor: (@config, lastState) ->
      @debug = milightPlugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @zoneId = @config.zoneId
      @actions = _.cloneDeep @actions
      @actions.brightnessUp =
        description: "Increases brightness"
        params: {}
      @actions.brightnessDown =
        description: "Decreases brightness"
        params: {}
      @actions.cooler =
        description: "Increases color temperature"
        params: {}
      @actions.warmer =
        description: "Decreases color temperature"
        params: {}
      @light = new Milight.MilightController
        host: @config.ip
        port: @config.port
        broadcast: @config.broadcast ? undefined
        delayBetweenCommands: @config.delayBetweenCommands
        commandRepeat: @config.commandRepeat
      @commands = if @config.useTwoByteCommands then Milight.commands2 else Milight.commands
      @_state = lastState?.state?.value or false
      @_previousState = null
      super()
      process.nextTick () =>
        @changeStateTo @_state

    destroy: () ->
      super()

    _onOffCommand: (newState, options = {}) ->
      commands = []
      if newState
        commands.push @commands.white.on @zoneId
      else
        commands.push @commands.white.off @zoneId
      @_previousState = newState
      @light.sendCommands commands

    changeStateTo: (state) ->
      @_setState state
      if state
        @_onOffCommand on
      else
        @_onOffCommand off

    brightnessUp: () ->
      @light.sendCommands @commands.white.brightUp()

    brightnessDown: () ->
      @light.sendCommands @commands.white.brightDown()

    warmer: () ->
      @light.sendCommands @commands.white.warmer()

    cooler: () ->
      @light.sendCommands @commands.white.cooler()


  class MilightRGBZone extends env.devices.DimmerActuator
    template: 'milight-rgb'

    constructor: (@config, lastState) ->
      @debug = milightPlugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @zoneId = @config.zoneId
      @addAttribute 'hue',
        description: "Hue value",
        type: t.number
      @actions = _.cloneDeep @actions
      @actions.changeHueTo =
        description: "Sets the hue value"
        params:
          hue:
            type: t.number
      @light = new Milight.MilightController
        host: @config.ipp
        port: @config.port
        broadcast: true
        delayBetweenCommands: @config.delayBetweenCommands
        commandRepeat: @config.commandRepeat
      @commands = if @config.useTwoByteCommands then Milight.commands2 else Milight.commands
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_state = unless @_dimlevel is 0 then true else false
      @_hue = lastState?.hue?.value or 0
      @_previousState = null
      super()
      process.nextTick () =>
        @changeStateTo @_state
        @changeHueTo @_hue
        @changeDimlevelTo @_dimlevel

    destroy: () ->
      @light.close()
      super()

    _onOffCommand: (newState, options = {}) ->
      commands = []
      if newState
        commands.push @commands.rgbw.on @zoneId
        unless newState is @_previousState
          commands.push @commands.rgbw.hue options.hue ? @_hue
          commands.push @commands.rgbw.brightness options.brightness ? @_dimlevel
        else
          if options.hue?
            commands.push @commands.rgbw.hue options.hue
          if options.brightness?
            commands.push @commands.rgbw.brightness options.brightness
      else
        commands.push @commands.rgbw.off @zoneId
      @_previousState = newState
      @light.sendCommands commands


    changeDimlevelTo: (dimlevel) ->
      @_setDimlevel dimlevel
      if dimlevel > 0
        @_onOffCommand on,
          brightness: dimlevel
      else
        @_onOffCommand off

    changeStateTo: (state) ->
      @_setState state
      if state
        @_onOffCommand on
      else
        @_onOffCommand off

    changeHueTo: (hue) ->
      @base.setAttribute "hue", hue
      if @_state
        @_onOffCommand on,
          hue: hue

    getHue: () ->
      Promise.resolve @_hue


  class MilightRGBWZone extends env.devices.DimmerActuator
    template: 'milight-rgbw'

    constructor: (@config, lastState) ->
      @debug = milightPlugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @zoneId = @config.zoneId
      @addAttribute 'hue',
        description: "Hue value",
        type: t.number
      @addAttribute 'white',
        description: "White mode",
        type: t.boolean
      @actions = _.cloneDeep @actions
      @actions.changeHueTo =
        description: "Sets the hue value"
        params:
          hue:
            type: t.number
      @actions.changeWhiteTo =
        description: "Switches between white and color mode"
        params:
          white:
            type: t.boolean
      @light = new Milight.MilightController
        host: @config.ipp
        port: @config.port
        broadcast: true
        delayBetweenCommands: @config.delayBetweenCommands
        commandRepeat: @config.commandRepeat
      @commands = if @config.useTwoByteCommands then Milight.commands2 else Milight.commands
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_state = unless @_dimlevel is 0 then true else false
      @_hue = lastState?.hue?.value or 0
      @_white = lastState?.white?.value or false
      @_previousState = null
      super()
      process.nextTick () =>
        @changeStateTo @_state
        @changeHueTo @_hue unless @_white
        @changeWhiteTo @_white if @_white
        @changeDimlevelTo @_dimlevel

    destroy: () ->
      @light.close()
      super()

    _onOffCommand: (newState, options = {}) ->
      commands = []
      if newState
        commands.push @commands.rgbw.on @zoneId unless options.white
        unless newState is @_previousState
          if options.white ? @_white
            commands.push @commands.rgbw.whiteMode @zoneId
          else
            commands.push @commands.rgbw.hue options.hue ? @_hue
          commands.push @commands.rgbw.brightness options.dimlevel ? @_dimlevel
        else
          if options.white
            commands.push @commands.rgbw.whiteMode @zoneId
            commands.push @commands.rgbw.brightness options.dimlevel ? @_dimlevel
          else if options.hue?
            commands.push @commands.rgbw.hue options.hue
          if options.brightness?
            commands.push @commands.rgbw.brightness options.brightness
      else
        commands.push @commands.rgbw.off @zoneId
      @_previousState = newState
      @light.sendCommands commands


    changeDimlevelTo: (dimlevel) ->
      @_setDimlevel dimlevel
      if dimlevel > 0
        @_onOffCommand on,
          brightness: dimlevel
      else
        @_onOffCommand off

    changeStateTo: (state) ->
      @_setState state
      if state
        @_onOffCommand on
      else
        @_onOffCommand off

    changeHueTo: (hue) ->
      changeFromWhite = @_white
      @base.setAttribute "white", false
      @base.setAttribute "hue", hue
      if @_state
        @_onOffCommand on,
          hue: hue
          brightness: @_dimlevel if changeFromWhite

    getHue: () ->
      Promise.resolve @_hue

    changeWhiteTo: (white) ->
      changeFromHue = white and not @_white
      @base.setAttribute "white", white
      @base.setAttribute "hue", 256
      if changeFromHue
        if @_state
          @_onOffCommand on,
            white: white
            brightness: @_dimlevel
      else if not white
        @_onOffCommand on,
          hue: @_hue
          brightness: @_dimlevel

    getWhite: () ->
      Promise.resolve @_white


  # ###Finally
  # Create a instance of my plugin
  milightPlugin = new MilightPlugin
  # and return it to the framework.
  return milightPlugin