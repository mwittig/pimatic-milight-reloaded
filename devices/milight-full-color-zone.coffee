module.exports = (env) ->

  assert = env.require 'cassert'
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  t = env.require('decl-api').types
  commons = require('pimatic-plugin-commons')(env)
  MilightRGBWZone = require('./milight-rgbwzone')(env)
  Milight = require 'node-milight-promise'

  class MilightFullColorZone extends MilightRGBWZone
    template: 'milight-rgbw'

    constructor: (@config, plugin, lastState) ->
      @debug = plugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @isVersion6 = true
      @zoneId = @config.zoneId
      @addAttribute 'saturation',
        description: "Saturation value",
        type: t.number
      @actions = _.cloneDeep @actions
      @actions.changeSaturationTo =
        description: "Sets the saturation value"
        params:
          hue:
            type: t.number
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

      @_saturation = lastState?.saturation?.value or 0
      super @config, plugin, lastState, true

    destroy: () ->
      @light.close()
      commons.clearAllPeriodicTimers()
      super()

    _onOffCommand: (newState, options = {}) ->
      commands = []
      if newState
        commands.push @commands.fullColor.on @zoneId unless options.white
        unless newState is @_previousState
          if options.white ? @_white
            commands.push @commands.fullColor.whiteMode @zoneId
          else
            commands.push @commands.fullColor.hue @zoneId, options.hue ? @_hue, true
            commands.push @commands.fullColor.saturation @zoneId, 0
          commands.push @commands.fullColor.brightness @zoneId, options.dimlevel ? @_dimlevel
          if options.brightness?
            commands.push @commands.fullColor.brightness @zoneId, options.brightness
        else
          if options.white
            commands.push @commands.fullColor.whiteMode @zoneId
            commands.push @commands.fullColor.brightness @zoneId, options.dimlevel ? @_dimlevel
          else if options.hue?
            commands.push @commands.fullColor.hue @zoneId, options.hue, true
            commands.push @commands.fullColor.saturation @zoneId, 0
          if options.brightness?
            commands.push @commands.fullColor.brightness @zoneId, options.brightness
      else
        commands.push @commands.fullColor.off @zoneId
      @_previousState = newState
      @light.sendCommands commands

    changeSaturationTo: (saturation) ->
      @base.setAttribute "saturation", saturation
      if @_state
        @_onOffCommand on,
          saturation: saturation

    getSaturation: () ->
      Promise.resolve @_saturation

    setColor: (color) ->
      @base.debug "color change requested to: #{color}"
      rgb = @_hexStringToRgb color
      @base.debug "RGB", rgb
      if _.isEqual rgb, [255,255,255]
        @base.debug "setting white mode"
        @changeWhiteTo true
      else
        hsv = Milight.helper.rgbToHsv.apply Milight.helper, rgb
        @base.debug "setting color to HSV: #{hsv}"
        hsv[0] = (256 + 176 - Math.floor(Number(hsv[0]) / 360.0 * 255.0)) % 256;
        @base.debug "setting color to HSV: #{hsv}"
        @base.setAttribute "white", false
        @base.setAttribute "hue", hsv[0]
        @base.setAttribute "saturation", hsv[1]
        @_setDimlevel hsv[2]

        if @_state
          @_onOffCommand on,
            white: false
            hue: hsv[0]
            saturation: hsv[1]
            dimlevel: hsv[2]

    nightMode: () ->
      @light.sendCommands @commands.fullColor.nightMode @zoneId

    effectMode: (mode) ->
      @light.sendCommands @commands.fullColor.effectMode @zoneId, mode

    effectNext: () ->
      @light.sendCommands @commands.fullColor.effectModeNext @zoneId

    effectFaster: () ->
      @light.sendCommands @commands.fullColor.effectSpeedUp @zoneId

    effectSlower: () ->
      @light.sendCommands @commands.fullColor.effectSpeedDown @zoneId

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