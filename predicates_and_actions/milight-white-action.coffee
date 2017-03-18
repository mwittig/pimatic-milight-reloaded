module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  M = env.matcher
  commons = require('pimatic-plugin-commons')(env)

  class MilightWhiteActionHandler extends env.actions.ActionHandler
    constructor: (@provider, @device, @action, @timesExecuteTokens, @delayTokens) ->
      @variableManager = @provider.framework.variableManager
      @base = commons.base @, 'MilightWhiteActionHandler'
      super()

    setup: ->
      @dependOnDevice(@device)
      super()

    executeAction: (simulate) =>
      Promise.all([
        @variableManager.evaluateNumericExpression(@timesExecuteTokens)
        @variableManager.evaluateNumericExpression(@delayTokens)
      ]).then (values) =>
        timesExecute = @base.normalize values[0], 1, 10
        delay = @base.normalize values[1], 0, 10000
        @setAction timesExecute, delay, simulate

    setAction: (timesExecute, delay, simulate) =>
      if simulate
        return Promise.resolve __("would perform milight set white %s %s timesExecute %s delay %s",
          @action, @device.name, timesExecute, delay)
      else
        @device.setAction @action, timesExecute, delay
        return Promise.resolve __("milight set %s %s timesExecute %s delay %s",
          @action, @device.name, timesExecute, delay)


  class MilightWhiteColorTempActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->
      super()

    parseAction: (input, context) =>
      applicableMilightDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => _.includes [
          'MilightWWCWZone'
        ], device.config.class
      ).value()
      device = null
      color = null
      match = null
      variable = null

      action = 'cooler'
      timesExecuteTokens = [1]
      delayTokens = [0]

      # Try to match the input string with: set ->
      M(input, context)
        .match([
          'milight set warmer '
          'milight set cooler '
          'milight set brighter '
          'milight set darker '
          'milight set nightMode '
          'milight set maxBright '
        ])
        .matchDevice applicableMilightDevices, (m, d) =>
          # Already had a match with another device?
          if device? and device.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return
          device = d
          action = m.getFullMatch().split(' ')[2]

          unless _.includes(['nightMode', 'maxBright'], action)
            next = m.match(' execute ').matchNumericExpression (m, tokens) =>
              timesExecuteTokens = tokens
            if next.hadMatch() then m = next

            next = m.match(' delay ').matchNumericExpression (m, tokens) =>
              delayTokens = tokens
            if next.hadMatch() then m = next

          match = m.getFullMatch()

      if match?
        assert typeof match is "string"
        assert device?
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new MilightWhiteActionHandler(@, device, action, timesExecuteTokens, delayTokens)
        }
      else
        return null

  return MilightWhiteColorTempActionProvider