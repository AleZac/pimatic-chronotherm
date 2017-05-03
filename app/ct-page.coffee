$(document).on( "templateinit", (event) ->

  class ChronoThermItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @attributetime = @getAttribute('time')
      @time_pos = ko.observable(@calcolaPos(@getAttribute('time').value()))
      @time_verso = @time_pos()
      if @time_pos() < 50
        @time_verso = ko.observable(@calcolaPos(@getAttribute('time').value()))
      else
        @time_verso = ko.observable((@calcolaPos(@getAttribute('time').value()))- 25)
      @time = ko.observable @attributetime.value()
      @time_orario = ko.observable @formattaTempo(@time())
      @attributetime.value.subscribe (newValue) =>
        @time newValue
        @time_orario @formattaTempo(@time())
        @time_pos @calcolaPos(@getAttribute('time').value())
        if @time_pos() < 50
          @time_verso @calcolaPos(@getAttribute('time').value())
        else
          @time_verso @calcolaPos(@getAttribute('time').value()) - 25


      attributeturnam = @getAttribute('timeturnam')
      @timeout_pos = ko.observable(@calcolaPos(@getAttribute('timeturnam').value()))
      @timeout_verso = @timeout_pos()
      if @timeout_pos() < 50
        @timeout_verso = ko.observable(@calcolaPos(@getAttribute('timeturnam').value()))
      else
        @timeout_verso = ko.observable((@calcolaPos(@getAttribute('timeturnam').value()))- 25)
      @timeturnam = ko.observable attributeturnam.value()
      @timeout_orario = ko.observable @formattaTempo(@timeturnam())
      attributeturnam.value.subscribe (newValue) =>
        @timeturnam newValue
        @timeout_orario @formattaTempo(@timeturnam())
        @timeout_pos @calcolaPos(@getAttribute('timeturnam').value())
        if @timeout_pos() < 50
          @timeout_verso @calcolaPos(@getAttribute('timeturnam').value())
        else
          @timeout_verso @calcolaPos(@getAttribute('timeturnam').value()) - 25

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
      if @device.config.showseason?
        @showseason = 1
      else
        @showseason = 0

      attribute = @getAttribute("result")
      @tempPresunta = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        @tempPresunta newValue

      attributetemperature = @getAttribute("realtemperature")
      @tempEffettiva = ko.observable attributetemperature.value()
      attributetemperature.value.subscribe (newValue) =>
        @tempEffettiva newValue

      attributeseason = @getAttribute("season")
      @season = ko.observable attributeseason.value()
      attributeseason.value.subscribe (newValue) =>
        @season newValue

      attributevalve = @getAttribute("valve")
      @valve = ko.observable attributevalve.value()
      attributevalve.value.subscribe (newValue) =>
        @valve newValue

      ko.computed( =>
        textValue = @inputValue()
        if textValue? and attrValue? and parseFloat(attrValue) isnt parseFloat(textValue)
          @changeTemperatureTo(parseFloat(textValue))
      ).extend({ rateLimit: { timeout: 1000, method: "notifyWhenChangesStop" } })

      @errore_web = @getAttribute('perweb').value()
      @modo = "auto"
      @contaEOS = 0

    afterRender: (elements) ->
      super(elements)

      @zonaprogram = $(elements).find('[name=zonaprogram]')
      @aprichiudiprogramo = $(elements).find('[name=aprichiudiprogramo]')
      @aprichiudiprogramc = $(elements).find('[name=aprichiudiprogramc]')
      @apri = $(elements).find('[name=apri]')
      @finetempo = $(elements).find('[name=timeoutinput]')
      @pulsauto = $(elements).find('[name=pulsauto]')
      @pulsmanu = $(elements).find('[name=pulsmanu]')
      @pulson = $(elements).find('[name=pulson]')
      @pulsboost = $(elements).find('[name=pulsboost]')
      @pulsoff = $(elements).find('[name=pulsoff]')
      @pulsseason = $(elements).find('[name=pulsseason]')
      @segna_orario = $(elements).find('[name=segna_orario]')
      @input_barra_orario = $(elements).find('[name=input_barra_orario]')
      @input_segna_orario = $(elements).find('[name=input_segna_orario]')
      @input = $(elements).find('.spinbox input')
      @input.spinbox()
      @updateButtons()
      @getAttribute('mode').value.subscribe( => @updateButtons() )
      if @season is "winter" then @pulsseasonw.removeClass('nascondi')
      if @season is "summer" then @pulsseasons.removeClass('nascondi')
      return
    showProgramO: ->
      @zonaprogram.removeClass('nascondi')
      @aprichiudiprogramc.removeClass('nascondi')
      @aprichiudiprogramo.addClass('nascondi')
    showProgramC: ->
      @zonaprogram.addClass('nascondi')
      @aprichiudiprogramc.addClass('nascondi')
      @aprichiudiprogramo.removeClass('nascondi')
    manuMode: ->
      @resettaMezzoColore()
      @pulsmanu.addClass('puls-mezzo-acceso')
      @modo = "manu"
      @timeoutapri()
    offMode: ->
      @resettaMezzoColore()
      @pulsoff.addClass('puls-mezzo-acceso')
      @modo = "off"
      @timeoutapri()
    onMode: ->
      @resettaMezzoColore()
      @pulson.addClass('puls-mezzo-acceso')
      @modo = "on"
      @timeoutapri()
    autoMode: ->
      @changeModeTo "auto"
    boostMode: -> @changeModeTo "boost"
    setTemp: -> @changeTemperatureTo "#{@inputValue.value()}"
    seasonMode: ->
      if @season() is "winter"
        @changeSeasonTo "summer"
      else
        @changeSeasonTo "winter"
    timeoutapri: ->
      @apri.removeClass('nascondi')
      @changeMinToAutoModeTo(0) #azzera conteggio minuti
      @importatempo = new Date(@attributetime.value())
      tempo_format = @formattaTempo(@importatempo)
      @finetempo.val(tempo_format)
      @aggiungiminuti = 0 #resetta conteggio minuti aggiunti
    somma1m: -> @aggiungitempo(1)
    somma5m: -> @aggiungitempo(5)
    somma30m: -> @aggiungitempo(30)
    somma1h: -> @aggiungitempo(60)
    somma1d: -> @aggiungitempo(1440)
    sommaFinoAFineGiornata: ->
      minuti_rimanenti = @calcolaEOD()
      # minuti_rimanenti = 0.307
      @aggiungitempo(minuti_rimanenti)
    sommaFinoAFineSchedule: ->
      minuti_rimanenti = @calcolaEOS()
      # minuti_rimanenti = 0.305
      @aggiungitempo(minuti_rimanenti)
    timeoutalways: ->
      @aggiungiminuti = 0 #resetta conteggio minuti aggiunti
      @finetempo.val('ALWAYS')
    timeoutreset: ->
      @importatempo = new Date(@attributetime.value())
      tempo_format = @formattaTempo(@importatempo)
      @finetempo.val(tempo_format)
      @aggiungiminuti = 0 #resetta conteggio minuti aggiunti
      @contaEOS = 0
    timeoutcancel: ->
      @apri.addClass('nascondi')
      @resettaMezzoColore()
      @contaEOS = 0
    timeoutok: ->
      @contaEOS = 0
      @resettaMezzoColore() #remove green button
      @apri.addClass('nascondi') #hide timeout select interface
      if @finetempo.val() is "ALWAYS"
        @changeModeTo @modo
      else
        if @aggiungiminuti is 0
          @changeModeTo 'auto'
        else
          @changeModeTo @modo
          @changeMinToAutoModeTo(@aggiungiminuti)
    formattaTempo: (tempo) ->
      today = new Date(tempo)
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
    calcolaEOD: () ->
      today = new Date(@time())
      oggi_ora = today.getHours()
      oggi_minuti = today.getMinutes()
      minuti_rimanenti = 1440 - ((oggi_ora * 60) + (oggi_minuti))
      return minuti_rimanenti
    calcolaEOS: () ->
      schedule = @getAttribute('perweb').value()
      today = new Date(@time())
      adesso_minuti = today.getHours() * 60 + today.getMinutes()
      if @contaEOS isnt 0
        console.log "contaEOS = num"
        minuti_alnuovo_schedule = 0
      else
        for orari, num in schedule by 2
          sched = schedule[num].toString().split(':')
          minuti_sched = Number(sched[0]) * 60 + Number(sched[1])
          if schedule[num+2]?
            sched2 = schedule[num+2].toString().split(':')
            minuti_sched2 = Number(sched2[0]) * 60 + Number(sched2[1])
          else
            minuti_sched2 = 1440
          if adesso_minuti >= minuti_sched and adesso_minuti < minuti_sched2
            minuti_alnuovo_schedule = minuti_sched2 - adesso_minuti
            @contaEOS = num
      return minuti_alnuovo_schedule
    aggiungitempo: (minuti) ->
      @importatempo.setTime(@importatempo.getTime() + (minuti * 60 * 1000))
      @aggiungiminuti = @aggiungiminuti + minuti
      tempo_format = @formattaTempo(@importatempo)
      @finetempo.val(tempo_format)
    resettaMezzoColore: ->
      @pulsmanu.removeClass('puls-mezzo-acceso')
      @pulsoff.removeClass('puls-mezzo-acceso')
      @pulson.removeClass('puls-mezzo-acceso')
    changeSeasonTo: (season) ->
      @device.rest.changeSeasonTo({season}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
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
        valore2 = uuu[o+1] #valore temperatura in base a orario
        if uuu[o+2]?
          valore3 = uuu[o+2] #orario successivo
        else
          valore3 = 23:59
        valore_split = valore1.toString().split(':')
        minuti = Number(valore_split[0]) * 60 + Number(valore_split[1])#Calcola minuti
        valore_split2 = valore3.toString().split(':')
        minuti2 = Number(valore_split2[0]) * 60 + Number(valore_split2[1])#Calcola minuti
        pos = Math.round(100*minuti/1440)
        pos2 = Math.round(100*minuti2/1440)
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
