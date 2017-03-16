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
      @intervalTimers = []

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
      @intervalTimers.forEach (element, index) =>
        clearInterval element
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

    setAction: (action, repeat, delay) ->
      assert not isNaN repeat
      assert not isNaN delay
      @base.debug "white action requested: #{action} repeat #{repeat} delay #{delay}"
      intervalId = null
      
      command = () =>
        @base.debug "action (#{repeat})"
        @[action]()
        repeat -= 1
        if repeat is 0 and intervalId?
          clearInterval intervalId 
          @intervalTimers.forEach (element, index) =>
            if _.isEqual(intervalId, element)
              @intervalTimers.splice index, 1
          @base.debug "finished"

      command()
      unless repeat is 0
        intervalId = setInterval command, delay
        @intervalTimers.push intervalId

