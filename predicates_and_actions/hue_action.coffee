module.exports = (env) ->

  Promise = env.require 'bluebird'

  assert = require 'cassert'
  _ = require 'lodash'
  M = env.matcher

  #color_schema = require '../color_schema'

  class HueActionHandler extends env.actions.ActionHandler
    constructor: (@provider, @device, @color, @variable) ->
      @_variableManager = null

      if @variable
        @_variableManager = @provider.framework.variableManager

    executeAction: (simulate) =>
      getHue = (callback) =>
        if @variable
          @_variableManager.evaluateStringExpression([@variable])
          .then (temperature) =>
            temperatureHue = new Hue()
            hue = 30 + 240 * (30 - temperature) / 60;
            temperatureHue.hsl(hue, 70, 50)

            hexHue = '#'
            hexHue += temperatureHue.rgb().r.toString(16)
            hexHue += temperatureHue.rgb().g.toString(16)
            hexHue += temperatureHue.rgb().b.toString(16)

            callback hexHue, simulate
        else
          callback @color, simulate

      getHue @setHue

    setHue: (color, simulate) =>
      if simulate
        return Promise.resolve(__("would log set color #{color}"))
      else
        @device.setHue color
        return Promise.resolve(__("set color #{color}"))

  class HueActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->

    parseAction: (input, context) =>
      iwyDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("setHue")
      ).value()

      hadPrefix = false

      # Try to match the input string with: set ->
      m = M(input, context).match(['set '])

      device = null
      color = null
      match = null
      variable = null

      # device name -> color
      m.matchDevice iwyDevices, (m, d) ->
# Already had a match with another device?
        if device? and device.id isnt d.id
          context?.addError(""""#{input.trim()}" is ambiguous.""")
          return

        device = d

        m.match [' to '], (m) ->
          m.or [
# rgb hex like #00FF00
            (m) ->
# TODO: forward pattern to UI
              m.match [/(#[a-fA-F\d]{6})(.*)/], (m, s) ->
                color = s.trim()
                match = m.getFullMatch()

# color name like red
            (m) -> m.match _.keys(color_schema), (m, s) ->
              color = color_schema[s]
              match = m.getFullMatch()

# color by temperature from variable like $weather.temperature = 30
            (m) ->
              m.match ['temperature based color by variable '], (m) ->
                m.matchVariable (m, s) ->
                  variable = s
                  match = m.getFullMatch()
          ]

      if match?
        assert device?
        # either variable or color should be set
        assert variable? ^ color?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new HueActionHandler(@, device, color, variable)
        }
      else
        return null

  return HueActionProvider
