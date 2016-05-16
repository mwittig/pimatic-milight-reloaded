$(document).on 'templateinit', (event) ->

  class MilightWwcwItem extends pimatic.DeviceItem
    constructor: (templateData, @device) ->
      super

      @id = templateData.deviceId
      @state = null

    afterRender: (elements) ->
      super

      @powerSwitch = $(elements).find('.milight-state')
      @powerSwitch.flipswitch()
      $(elements).find('.ui-flipswitch').addClass('no-carousel-slide')

      @_onLocalChange 'state', @_setState
      @_onRemoteChange 'state', @powerSwitch

      @powerSwitch.val(@state()).trigger 'change', [origin: 'remote']

    _debounce: (fn, timeout) ->
      clearTimeout @debounceTimerId if @debounceTimerId
      @debounceTimerId = setTimeout fn, timeout

    _action: (event) ->
      if @mouseStillDown
        name = $(event.target).attr("name")
        unless name.length is 0
          @['_' + name]()

        @mouseDownActionTimer = setTimeout (=> @_action event), 100

    _onLocalChange: (element, fn) ->
      timeout = 75
      queue = async.queue (arg, cb) =>
        fn.call(@, arg)
        .done( (jqXHR) =>
          @_debounce () =>
            ajaxShowToast(jqXHR)
          , 500
          setTimeout cb, timeout
        )
        .fail( (jqXHR, textStatus, errorThrown) =>
          ajaxAlertFail(jqXHR, textStatus, errorThrown)
          setTimeout cb, timeout
        )
      , 1 # concurrency

      $('#index').on "vmousedown", "#item-lists ##{@id} .milight-button-container a", (e, payload) =>
        @mouseStillDown = true
        @_action e

      $('#index').on "vmouseup", "#item-lists ##{@id} .milight-button-container a", (e, payload) =>
        @mouseStillDown = false
        clearTimeout @mouseDownActionTimer if @mouseDownActionTimer?
        @mouseDownActionTimer = null

      $('#index').on "change", "#item-lists ##{@id} .milight-#{element}", (e, payload) =>
        unless payload?.origin is 'remote' or @[element]?() is $(e.target).val()
          queue.kill() if queue.length() >= 1
          queue.push $(e.target).val()

    _onRemoteChange: (attributeName, el) ->
      unless attributeName?
        throw new Error("A Milight RGBW device needs an #{attributeName} attribute!")

      attribute = @getAttribute(attributeName)
      if attributeName is "state"
        @[attributeName] = ko.observable(if attribute.value() then 'on' else 'off')

        attribute.value.subscribe (newValue) =>
          @state(if newValue then 'on' else 'off')
          @powerSwitch.flipswitch 'refresh'
      else
        @[attributeName] = ko.observable attribute.value()
        attribute.value.subscribe (newValue) =>
          @[attributeName] newValue
          el.val(@[attributeName]()).trigger 'change', [origin: 'remote']

    _setState: (state) ->
      if state is 'on'
        @device.rest.turnOn {}, global: no
      else
        @device.rest.turnOff {}, global: no

    _brightnessUp: () ->
      if @state() is 'off'
        @powerSwitch.val 'on'
        @_setState 'on'
      @device.rest.brightnessUp {}, global: no

    _brightnessDown: () ->
      if @state() is 'off'
        @powerSwitch.val 'on'
        @_setState 'on'
      @device.rest.brightnessDown {}, global: no

    _warmer: () ->
      if @state() is 'off'
        @powerSwitch.val 'on'
        @_setState 'on'
      @device.rest.warmer {}, global: no

    _cooler: () ->
      if @state() is 'off'
        @powerSwitch.val 'on'
        @_setState 'on'
      @device.rest.cooler {}, global: no

  class MilightRgbwItem extends pimatic.DeviceItem
    constructor: (templateData, @device) ->
      super

      @id = templateData.deviceId
      @dimlevel = null
      @hue = null

    afterRender: (elements) ->
      super

      @dimlevelSlider = $(elements).find('.milight-dimlevel')
      @dimlevelSlider.slider()
      $(elements).find('.ui-slider').addClass('no-carousel-slide')

      @hueSlider = $(elements).find('.milight-hue')
      @hueSlider.slider()
      $(elements).find('.ui-slider').addClass('no-carousel-slide')

      @_onLocalChange 'dimlevel', @_setDimlevel
      @_onLocalChange 'hue', @_setHue

      @_onRemoteChange 'dimlevel', @dimlevelSlider
      @_onRemoteChange 'hue', @hueSlider

      @dimlevelSlider.val(@dimlevel()).trigger 'change', [origin: 'remote']
      @hueSlider.val(@hue()).trigger 'change', [origin: 'remote']

    _debounce: (fn, timeout) ->
      clearTimeout @debounceTimerId if @debounceTimerId
      @debounceTimerId = setTimeout fn, timeout

    _onLocalChange: (element, fn) ->
      timeout = 75

      queue = async.queue (arg, cb) =>
        fn.call(@, arg)
          .done( (jqXHR) =>
            @_debounce () =>
              ajaxShowToast(jqXHR)
            , 500
            setTimeout cb, timeout
          )
          .fail( (jqXHR, textStatus, errorThrown) =>
            ajaxAlertFail(jqXHR, textStatus, errorThrown)
            setTimeout cb, timeout
          )
      , 1 # concurrency

      $('#index').on "change", "#item-lists ##{@id} .milight-#{element}", (e, payload) =>
        unless payload?.origin is 'remote' or @[element]?() is $(e.target).val()
          queue.kill() if queue.length() >= 1
          queue.push $(e.target).val()

      if element is 'dimlevel'
        @dimlevelSlider.change () =>
          val = Number @dimlevelSlider.val()
          unless val is 0
            val = Math.round(val * 64.0 / 100.0) + (if val < 100 then 127 else 191)
          rgb = [val, val, val].join()
          @dimlevelSlider.next().css("background-color", "rgb(#{rgb})")

      if element is 'hue'
        @hueSlider.change () =>
          rgb = "255, 255, 255"
          val = Number @hueSlider.val()
          unless val is 256
            c1 = Math.floor((val / 255.0 * 359.0) % 360) - 240
            color = if c1 <= 0 then Math.abs(c1) else 360 - c1
            rgb = @hsvToRgb(color, 80, 100).join()
          @hueSlider.next().css("background-color", "rgb(#{rgb})")

    _onRemoteChange: (attributeName, el) ->
      unless attributeName?
        throw new Error("A Milight RGBW device needs an #{attributeName} attribute!")

      attribute = @getAttribute(attributeName)
      @[attributeName] = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        @[attributeName] newValue
        el.val(@[attributeName]()).trigger 'change', [origin: 'remote']

    _setHue: (hueValue) ->
      if Number(hueValue) is 256
        @device.rest.changeWhiteTo {white: true}, global: no
      else
        @device.rest.changeHueTo {hue: hueValue},  global: no

    _setDimlevel: (dimlevelValue) ->
      @device.rest.changeDimlevelTo {dimlevel: dimlevelValue}, global: no

    hsvToRgb: (h, s, v) ->
      # Make sure our arguments stay in-range
      h = Math.max(0, Math.min(360, h))
      s = Math.max(0, Math.min(100, s))
      v = Math.max(0, Math.min(100, v))
      s /= 100
      v /= 100
      if s == 0
        # Achromatic (grey)
        r = g = b = v
        return [
          Math.round(r * 255)
          Math.round(g * 255)
          Math.round(b * 255)
        ]
      h /= 60
      # sector 0 to 5
      i = Math.floor(h)
      f = h - i
      # factorial part of h
      p = v * (1 - s)
      q = v * (1 - (s * f))
      t = v * (1 - (s * (1 - f)))
      switch i
        when 0
          r = v
          g = t
          b = p
        when 1
          r = q
          g = v
          b = p
        when 2
          r = p
          g = v
          b = t
        when 3
          r = p
          g = q
          b = v
        when 4
          r = t
          g = p
          b = v
        else
          # case 5:
          r = v
          g = p
          b = q
      [
        Math.round(r * 255)
        Math.round(g * 255)
        Math.round(b * 255)
      ]

  # register the item-class
  pimatic.templateClasses['milight-rgbw'] = MilightRgbwItem
  pimatic.templateClasses['milight-cwww'] = MilightWwcwItem
