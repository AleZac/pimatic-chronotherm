$(document).on( "templateinit", (event) ->

  class ChronoThermItem extends pimatic.DeviceItem
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
      if @device.config.interface?
        @interfaccia = @device.config.interface
      else
        @interfaccia = 0

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
          @changeTemperatureTo(parseFloat(textValue))
      ).extend({ rateLimit: { timeout: 1000, method: "notifyWhenChangesStop" } })

      @errore_web = @getAttribute('perweb').value()
      @modo = "auto"

      # @aggiornaOrario()
      # console.log @aggiornaOrario()

    afterRender: (elements) ->
      super(elements)

      @apri = $(elements).find('[name=apri]')
      @finetempo = $(elements).find('[name=timeoutinput]')
      @pulsauto = $(elements).find('[name=pulsauto]')
      @pulsmanu = $(elements).find('[name=pulsmanu]')
      @pulson = $(elements).find('[name=pulson]')
      @pulsoff = $(elements).find('[name=pulsoff]')
      @input = $(elements).find('.spinbox input')
      @input.spinbox()

      @updateButtons()
      @getAttribute('mode').value.subscribe( => @updateButtons() )
      return
    timeoutapri: ->
      @apri.removeClass('nascondi')
      @timeouttempo = 0
      @finetempo.val('00:00:00')
    somma1m: -> @insertTimeOutTempo(60)
    # somma1m: -> @insertTimeOutTempo(5)
    somma5m: -> @insertTimeOutTempo(300)
    somma30m: -> @insertTimeOutTempo(1800)
    somma1h: -> @insertTimeOutTempo(3600)
    timeoutalways: ->
      @finetempo.val('ALWAYS')
    timeoutreset: ->
      @timeouttempo = 0
      @finetempo.val('00:00:00')
    timeoutcancel: ->
      @apri.addClass('nascondi')
      @resettaMezzoColore()
    timeoutok: ->
      @resettaMezzoColore()
      @apri.addClass('nascondi')
      if @finetempo.val() is "ALWAYS"
        @changeModeTo @modo
      else
        @changeModeTo @modo
        callback = =>
          @changeModeTo('auto')
        setTimeout callback, @timeouttempo * 1000

    insertTimeOutTempo: (time) ->
      @timeouttempo = @timeouttempo + time
      mostra_orologio = new Date(@timeouttempo * 1000).toISOString().substr(11, 8)
      @finetempo.val(mostra_orologio)

    manuMode: ->
      @resettaMezzoColore()
      @pulsmanu.addClass('puls-mezzo-acceso')
      @modo = "manu"
      @timeout = 0
      @timeoutapri()
    offMode: ->
      @resettaMezzoColore()
      @pulsoff.addClass('puls-mezzo-acceso')
      @modo = "off"
      @timeout = 0
      @timeoutapri()
    onMode: ->
      @resettaMezzoColore()
      @pulson.addClass('puls-mezzo-acceso')
      @modo = "on"
      @timeout = 0
      @timeoutapri()

    autoMode: -> @changeModeTo "auto"
    setTemp: -> @changeTemperatureTo "#{@inputValue.value()}"
    resettaMezzoColore: ->
      @pulsmanu.removeClass('puls-mezzo-acceso')
      @pulsoff.removeClass('puls-mezzo-acceso')
      @pulson.removeClass('puls-mezzo-acceso')

    changeModeTo: (mode) ->
      @device.rest.changeModeTo({mode}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
    changeTemperatureTo: (manuTemp) ->
      # @input.spinbox('disable')
      @device.rest.changeTemperatureTo({manuTemp}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)

    updateButtons: ->
      modeAttr = @getAttribute('mode').value()
      switch modeAttr
        when 'auto'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulson.removeClass('ui-btn-active')
          @pulsauto.addClass('ui-btn-active')
        when 'manu'
          @pulsmanu.addClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulson.removeClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
        when 'off'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.addClass('ui-btn-active')
          @pulson.removeClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
        when 'on'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulson.addClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
      return

    paginaweb: () ->
      uuu = @getAttribute('perweb').value()
      if uuu is 0
        return uuu
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
        if valore2 is "0" then col = "red" else col = "green" #colore barre
        alt = Math.round(nuovovalore) + 1
                  # regolo l'altezza in base al max valore dei gradi
        barra = {
          orario: valore1,
          temperatura: "#{valore2}°",
          posizione: "#{pos}%",
          larghezza: "#{larg}%",
          altezza: "#{alt}%",
          colore: "#{col}"
        }
        tabella.push(barra)
      return tabella

    aggiornaOrario : () ->
      today = new Date()
      oggi_ora = today.getHours()
      oggi_minuti = today.getMinutes()
      oggi_minuti_corretto = (if oggi_minuti < 10 then "0" else "" )+""+oggi_minuti
                                #corregge errore dei minuti minori di 10
      pos = Math.round((oggi_ora+(oggi_minuti/60)) * 1000 / 24)/10 #trova la posizione in %
      if pos < 50
        verso = pos
        allineamento = "right"
      else
        verso = pos - 10
        allineamento = "left"
      orario = oggi_ora + ":" + oggi_minuti_corretto
      bandellaorario = {ora: orario, posizione: "#{pos}%", verso: "#{verso}%", allineamento: "#{allineamento}"}
      console.log orario
      console.log pos
      console.log bandellaorario
      return bandellaorario

    getConfig: (name) ->
      if @device.config[name]?
        return @device.config[name]
      else
        return @device.configDefaults[name]

  pimatic.templateClasses['ChronoThermDevice'] = ChronoThermItem
)
