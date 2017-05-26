module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = env.require 'lodash'
  M = env.matcher


  class ChronoThermPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("ChronoThermDevice", {
        configDef: deviceConfigDef.ChronoThermDevice,
        createCallback: (config, lastState, framework) ->
          return new ChronoThermDevice(config, lastState)
      })

      @framework.ruleManager.addActionProvider(new ChronoThermSeasonActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new ChronoThermMintoAutomodeActionProvider(@framework))
      # wait till all plugins are loaded
      @framework.on "after init", =>
      # Check if the mobile-frontent was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-chronotherm/app/ct-page.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-chronotherm/app/ct.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-chronotherm/app/ct.html"
        else
          env.logger.warn "your plugin could not find the mobile-frontend. No gui will be available"

  class ChronoThermDevice extends env.devices.Device

    cas1: 0
    cas2: 0
    cas3: 0
    cas4: 0
    cas5: 0
    cas6: 0
    cas7: 0
    sum1: 0
    sum2: 0
    sum3: 0
    sum4: 0
    sum5: 0
    sum6: 0
    sum7: 0
    realtemperature: 0
    result: 0
    perweb: 0
    _mode: null
    _manuTemp: null
    _autoTemp: null

    attributes:
      result:
        description: "Result"
        type: "number"
      cas1:
        description: "Variable to insert winter value"
        type: "string"
      cas2:
        description: "Variable to insert winter value"
        type: "string"
      cas3:
        description: "Variable to insert winter value"
        type: "string"
      cas4:
        description: "Variable to insert winter value"
        type: "string"
      cas5:
        description: "Variable to insert winter value"
        type: "string"
      cas6:
        description: "Variable to insert winter value"
        type: "string"
      cas7:
        description: "Variable to insert winter value"
        type: "string"
      sum1:
        description: "Variable to insert summmer value"
        type: "string"
      sum2:
        description: "Variable to insert summmer value"
        type: "string"
      sum3:
        description: "Variable to insert summmer value"
        type: "string"
      sum4:
        description: "Variable to insert summmer value"
        type: "string"
      sum5:
        description: "Variable to insert summmer value"
        type: "string"
      sum6:
        description: "Variable to insert summmer value"
        type: "string"
      sum7:
        description: "Variable to insert summmer value"
        type: "string"
      realtemperature:
        description: "Variable with real temperature"
        type: "string"
      perweb:
        description: "perweb"
        type: "string"
      mode:
        description: "The current mode"
        type: "string"
        enum: ["auto", "manu", "on", "off", "boost"]
      manuTemp:
        label: "Temperature Setpoint"
        description: "The temp that should be set"
        type: "number"
      autoTemp:
        label: "Automatic temperature"
        description: "Automatic temperature"
        type: "string"
      mintoautomode:
        description: "minute to turn to automode"
        type: "number"
      time:
        description: "current time and date"
        type: "number"
      timeturnam:
        description: "time to turn to automode"
        type: "number"
      valve:
        description: "valve"
        type: "boolean"
      season:
        description: "The current season"
        type: "string"
        enum: ["winter", "summer"]
    actions:
      changeValveTo:
        params:
          valve:
            type:"boolean"
      changeSeasonTo:
        params:
          season:
            type: "string"
      changeModeTo:
        params:
          mode:
            type: "string"
      changeTemperatureTo:
        params:
          manuTemp:
            type: "number"
      changeMinToAutoModeTo:
        params:
          mintoautomode:
            type: "number"
    template: "ChronoThermDevice"

    constructor: (@config, lastState, framework) ->
      @id = @config.id
      @name = @config.name
      @cas1 = lastState?.cas1?.value or 0
      @cas2 = 0
      @cas3 = 0
      @cas4 = 0
      @cas5 = 0
      @cas6 = 0
      @cas7 = 0
      @sum1 = lastState?.sum1?.value or 0
      @sum2 = 0
      @sum3 = 0
      @sum4 = 0
      @sum5 = 0
      @sum6 = 0
      @sum7 = 0
      @realtemperature = 0
      @result = 0
      @perweb = 0
      @setMode(lastState?.mode?.value or "auto")
      @intattivo = 0
      @setManuTemp(lastState?.manuTemp?.value or 20)
      @season = lastState?.season?.value or "winter"
      @timeturnam = lastState?.timeturnam?.value
      if @timeturnam? and @timeturnam isnt 0
        @timeturnam = new Date(@timeturnam)
      else
        @timeturnam = 0
      @mintoautomode = 0
      if @config.interface?
        @interfaccia = @config.interface
      else
        @interfaccia = 0
      @varManager = plugin.framework.variableManager #so you get the variableManager
      @_exprChangeListeners = []

      for reference in [
        {name: "cas1", expression: @config.cas1Ref}
        {name: "cas2", expression: @config.cas2Ref}
        {name: "cas3", expression: @config.cas3Ref}
        {name: "cas4", expression: @config.cas4Ref}
        {name: "cas5", expression: @config.cas5Ref}
        {name: "cas6", expression: @config.cas6Ref}
        {name: "cas7", expression: @config.cas7Ref}
        {name: "sum1", expression: @config.sum1Ref}
        {name: "sum2", expression: @config.sum2Ref}
        {name: "sum3", expression: @config.sum3Ref}
        {name: "sum4", expression: @config.sum4Ref}
        {name: "sum5", expression: @config.sum5Ref}
        {name: "sum6", expression: @config.sum6Ref}
        {name: "sum7", expression: @config.sum7Ref}
        {name: "realtemperature", expression: @config.realtemperature}
      ]
        do (reference) =>
          name = reference.name
          info = null

          evaluate = ( =>
            # wait till VariableManager is ready
            return Promise.delay(10).then( =>
              unless info?
                info = @varManager.parseVariableExpression(reference.expression)
                @varManager.notifyOnChange(info.tokens, evaluate)
                @_exprChangeListeners.push evaluate
              switch info.datatype
                when "numeric" then @varManager.evaluateNumericExpression(info.tokens)
                when "string"then @varManager.evaluateStringExpression(info.tokens)
                else
                  assert false
            ).then((val) =>
              if val
                env.logger.debug @id, name, val
                if name is "realtemperature"
                  val = val.toFixed(1)
                  @_setAttribute name, val
                else
                  @errori name, val
              return @[name]
            )
          )
          @_createGetter(name, evaluate)
      super()
      @errore_giorni()
      @aggiornaTempo()
      @girotempo = setInterval ( =>
        @aggiornaTempo() #giro aggiorna orario
        ), 1000 * @config.interval
    errori: (name, val) ->
      if @intattivo is 1
        clearTimeout @intervalId
        @intattivo = 0
      @errore = 0
      if (/([^0-9\,\:\.])/g.test(val)) #check if it's only numbers and , :
        env.logger.debug @name, "--> Character error, type only , : and numbers "
        @errore = 1
      if val % 2 is 0 #check if all numbers are even
        env.logger.debug @name, "--> Odd error, wrong type of numbers "
        @errore = 1
      conteggio = val.toString().split(',')
      if conteggio[1]? and conteggio[1] isnt "00:00"#check if 2° number is 00:00
        env.logger.debug @name, "--> Inside 0 error, the second number must be 00:00"
        @errore = 1
      for elementi in conteggio[1..] by 2
        clock = elementi.toString().split(':')
        if clock[0] > 23 or clock[1] > 59 #check if all hours are logical
          env.logger.debug @name, "--> Hours error, you have write hours in a wrong way"
          @errore = 1
      if @errore is 1 #tutto ok procedi
        @errore = 0
        val = 0
      @_setAttribute name, val
      @errore_giorni()
    errore_giorni: () ->
      if @season is "winter"
        acas1 = @cas1.toString().split(',')
        acas2 = @cas2.toString().split(',')
        acas3 = @cas3.toString().split(',')
        acas4 = @cas4.toString().split(',')
        acas5 = @cas5.toString().split(',')
        acas6 = @cas6.toString().split(',')
        acas7 = @cas7.toString().split(',')
      else
        acas1 = @sum1.toString().split(',')
        acas2 = @sum2.toString().split(',')
        acas3 = @sum3.toString().split(',')
        acas4 = @sum4.toString().split(',')
        acas5 = @sum5.toString().split(',')
        acas6 = @sum6.toString().split(',')
        acas7 = @sum7.toString().split(',')
      array_giorni = acas1[0] + acas2[0] + acas3[0] + acas4[0] + acas5[0] + acas6[0] + acas7[0]
      somma_giorni = 0
      for numeri in array_giorni
        aggiungi = Number(numeri)
        somma_giorni+=aggiungi
      if somma_giorni isnt 28 # 1+2+3+4+5+6+7 = 28
        env.logger.debug @name, "--> You forgot or duplicated one or more days of the week"
        @ciclo_errore_giorni()
        return
      else
        for x in [1..7]
          trovato_giorno = array_giorni.indexOf(x)
          if trovato_giorno < 0
            @ciclo_errore_giorni()
          break
      clearTimeout @intervalId
      clearTimeout @giroErrore
      @requestValue()
      @intervalId = setInterval ( =>
        @intattivo = 1
        @requestValue()
        ), @config.interval * 1000
    ciclo_errore_giorni: () ->
      zero = 0
      clearTimeout @intervalId
      clearTimeout @giroErrore
      @giroErrore = setInterval ( =>
        @errore_giorni()
        ), 3000
      @emit "perweb", zero
      return Promise.resolve()
    aggiornaTempo: () ->
      @setValve() #set valve to true or false
      # console.log "GIRO aggiornaTempo"
      now = new Date()
      @time = now
      if @timeturnam is 0
        @emit "time", @time
        return Promise.resolve()
      if @time > @timeturnam
        @timeturnam = 0
        @emit "timeturnam", @timeturnam
        @changeModeTo "auto"
      else
      @emit "time", @time
      return Promise.resolve()
    requestValue: () ->
      if @season is "winter"
        l01 = @cas1
        l02 = @cas2
        l03 = @cas3
        l04 = @cas4
        l05 = @cas5
        l06 = @cas6
        l07 = @cas7
      else
        l01 = @sum1
        l02 = @sum2
        l03 = @sum3
        l04 = @sum4
        l05 = @sum5
        l06 = @sum6
        l07 = @sum7

      array01 = []
      tempo = new Date()
      ora = tempo.getHours() #prende solo l'ora non i minuti / get the hours
      minuti = tempo.getMinutes() #get the minutes
      if minuti < 10    # corregge problema dello 0 nei minuti minori di 10
        orario = "#{ora}:0#{minuti}" # correct when minutes less then 10 add a 0
      else
        orario = "#{ora}:#{minuti}"
      # orario = Math.round(orario*100)
      giornods = tempo.getDay() #numero del giorno della settimana
      if giornods is 0  # get the number of the day and change sunday to 7
        giornods = 7
      lista_variabili = [[l01],[l02],[l03],[l04],[l05],[l06],[l07]]# multi array
      for i in lista_variabili     # find the right day inside multi array
        test = @trova_giorno(giornods, i)
        if test?
          array01 = test  #return the right array
      if array01.length > 0
        lung_array01 = array01.length #trova la lunghezza dell'array / find array length
        array_esatto = array01
        array01.shift() #elimina il primo dato dall'array / delete the first value of array
      else
        array01 = []
      array_orari = (x for x in array01 by 2) #prende solo i dati pari (orari) / take values by 2
      array_orari.push("23:59") #aggiunge il valore 23:59 alla fine dell' array
                     #insert 23:59 to the end of array
      for ogni_array_orari, pao in array_orari
        orario_basso = array_orari[pao].toString().split(':')
        minuti_orario_basso = Number(orario_basso[0]) * 60 + Number(orario_basso[1])
        orario_giusto = orario.toString().split(':')
        minuti_orario = Number(orario_giusto[0]) * 60 + Number(orario_giusto[1])
        if array_orari[pao+1]?
          orario_alto = array_orari[pao+1].toString().split(':')
          minuti_orario_alto = Number(orario_alto[0]) * 60 + Number(orario_alto[1])
        else orario_alto = 1440
        if minuti_orario >= minuti_orario_basso and minuti_orario < minuti_orario_alto
                  #find the position of the right value
          autoTemp = array_esatto[(pao * 2)+1] #the autotemperature in now time of schedule
          @minuti_alnuovo_schedule = minuti_orario_alto - minuti_orario
      @_autoTemp = Number(autoTemp)
      if @_mode is "auto"
        @result = @_autoTemp
      else if @_mode is "off"
        if @season is "winter"
          @result = @config.offtemperature
        else
          @result = @config.ontemperature
      else if @_mode is "on"
        if @season is "winter"
          @result = @config.ontemperature
        else
          @result = @config.offtemperature
      if @config.interface is 1
        if @_mode is "on"
          @result = 1
        else if @_mode is "off"
          @result = 0
        else
          @result = @_autoTemp
      @emit "autoTemp", @_autoTemp
      @emit "result", @result
      @emit "perweb", array01
      return Promise.resolve()
    trova_giorno: (giornods, array01) ->
      array01 = array01.toString().split(',') # trasforma variabile in un array di numeri
                                              # transform string to array
      yyy = array01[0] #prende il primo dato dell' array / get the first value of array
      array_dei_giorni = yyy.split('')  # trasforma il primo numero nell'array dei giorni
                                        # transform the first value to a string
      array_dei_numeri = array_dei_giorni.map(Number) # trasforma la stringa di array in un array di numeri
      if giornods in array_dei_numeri   # transform the string of day to a new array
        return array01
    calcolaEOD: () ->
      today = new Date(@time)
      oggi_ora = today.getHours()
      oggi_minuti = today.getMinutes()
      minuti_rimanenti = 1440 - ((oggi_ora * 60) + (oggi_minuti))
      return minuti_rimanenti
    setValve:() ->
      if @config.interface is 1
        if @result is 1
          @valve = true
        else
          @valve = false
      else
        if @season is "winter"
          if @realtemperature < @result
            @valve = true
          else
            @valve = false
        else
          if @realtemperature > @result
            @valve = true
          else
            @valve = false
      @emit "valve", @valve
      return Promise.resolve()
    _setAttribute: (attributeName, value) ->
      if @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value
    setSeason: (season) ->
      if season is @season then return
      @season = season
      @emit "season",@season
      @requestValue()
      return Promise.resolve()
    setMode: (mode) ->
      if mode is @_mode then return
      switch mode
        when 'auto'
          @timeturnam = 0
          @emit "timeturnam", @timeturnam
          @result = @_autoTemp
          @emit "result", @result
        when 'manu'
          @result = @_manuTemp
          @emit "result", @result
        when 'on'
          if @config.interface is 0
            if @season is "winter"
              @result = @config.ontemperature
            else
              @result = @config.offtemperature
          else
            @result = 1
          @emit "result", @result
        when 'boost'
          @result = 50
          @emit "result", @result
        when 'off'
          if @config.interface is 0
            if @season is "winter"
              @result = @config.offtemperature
            else
              @result = @config.ontemperature
          else
            @result = 0
          @emit "result", @result
      @_mode = mode
      @emit "mode", @_mode
      @aggiornaTempo()
      return Promise.resolve()
    setManuTemp: (manuTemp) ->
      if manuTemp is @_manuTemp then return
      @_manuTemp = manuTemp
      if @_mode is "manu"
        @result = @_manuTemp
        @emit "result", @result
      @emit "manuTemp", @_manuTemp
      @aggiornaTempo()
      return Promise.resolve()
    setMinToAutoModeTo: (mintoautomode) ->
      if mintoautomode is 0.307
        mintoautomode = @calcolaEOD()
      if mintoautomode is 0.305
        mintoautomode = @minuti_alnuovo_schedule
      if mintoautomode is 0
        @timeturnam = 0
      else
        @timeturnam = new Date(@time.getTime() + mintoautomode * 60 * 1000)
        @mintoautomode = mintoautomode
      @emit "mintoautomode", @mintoautomode
      @emit "timeturnam", @timeturnam
      return Promise.resolve()
    changeSeasonTo: (season) ->
      @setSeason(season)
      return Promise.resolve()
    changeModeTo: (mode) ->
      @setMode(mode)
      return Promise.resolve()
    changeTemperatureTo: (manuTemp) ->
      @setManuTemp(manuTemp)
      return Promise.resolve()
    changeMinToAutoModeTo: (mintoautomode) ->
      @setMinToAutoModeTo(mintoautomode)
      return Promise.resolve()
    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()
    getManuTemp: () ->  Promise.resolve(@_manuTemp)
    getMode: () ->  Promise.resolve(@_mode)
    getAutoTemp: () -> Promise.resolve(@_autoTemp)
    getPerweb: () -> Promise.resolve(@perweb)
    getResult: () -> Promise.resolve(@result)
    getRealTemperature: () -> Promise.resolve(@realtemperature)
    getMintoautomode: () -> Promise.resolve(@mintoautomode)
    getTimeturnam: () -> Promise.resolve(@timeturnam)
    getTime: () -> Promise.resolve(@time)
    getCas1: () -> Promise.resolve(@cas1)
    getCas2: () -> Promise.resolve(@cas2)
    getCas3: () -> Promise.resolve(@cas3)
    getCas4: () -> Promise.resolve(@cas4)
    getCas5: () -> Promise.resolve(@cas5)
    getCas6: () -> Promise.resolve(@cas6)
    getCas7: () -> Promise.resolve(@cas7)
    getSum1: () -> Promise.resolve(@sum1)
    getSum2: () -> Promise.resolve(@sum2)
    getSum3: () -> Promise.resolve(@sum3)
    getSum4: () -> Promise.resolve(@sum4)
    getSum5: () -> Promise.resolve(@sum5)
    getSum6: () -> Promise.resolve(@sum6)
    getSum7: () -> Promise.resolve(@sum7)
    getValve: () -> Promise.resolve(@valve)
    getSeason: () -> Promise.resolve(@season)

  class ChronoThermSeasonActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->

    parseAction: (input, context) =>
      # The result the function will return:
      retVar = null

      season = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("changeSeasonTo")
      ).value()

      if season.length is 0 then return

      device = null
      valueTokens = null
      match = null

      # Try to match the input string with:
      M(input, context)
        .match('set season of ')
        .matchDevice(season, (next, d) =>
          next.match(' to ')
            .matchStringWithVars( (next, ts) =>
              m = next.match(' season', optional: yes)
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              device = d
              valueTokens = ts
              match = m.getFullMatch()
            )
        )

      if match?
        if valueTokens.length is 1 and not isNaN(valueTokens[0])
          value = valueTokens[0]
          assert(not isNaN(value))
          modes = ["winter", "summer"]
          if modes.indexOf(value) < -1
            context?.addError("Allowed modes: winter,summer")
            return
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new ChronoThermSeasonActionHandler(@framework, device, valueTokens)
        }
      else
        return null
  class ChronoThermSeasonActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @device, @valueTokens) ->
      assert @device?
      assert @valueTokens?

    setup: ->
      @dependOnDevice(@device)
      super()

    ###
    Handles the above actions.
    ###
    _doExecuteAction: (simulate, value) =>
      return (
        if simulate
          __("would set mode %s to %s", @device.name, value)
        else
          @device.changeSeasonTo(value).then( => __("set season %s to %s", @device.name, value) )
      )

    # ### executeAction()
    executeAction: (simulate) =>
      @framework.variableManager.evaluateStringExpression(@valueTokens).then( (value) =>
        @lastValue = value
        return @_doExecuteAction(simulate, value)
      )

    # ### hasRestoreAction()
    hasRestoreAction: -> yes
    # ### executeRestoreAction()
    executeRestoreAction: (simulate) => Promise.resolve(@_doExecuteAction(simulate, @lastValue))
  class ChronoThermMintoAutomodeActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->

    parseAction: (input, context) =>
      # The result the function will return:
      retVar = null

      minute = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("changeMinToAutoModeTo")
      ).value()

      if minute.length is 0 then return

      device = null
      valueTokens = null
      match = null

      # Try to match the input string with:
      M(input, context)
        .match('set minute to automode of ')
        .matchDevice(minute, (next, d) =>
          next.match(' to ')
            .matchNumericExpression( (next, ts) =>
              m = next.match(' min', optional: yes)
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              device = d
              valueTokens = ts
              match = m.getFullMatch()
            )
        )

      if match?
        if valueTokens.length is 1 and not isNaN(valueTokens[0])
          value = valueTokens[0]
          assert(not isNaN(value))
          value = parseFloat(value)
          if value < 0.0
            context?.addError("Can't set minute to a negative value.")
            return
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new ChronoThermMintoAutomodeActionHandler(@framework, device, valueTokens)
        }
      else
        return null
  class ChronoThermMintoAutomodeActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @device, @valueTokens) ->
      assert @device?
      assert @valueTokens?

    setup: ->
      @dependOnDevice(@device)
      super()

    ###
    Handles the above actions.
    ###
    _doExecuteAction: (simulate, value) =>
      return (
        if simulate
          __("would set minute of %s to %s min", @device.name, value)
        else
          @device.changeMinToAutoModeTo(value).then( =>
            __("set minute of %s to %s min", @device.name, value)
          )
      )

    # ### executeAction()
    executeAction: (simulate) =>
      @framework.variableManager.evaluateNumericExpression(@valueTokens).then( (value) =>
        # value = @_clampVal value
        @lastValue = value
        return @_doExecuteAction(simulate, value)
      )

    # ### hasRestoreAction()
    hasRestoreAction: -> yes
    # ### executeRestoreAction()
    executeRestoreAction: (simulate) => Promise.resolve(@_doExecuteAction(simulate, @lastValue))

  plugin = new ChronoThermPlugin
  return plugin
