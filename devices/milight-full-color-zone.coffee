
module.exports = (env) ->

  t = env.require('decl-api').types
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)
  Milight = require 'node-milight-promise'
  MilightRGBWZone = require('./milight-rgbwzone')(env)

  class MilightFullColorZone extends MilightRGBWZone
    template: 'milight-rgbw'

    constructor: (@config, plugin, lastState) ->
      @debug = plugin.config.debug ? false
      @base = commons.base @, @config.class

      @name = @config.name
      @id = @config.id
      @isVersion6 = true
      @zoneId = @config.zoneId
      super @config, plugin, lastState, true

    destroy: () ->
      @light.close()
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
