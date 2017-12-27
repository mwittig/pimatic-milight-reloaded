module.exports = (env) ->

  assert = env.require 'cassert'
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  t = env.require('decl-api').types
  commons = require('pimatic-plugin-commons')(env)
  MilightFullColorZone = require('./milight-full-color-zone')(env)

  class Milight8ChannelFullColorZone extends MilightFullColorZone
    template: 'milight-rgbw'

    constructor: (@config, plugin, lastState) ->
      @debug = plugin.config.debug ? false
      @base = commons.base @, @config.class

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
      super @config, plugin, lastState
      @cmd = @commands.fullColor8Zone

    destroy: () ->
      super()