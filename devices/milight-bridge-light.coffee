
module.exports = (env) ->

  assert = env.require 'cassert'
  t = env.require('decl-api').types
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  Milight = require 'node-milight-promise'
  MilightRGBWZone = require('./milight-rgbwzone')(env)

  class MilightBridgeLight extends MilightRGBWZone
    template: 'milight-rgbw'

    constructor: (@config, plugin, lastState) ->
      @debug = plugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @isVersion6 = true
      @actions = _.cloneDeep @actions
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
      super @config, plugin, lastState, true

    destroy: () ->
      @light.close()
      commons.clearAllPeriodicTimers()
      super()

    _onOffCommand: (newState, options = {}) ->
      commands = []
      if newState
        commands.push @commands.bridge.on() unless options.white
        unless newState is @_previousState
          if options.white ? @_white
            commands.push @commands.bridge.whiteMode()
          else
            commands.push @commands.bridge.hue options.hue ? @_hue, true
          commands.push @commands.bridge.brightness options.dimlevel ? @_dimlevel
        else
          if options.white
            commands.push @commands.bridge.whiteMode()
            commands.push @commands.bridge.brightness options.dimlevel ? @_dimlevel
          else if options.hue?
            commands.push @commands.bridge.hue options.hue, true
          if options.brightness?
            commands.push @commands.bridge.brightness options.brightness
      else
        commands.push @commands.bridge.off()
      @_previousState = newState
      @light.sendCommands commands

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
      #@light.sendCommands @commands.bridge.nightMode()
      # as nightMode does not seem to work for bridge light we need to emulate it
      @changeStateTo true
      @light.sendCommands [@commands.bridge.whiteMode true, @commands.bridge.brightness 1]

    effectMode: (mode) ->
      @changeStateTo true
      @light.sendCommands @commands.bridge.effectMode mode

    effectNext: () ->
      @changeStateTo true
      @light.sendCommands @commands.bridge.effectModeNext()

    effectFaster: () ->
      @light.sendCommands @commands.bridge.effectSpeedUp()

    effectSlower: () ->
      @light.sendCommands @commands.bridge.effectSpeedDown()

    blink: () ->
      @toggle();

    setAction: (action, count, delay) ->
      assert not isNaN count
      assert not isNaN delay
      @base.debug "action requested: #{action} count #{count} delay #{delay}"
      intervalId = null
      count = count *2 if action is "blink"

      command = () =>
        @base.debug "action (#{count}) - #{new Date().valueOf()}"
        @[action]()
        count -= 1
        if count is 0 and intervalId?
          commons.clearPeriodicTimer intervalId
          @base.debug "finished"

      intervalId = commons.setPeriodicTimer command, delay
