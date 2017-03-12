module.exports = (env) ->

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
      @light.sendCommands @commands.white.brightUp @zoneId

    brightnessDown: () ->
      @light.sendCommands @commands.white.brightDown @zoneId

    warmer: () ->
      @light.sendCommands @commands.white.warmer @zoneId

    cooler: () ->
      @light.sendCommands @commands.white.cooler @zoneId

