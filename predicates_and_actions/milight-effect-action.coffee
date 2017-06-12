module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  M = env.matcher
  commons = require('pimatic-plugin-commons')(env)

  class MilightEffectActionHandler extends env.actions.ActionHandler
    constructor: (@provider, @device, @action, @countTokens, @delayTokens, @modeTokens) ->
      @variableManager = @provider.framework.variableManager
      @base = commons.base @, 'MilightEffectActionHandler'
      super()

    setup: ->
      @dependOnDevice(@device)
      super()

    executeAction: (simulate) =>
      Promise.all([
        @variableManager.evaluateNumericExpression(@countTokens)
        @variableManager.evaluateNumericExpression(@delayTokens)
        @variableManager.evaluateNumericExpression(@modeTokens)
      ]).then (values) =>
        count = @base.normalize values[0], 1, 10
        delay = @base.normalize values[1], 0, 10000
        mode = @base.normalize values[2], 1, 9
        if @action is 'effectMode'
          @setModeAction mode, simulate
        else
          @setAction count, delay, simulate

    setAction: (count, delay, simulate) =>
      if simulate
        return Promise.resolve __("would perform milight set %s %s count %s delay %s",
          @action, @device.name, count, delay)
      else
        @device.setAction @action, count, delay
        return Promise.resolve __("milight set %s %s count %s delay %s",
          @action, @device.name, count, delay)

    setModeAction: (mode, simulate) =>
      if simulate
        return Promise.resolve __("would perform milight set %s %s mode %s",
          @action, @device.name, mode)
      else
        @device.effectMode mode
        return Promise.resolve __("milight set %s %s mode %s",
          @action, @device.name, mode)


  class MilightEffectActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->
      super()

    parseAction: (input, context) =>

      applicableMilightDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => _.includes [
          'MilightRGBWZone', 'MilightBridgeLight', 'MilightFullColorZone'
        ], device.config.class
      ).value()
      device = null
      color = null
      match = null
      variable = null

      action = 'effectMode'
      countTokens = [5]
      delayTokens = [1000]
      modeTokens = [1]

      # Try to match the input string with: set ->
      M(input, context)
      .match([
        'milight set effectMode '
        'milight set effectNext '
        'milight set effectFaster '
        'milight set effectSlower '
      ])
      .matchDevice applicableMilightDevices, (m, d) =>
        # Already had a match with another device?
        if device? and device.id isnt d.id
          context?.addError(""""#{input.trim()}" is ambiguous.""")
          return
        device = d
        action = m.getFullMatch().split(' ')[2]

        unless _.includes(['effectMode'], action)
          next = m.match(' count ').matchNumericExpression (m, tokens) =>
            countTokens = tokens
          if next.hadMatch() then m = next

          next = m.match(' delay ').matchNumericExpression (m, tokens) =>
            delayTokens = tokens
          if next.hadMatch() then m = next
        else
          next = m.match(' mode ').matchNumericExpression (m, tokens) =>
            modeTokens = tokens
          if next.hadMatch() then m = next

        match = m.getFullMatch()

      if match?
        assert typeof match is "string"
        assert device?
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new MilightEffectActionHandler(@, device, action, countTokens, delayTokens, modeTokens)
        }
      else
        return null

  return MilightEffectActionProvider
