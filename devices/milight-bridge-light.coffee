
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

    nightMode: () ->
      #@light.sendCommands @commands.bridge.nightMode()
      # as nightMode does not seem to work for bridge light we need to emulate it
      @light.sendCommands @commands.bridge.whiteMode()
      @light.sendCommands @commands.bridge.brightness 1

    effectMode: (mode) ->
      @light.sendCommands @commands.bridge.effectMode mode

    effectNext: () ->
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
