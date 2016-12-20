$(document).on( "templateinit", (event) ->

  class ChronoThermItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @time = @getAttribute('time')

      attributeturnam = @getAttribute('timeturnam')
      @timeturnam = ko.observable attributeturnam.value()
      attributeturnam.value.subscribe (newValue) =>
        @timeturnam newValue

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
      if @device.config.boost?
        @boost = 1
      else
        @boost = 0
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

    afterRender: (elements) ->
      super(elements)

      @apri = $(elements).find('[name=apri]')
      @finetempo = $(elements).find('[name=timeoutinput]')
      @pulsauto = $(elements).find('[name=pulsauto]')
      @pulsmanu = $(elements).find('[name=pulsmanu]')
      @pulson = $(elements).find('[name=pulson]')
      @pulsboost = $(elements).find('[name=pulsboost]')
      @pulsoff = $(elements).find('[name=pulsoff]')
      @bandella_orario = $(elements).find('[name=bandella_orario]')
      @segna_orario = $(elements).find('[name=segna_orario]')
      @input_barra_orario = $(elements).find('[name=input_barra_orario]')
      @input_segna_orario = $(elements).find('[name=input_segna_orario]')
      # @apri_blocco_input = $(elements).find('[name=apri_blocco_input]')
      @input = $(elements).find('.spinbox input')
      @input.spinbox()
      @updateButtons()
      @orarioBarra()
      @getAttribute('mode').value.subscribe( => @updateButtons() )

      @fineAutoMode()

      return

    manuMode: ->
      @resettaMezzoColore()
      @pulsmanu.addClass('puls-mezzo-acceso')
      @modo = "manu"
      @timeoutapri()
      # @changeModeTo "manu"

    offMode: ->
      @resettaMezzoColore()
      @pulsoff.addClass('puls-mezzo-acceso')
      @modo = "off"
      @timeoutapri()
      # @changeModeTo "off"
    onMode: ->
      @resettaMezzoColore()
      @pulson.addClass('puls-mezzo-acceso')
      @modo = "on"
      @timeoutapri()
      # @changeModeTo "on"
    autoMode: ->
      # @visibletimeturnam = 0
      @changeModeTo "auto"
    boostMode: -> @changeModeTo "boost"
    setTemp: -> @changeTemperatureTo "#{@inputValue.value()}"


    timeoutapri: ->
      @apri.removeClass('nascondi')
      @changeMinToAutoModeTo(0) #azzera conteggio minuti
      @importatempo = new Date(@time.value())
      tempo_format = @formattaTempo(@importatempo)
      @finetempo.val(tempo_format)
      @aggiungiminuti = 0 #resetta conteggio minuti aggiunti

    somma1m: -> @aggiungitempo(1)
    somma5m: -> @aggiungitempo(5)
    somma30m: -> @aggiungitempo(30)
    somma1h: -> @aggiungitempo(60)
    somma1d: -> @aggiungitempo(1440)
    sommaFinoAFineGiornata: ->
      today = new Date(@time.value())
      oggi_ora = today.getHours()
      oggi_minuti = today.getMinutes()
      minuti_rimanenti = 1440 - ((oggi_ora * 60) + (oggi_minuti))
      @aggiungitempo(minuti_rimanenti)
    timeoutalways: ->
      @aggiungiminuti = 0 #resetta conteggio minuti aggiunti
      @finetempo.val('ALWAYS')
    timeoutreset: ->
      @importatempo = new Date(@time.value())
      tempo_format = @formattaTempo(@importatempo)
      @finetempo.val(tempo_format)
      @aggiungiminuti = 0 #resetta conteggio minuti aggiunti
    timeoutcancel: ->
      @apri.addClass('nascondi')
      @resettaMezzoColore()
    timeoutok: ->
      console.log @aggiungiminuti, " --@aggiungiminuti"
      # @visibletimeturnam = 1

      @resettaMezzoColore() #remove green button
      @apri.addClass('nascondi') #hide timeout select interface
      if @finetempo.val() is "ALWAYS"
        @changeModeTo @modo
        console.log "Cambiato in ",@modo
      else
        if @aggiungiminuti is 0
          @changeModeTo 'auto'
        else
          @changeModeTo @modo
          @changeMinToAutoModeTo(@aggiungiminuti)
          setTimeout (=> @fineAutoMode()) , 1000 #delay


    orarioBarra: ->
      pos = @calcolaPos(@time.value())
      if pos < 50
        verso = pos
      else
        verso = pos - 25
      if @interfaccia is 1
        @segna_orario.css("bottom", "40px")
        @bandella_orario.css("height", "40px")
      @bandella_orario.css("left", "#{pos}%")
      @segna_orario.css("left", "#{verso}%")
      tempo_esatto = @formattaTempo(@time.value())
      @segna_orario.html(tempo_esatto)
    fineAutoMode: ->
      # turnam = @getAttribute('timeturnam').value()
      turnam = @timeturnam()
      # console.log turnam, "TURNAM"
      pos = @calcolaPos(turnam)
      if pos < 50
        verso = pos
      else
        verso = pos - 25
      if @interfaccia is 1
        @input_segna_orario.css("bottom", "25px")
        @input_barra_orario.css("height", "25px")
      @input_barra_orario.css("left", "#{pos}%")
      @input_segna_orario.css("left", "#{verso}%")
      tempo_esatto = @formattaTempo(turnam)
      @input_segna_orario.html(tempo_esatto)
      # @apri_blocco_input.removeClass('nascondi')
    formattaTempo: (tempo) ->
      # date = tempo.value()
      today = new Date(tempo)
      # console.log today, "TODAY"
      tempo_format =
        ("0" + today.getDate())[-2..] + "/" +
        ("0" + (today.getMonth()+1))[-2..]  + "/" +
        today.getFullYear() + "  " +
        ("0" + today.getHours())[-2..] + ":" +
        ("0" + today.getMinutes())[-2..]
      return tempo_format
    calcolaPos: (tempo) ->
      today = new Date(tempo)
      oggi_ora = today.getHours() * 60
      totale_minuti = today.getMinutes() + oggi_ora
      totale_minuti = Math.floor(totale_minuti % 1440)
      pos = Math.round(100 / (1440 / totale_minuti) * 10) / 10
                            #(minuti in un giorno/totale_minuti)
      return pos
    aggiungitempo: (minuti) ->
      @importatempo.setTime(@importatempo.getTime() + (minuti * 60 * 1000))
      @aggiungiminuti = @aggiungiminuti + minuti
      tempo_format = @formattaTempo(@importatempo)
      @finetempo.val(tempo_format)
    resettaMezzoColore: ->
      @pulsmanu.removeClass('puls-mezzo-acceso')
      @pulsoff.removeClass('puls-mezzo-acceso')
      @pulson.removeClass('puls-mezzo-acceso')


    changeModeTo: (mode) ->
      @device.rest.changeModeTo({mode}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
    changeTemperatureTo: (manuTemp) ->
      @device.rest.changeTemperatureTo({manuTemp}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
    changeMinToAutoModeTo: (mintoautomode) ->
      @device.rest.changeMinToAutoModeTo({mintoautomode}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
    updateButtons: ->
      modeAttr = @getAttribute('mode').value()
      switch modeAttr
        when 'auto'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulson.removeClass('ui-btn-active')
          @pulsboost.removeClass('ui-btn-active')
          @pulsauto.addClass('ui-btn-active')
        when 'manu'
          @pulsmanu.addClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulson.removeClass('ui-btn-active')
          @pulsboost.removeClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
        when 'off'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.addClass('ui-btn-active')
          @pulson.removeClass('ui-btn-active')
          @pulsboost.removeClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
        when 'on'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulsboost.removeClass('ui-btn-active')
          @pulson.addClass('ui-btn-active')
          @pulsauto.removeClass('ui-btn-active')
        when 'boost'
          @pulsmanu.removeClass('ui-btn-active')
          @pulsoff.removeClass('ui-btn-active')
          @pulson.removeClass('ui-btn-active')
          @pulsboost.addClass('ui-btn-active')
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

    getConfig: (name) ->
      if @device.config[name]?
        return @device.config[name]
      else
        return @device.configDefaults[name]

  pimatic.templateClasses['ChronoThermDevice'] = ChronoThermItem
)
