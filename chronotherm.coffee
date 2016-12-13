module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = env.require 'lodash'

  class ChronoThermPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("ChronoThermDevice", {
        configDef: deviceConfigDef.ChronoThermDevice,
        createCallback: (config, lastState) =>
          return new ChronoThermDevice(config, lastState)
      })
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
      cas1:
        description: "Variable to insert value"
        type: "string"
      cas2:
        description: "Variable to insert value"
        type: "string"
      cas3:
        description: "Variable to insert value"
        type: "string"
      cas4:
        description: "Variable to insert value"
        type: "string"
      cas5:
        description: "Variable to insert value"
        type: "string"
      cas6:
        description: "Variable to insert value"
        type: "string"
      cas7:
        description: "Variable to insert value"
        type: "string"
      realtemperature:
        description: "Variable with real temperature"
        type: "string"
      perweb:
        description: "perweb"
        type: "string"

    actions:
      changeModeTo:
        params:
          mode:
            type: "string"
      changeTemperatureTo:
        params:
          manuTemp:
            type: "number"
      changeAutoTempTo:
        params:
          autoTemp:
            type: "number"

    template: "ChronoThermDevice"

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @cas1 = lastState?.cas1?.value or 0
      @cas2 = 0
      @cas3 = 0
      @cas4 = 0
      @cas5 = 0
      @cas6 = 0
      @cas7 = 0
      @realtemperature = 0
      @result = 0
      @perweb = 0
      @setMode(lastState?.mode?.value or "auto")
      @intattivo = 0
      @setManuTemp(lastState?.manuTemp?.value or 20)
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
                env.logger.debug name, val
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

    errori: (name, val) ->
      if @intattivo is 1
        clearTimeout @intervalId
        @intattivo = 0
      @errore = 0
      if (/([^0-9\,\.])/g.test(val)) #check if it's only numbers and , .
        env.logger.debug "Inside character error"
        @errore = 1
      if val % 2 is 0 #check if all numbers are even
        env.logger.debug "Inside odd error"
        @errore = 1
      conteggio = val.toString().split(',')
      if conteggio[1]? and conteggio[1]*1000 isnt 0 #check if second number is 0
        env.logger.debug "Inside 0 error"
        @errore = 1
      for elementi in conteggio[1..] by 2
        moltiplica = elementi * 100
        if moltiplica > 2359 #check if all hours are logical
          env.logger.debug "Inside hours error"
          @errore = 1
      if @errore is 1 #tutto ok procedi
        @errore = 0
        val = 0
      @_setAttribute name, val
      @errore_giorni()

    errore_giorni: () ->
      acas1 = @cas1.toString().split(',')
      acas2 = @cas2.toString().split(',')
      acas3 = @cas3.toString().split(',')
      acas4 = @cas4.toString().split(',')
      acas5 = @cas5.toString().split(',')
      acas6 = @cas6.toString().split(',')
      acas7 = @cas7.toString().split(',')

      array_giorni = acas1[0] + acas2[0] + acas3[0] + acas4[0] + acas5[0] + acas6[0] + acas7[0]
      somma_giorni = 0
      for numeri in array_giorni
        aggiungi = Number(numeri)
        somma_giorni+=aggiungi
      if somma_giorni isnt 28 # 1+2+3+4+5+6+7 = 28
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

    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()

    requestValue: () ->
      l01 = @cas1
      l02 = @cas2
      l03 = @cas3
      l04 = @cas4
      l05 = @cas5
      l06 = @cas6
      l07 = @cas7
      array01 = []
      tempo = new Date()
      ora = tempo.getHours() #prende solo l'ora non i minuti / get the hours
      minuti = tempo.getMinutes() #get the minutes
      if minuti < 10    # corregge problema dello 0 nei minuti minori di 10
        orario = "#{ora}.0#{minuti}" # correct when minutes less then 10 add a 0
      else
        orario = "#{ora}.#{minuti}"
      orario = Math.round(orario*100)
      giornods = tempo.getDay() #numero del giorno della settimana
      if giornods is 0  # get the number of the day and change sunday to 7
        giornods = 7
      lista_variabili = [[l01],[l02],[l03],[l04],[l05],[l06],[l07]]# multi array
      for i in lista_variabili     # find the right day inside multi array
        test = @trova_giorno(giornods, i)
        if test
          array01 = test  #return the right array
      if array01.length > 0
        lung_array01 = array01.length #trova la lunghezza dell'array / find array length
        array_esatto = array01
        array01.shift() #elimina il primo dato dall'array / delete the first value of array
      else
        array01 = []
      array_orari = (x for x in array01 by 2) #prende solo i dati pari (orari) / take values by 2
      nao = for valore_array_orari in array_orari #porta ogni valore a *100, problemi bug
        Math.round(valore_array_orari*100)     #all values *100 to solve a bug
      nao.push(2359) #aggiunge il valore 2359 alla fine dell' array
                     #insert 2359 to the end of array
      for valore_array_orari, pao in nao
        if orario >= nao[pao] and orario < nao[pao + 1] #find the position of the right value
          autoTemp = array_esatto[(pao * 2)+1]
      @_autoTemp = Number(autoTemp)
      if @_mode is "auto"
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

    _setAttribute: (attributeName, value) ->
      if @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value

    setMode: (mode) ->
      if mode is @_mode then return
      switch mode
        when 'auto'
          @result = @_autoTemp
          @emit "result", @result
        when 'manu'
          @result = @_manuTemp
          @emit "result", @result
        when 'on'
          if @config.interface is 0
            @result = @config.ontemperature
          else
            @result = 1
          @emit "result", @result
        when 'boost'
          @result = 50
          @emit "result", @result
        when 'off'
          if @config.interface is 0
            @result = @config.offtemperature
          else
            @result = 0
          @emit "result", @result
      @_mode = mode
      @emit "mode", @_mode
      return Promise.resolve()

    setManuTemp: (manuTemp) ->
      if manuTemp is @_manuTemp then return
      @_manuTemp = manuTemp
      if @_mode is "manu"
        @result = @_manuTemp
        @emit "result", @result
      @emit "manuTemp", @_manuTemp
      return Promise.resolve()

    # Actions : called from UI & rules
    changeModeTo: (mode) ->
      @setMode(mode)
      return Promise.resolve()

    changeTemperatureTo: (manuTemp) ->
      @setMode('manu')
      @setManuTemp(manuTemp)
      return Promise.resolve()

    getManuTemp: () ->  Promise.resolve(@_manuTemp)
    getMode: () ->  Promise.resolve(@_mode)
    getAutoTemp: () -> Promise.resolve(@_autoTemp)
    getPerweb: () -> Promise.resolve(@perweb)
    getResult: () -> Promise.resolve(@result)
    getRealTemperature: () -> Promise.resolve(@realtemperature)
    getCas1: () -> Promise.resolve(@cas1)
    getCas2: () -> Promise.resolve(@cas2)
    getCas3: () -> Promise.resolve(@cas3)
    getCas4: () -> Promise.resolve(@cas4)
    getCas5: () -> Promise.resolve(@cas5)
    getCas6: () -> Promise.resolve(@cas6)
    getCas7: () -> Promise.resolve(@cas7)

  plugin = new ChronoThermPlugin
  return plugin
