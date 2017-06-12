module.exports = (env) ->

  assert = env.require 'cassert'
  t = env.require('decl-api').types
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  Milight = require 'node-milight-promise'

  class MilightWWCWZone extends env.devices.SwitchActuator
    template: 'milight-cwww'

    constructor: (@config, plugin, lastState) ->
      @debug = plugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @isVersion6 = @config.bridgeVersion is 'v6'
      @zoneId = @config.zoneId
      @actions = _.cloneDeep @actions
      @actions.brighter =
        description: "Increases brightness"
        params: {}
      @actions.darker =
        description: "Decreases brightness"
        params: {}
      @actions.cooler =
        description: "Increases color temperature"
        params: {}
      @actions.warmer =
        description: "Decreases color temperature"
        params: {}
      @actions.nightMode =
        description: "Enables the night mode"
        params: {}
      @actions.maxBright =
        description: "Sets brightness to maximum"
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
        port: @config.port
        type: @config.bridgeVersion
        broadcast: @config.broadcast ? undefined
        delayBetweenCommands: delayBetweenCommands
        commandRepeat: @config.commandRepeat

      @commands = if @config.useTwoByteCommands then Milight.commands2 else Milight.commands
      if @isVersion6
        @commands = Milight.commandsV6
      @_state = lastState?.state?.value or false
      @_previousState = null
      super()
      process.nextTick () =>
        @changeStateTo @_state

    destroy: () ->
      @light.close()
      commons.clearAllPeriodicTimers()
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

    brighter: () ->
      @light.sendCommands @commands.white.brightUp @zoneId

    darker: () ->
      @light.sendCommands @commands.white.brightDown @zoneId

    warmer: () ->
      @light.sendCommands @commands.white.warmer @zoneId

    cooler: () ->
      @light.sendCommands @commands.white.cooler @zoneId

    nightMode: () ->
      @light.sendCommands @commands.white.nightMode @zoneId

    maxBright: () ->
      @light.sendCommands @commands.white.maxBright @zoneId

    effectMode: (mode) ->
      if @isVersion6
        @light.sendCommands @commands.white.effectMode @zoneId, mode
      else
        @base.error "effectMode command not supported by legacy Milight controller"

    effectNext: () ->
      @light.sendCommands @commands.white.effectModeNext @zoneId

    effectFaster: () ->
      @light.sendCommands @commands.white.effectSpeedUp @zoneId

    effectSlower: () ->
      @light.sendCommands @commands.white.effectSpeedDown @zoneId

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
