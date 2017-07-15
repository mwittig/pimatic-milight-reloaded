module.exports = (env) ->

  assert = env.require 'cassert'
  t = env.require('decl-api').types
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  Milight = require 'node-milight-promise'

  class MilightRGBWZone extends env.devices.DimmerActuator
    template: 'milight-rgbw'

    constructor: (@config, plugin, lastState, v6 = false) ->
      @debug = plugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @isVersion6 = v6 or @config.bridgeVersion is 'v6'
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
      @actions.setColor =
        description: 'set a light color'
        params:
          colorCode:
            type: t.string
      @actions.nightMode =
        description: "Enables the night mode"
        params: {}
      @actions.effectMode =
        description: "Set effect mode"
        params:
          mode:
            type: t.number
      @actions.effectNext =
        description: "Switch to next effect mode"
        params: {}
      @actions.effectFaster =
        description: "Increase effect speed"
        params: {}
      @actions.effectSlower =
        description: "Decrease effect speed"
        params: {}
      delayBetweenCommands = @config.delayBetweenCommands
      if @isVersion6
        delayBetweenCommands = @base.normalize delayBetweenCommands, 100
      @light = new Milight.MilightController
        ip: @config.ip
        port: @config.port if @config.port > 0
        type: if @isVersion6 then 'v6' else 'legacy'
        broadcast: @config.broadcast ? undefined
        delayBetweenCommands: delayBetweenCommands
        commandRepeat: @config.commandRepeat

      @commands = if @config.useTwoByteCommands then Milight.commands2 else Milight.commands
      if @isVersion6
        @commands = Milight.commandsV6
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
      commons.clearAllPeriodicTimers()
      super()

    _onOffCommand: (newState, options = {}) ->
      commands = []
      if newState
        commands.push @commands.rgbw.on @zoneId unless options.white
        if @isVersion6 then (
          unless newState is @_previousState
            if options.white ? @_white
              commands.push @commands.rgbw.whiteMode @zoneId
            else
              commands.push @zoneId, @commands.rgbw.hue options.hue ? @_hue, true
            commands.push @commands.rgbw.brightness @zoneId, options.dimlevel ? @_dimlevel
          else
            if options.white
              commands.push @commands.rgbw.whiteMode @zoneId
              commands.push @commands.rgbw.brightness @zoneId, options.dimlevel ? @_dimlevel
            else if options.hue?
              commands.push @commands.rgbw.hue @zoneId, options.hue, true
            if options.brightness?
              commands.push @commands.rgbw.brightness @zoneId, options.brightness
        )
        else (
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
        )
      else
        commands.push @commands.rgbw.off @zoneId
      @_previousState = newState
      @light.sendCommands commands

    _hexStringToRgb: (hexString) ->
      hexString = hexString.replace /#/, ''
      if hexString.length is 6
        [
          parseInt(hexString.slice(0,2), 16)
          parseInt(hexString.slice(2,4), 16)
          parseInt(hexString.slice(4,6), 16)
        ]
      else
        throw new Error("Bad color hex string")

    changeDimlevelTo: (dimlevel) ->
      if dimlevel > 0
        @_setDimlevel dimlevel
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
      if @_state
        @_onOffCommand on,
          white: white
          brightness: @_dimlevel if changeFromHue
      else if not white
        @_onOffCommand on,
          hue: @_hue
          brightness: @_dimlevel

    getWhite: () ->
      Promise.resolve @_white

    setColor: (color) ->
      @base.debug "color change requested to: #{color}"
      rgb = @_hexStringToRgb color
      @base.debug "RGB:", rgb
      if _.isEqual rgb, [255,255,255]
        @base.debug "setting white mode"
        @changeWhiteTo true
      else
        hue = Milight.helper.rgbToHue.apply Milight.helper, rgb
        @base.debug "setting hue to: #{hue}"
        @changeHueTo hue

    nightMode: () ->
      @light.sendCommands @commands.rgbw.nightMode @zoneId

    effectMode: (mode) ->
      if @isVersion6
        @light.sendCommands @commands.rgbw.effectMode @zoneId, mode
      else
        @base.error "effectMode command not supported by legacy Milight controller"

    effectNext: () ->
      @light.sendCommands @commands.rgbw.effectModeNext @zoneId

    effectFaster: () ->
      @light.sendCommands @commands.rgbw.effectSpeedUp @zoneId

    effectSlower: () ->
      @light.sendCommands @commands.rgbw.effectSpeedDown @zoneId

    blink: () ->
      @toggle();

    setAction: (action, count, delay) ->
      assert not isNaN count
      assert not isNaN delay
      @base.debug "action requested: #{action} count #{count} delay #{delay}"
      intervalId = null
      count = count *2 if action is "blink"

      command = () =>
        @base.debug "action (#{count})"
        @[action]()
        count -= 1
        if count is 0 and intervalId?
          commons.clearPeriodicTimer intervalId
          @base.debug "finished"

      intervalId = commons.setPeriodicTimer command, delay