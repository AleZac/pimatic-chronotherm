$(document).on( "templateinit", (event) ->

  class CronoAccesoSpentoItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @inputValue = ko.observable()

      @stAttr = @getAttribute('manuTemp')
      @inputValue(@stAttr.value())

      attrValue = @stAttr.value()

      @stAttr.value.subscribe( (value) =>
        @inputValue(value)
        attrValue = value
      )

      attribute = @getAttribute("result")
      @tempPresunta = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        @tempPresunta newValue

      attributetemperature = @getAttribute("realtemperature")
      @tempEffettiva = ko.observable attributetemperature.value()
      attributetemperature.value.subscribe (newValue) =>
        @tempEffettiva newValue

      ko.computed( =>
        textValue = @inputValue()
        if textValue? and attrValue? and parseFloat(attrValue) isnt parseFloat(textValue)
          @changeManuTempTo(parseFloat(textValue))

      ).extend({ rateLimit: { timeout: 1000, method: "notifyWhenChangesStop" } })

    afterRender: (elements) ->
      super(elements)

      @pulsauto = $(elements).find('[name=pulsauto]')
      @pulsmanu = $(elements).find('[name=pulsmanu]')
      @pulsoff = $(elements).find('[name=pulsoff]')
      @input = $(elements).find('.spinbox input')
      @input.spinbox()

      @updateButtons()
      @getAttribute('mode').value.subscribe( => @updateButtons() )
      return

    manuMode: -> @changeModeTo "manu"
    offMode: -> @changeModeTo "off"
    autoMode: -> @changeModeTo "auto"
    setTemp: -> @changeManuTempTo "#{@inputValue.value()}"

    changeModeTo: (mode) ->
      @device.rest.changeModeTo({mode}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)

    changeManuTempTo: (manuTemp) ->
      # @input.spinbox('disable')
      @device.rest.changeManuTempTo({manuTemp}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
        # .always( => @input.spinbox('enable') )

    updateButtons: ->
      modeAttr = @getAttribute('mode').value()
      switch modeAttr
        when 'auto'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulsauto.addClass('ui-btn-active')
        when 'manu'
          @pulsmanu.addClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
        when 'off'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.addClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
      return

    paginaweb: ->
      uuu = @getAttribute('perweb').value()
      tabella = []
      val_max = (x for x in uuu.slice(1) by 2) # crea array di soli gradi
      valore_max = Math.max.apply(Math, val_max) # trova il valore max dei gradi
      for i,o in uuu by 2 #prende solo gli orari
        valore1 = uuu[o] #orario
        valore2 = uuu[o+1] #valore in base a orario
        valore3 = uuu[o+2] #orario successivo
        pos = Math.round((valore1*100*100/24)/100) #trova x% della posizione
        pos2 = Math.round((valore3*100*100/24)/100)
        larg = pos2 - pos - 1 # sottraggo 1 per distanziare
        if isNaN(larg)
          larg = 100 - pos

        nuovovalore = (valore2 * 100) / valore_max
        alt = Math.round(nuovovalore) + 1  # regolo l'altezza in base al max valore dei gradi
        barra = {orario: valore1, temperatura: "#{valore2}°", posizione: "#{pos}%", larghezza: "#{larg}%", altezza: "#{alt}%"}
        tabella.push(barra)
      return tabella

    getConfig: (name) ->
      if @device.config[name]?
        return @device.config[name]
      else
        return @device.configDefaults[name]

  pimatic.templateClasses['CronoAccesoSpentoDevice'] = CronoAccesoSpentoItem
)
