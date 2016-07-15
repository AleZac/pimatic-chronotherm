module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = env.require 'lodash'

  class CronoAccesoSpentoPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("CronoAccesoSpentoDevice", {
        configDef: deviceConfigDef.CronoAccesoSpentoDevice,
        createCallback: (config, lastState) =>
          return new CronoAccesoSpentoDevice(config, lastState)
      })

  plugin = new CronoAccesoSpentoPlugin

  class CronoAccesoSpentoDevice extends env.devices.Device

    cas1: 0
    cas2: 0
    cas3: 0
    cas4: 0
    cas5: 0
    cas6: 0
    cas7: 0
    result: 0

    attributes:
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
      result:
        description: "Result"
        type: "string"

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @cas1 = lastState?.cas1?.value or 0;
      @cas2 = lastState?.cas2?.value or 0;
      @cas3 = lastState?.cas3?.value or 0;
      @cas4 = lastState?.cas4?.value or 0;
      @cas5 = lastState?.cas5?.value or 0;
      @cas6 = lastState?.cas6?.value or 0;
      @cas7 = lastState?.cas7?.value or 0;
      @result = lastState?.result?.value or 0;

      @varManager = plugin.framework.variableManager #so you get the variableManager
      @_exprChangeListeners = []
      
      for reference in [
        {name: "cas1", expression: @config.cas1Ref},
        {name: "cas2", expression: @config.cas2Ref},
        {name: "cas3", expression: @config.cas3Ref}
        {name: "cas4", expression: @config.cas4Ref}
        {name: "cas5", expression: @config.cas5Ref}
        {name: "cas6", expression: @config.cas6Ref}
        {name: "cas7", expression: @config.cas7Ref}
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
                when "numeric" then @varManager.evaluateStringExpression(info.tokens)
                else
                  assert false
            ).then((val) =>
              if val
                env.logger.debug name, val
                @_setAttribute name, val
              return @[name]
            )
          )
          @_createGetter(name, evaluate)
      super()
      setInterval( ( => @requestValue() ), 120 * 1000) # do the loop every 2 minutes
      
      
    destroy: () ->
      @varManager.cancelNotifyOnChange(cl) for cl in @_exprChangeListeners
      super()
    
    requestValue: ->
      l01 = @_fromVariableValue(@cas1)
      l02 = @_fromVariableValue(@cas2)
      l03 = @_fromVariableValue(@cas3)
      l04 = @_fromVariableValue(@cas4)
      l05 = @_fromVariableValue(@cas5)
      l06 = @_fromVariableValue(@cas6)
      l07 = @_fromVariableValue(@cas7)
      
      console.log l01
      console.log l02
      console.log l03
      console.log l04
      console.log l05
      console.log l06
      console.log l07
      
      
      tempo = new Date()
      ora = tempo.getHours() #prende solo l'ora non i minuti / get the hours
      minuti = tempo.getMinutes() #get the minutes
      if minuti < 10                  # corregge problema dello 0 nei minuti minori di 10
        orario = "#{ora}.0#{minuti}"  # correct when minutes less then 10 add a 0
      else
        orario = "#{ora}.#{minuti}"
      orario = Math.round(orario*100)

      giornods = tempo.getDay() #numero del giorno della settimana
      if giornods is 0          # get the number of the day and change sunday to 7
        giornods = 7
            
      lista_variabili = [[l01],[l02],[l03],[l04],[l05],[l06],[l07]]# create a multi array
      for i in lista_variabili     # find the right day inside multi array
        test = @trova_giorno(giornods, i)
        if test
          array01 = test  #return the right array
          
      
      lung_array01 = array01.length #trova la lunghezza dell'array / find array lenght
      array_esatto = array01
      array01.shift() #elimina il primo dato dall'array / delete the first value of array
      array_orari = (x for x in array01 by 2) #prende solo i dati pari (orari) / take values by 2
        
      nao = for valore_array_orari in array_orari #porta ogni valore a *100, problemi bug
        Math.round(valore_array_orari*100)        #all values *100 to solve a bug
      nao.push(2359) #aggiunge il valore 2359 alla fine dell' array / insert 2359 to the end of array
      
      for valore_array_orari, pao in nao
        if orario >= nao[pao] and orario < nao[pao + 1] #find the position of the right value
          risultato = array_esatto[(pao * 2)+1] 

      env.logger.debug 'result of cas', @_toVariableValue(risultato)
      @_setAttribute 'result of cas', @_toVariableValue(risultato)

    trova_giorno: (giornods, array01) ->
      array01 = array01.toString().split(',') # trasforma variabile in un array di numeri
                                              # transform string to array
      yyy = array01[0] #prende il primo dato dell' array / get the first value of array
      array_dei_giorni = yyy.split('')  # trasforma il primo numero nell'array dei giorni
                                        # transform the first value to a string
      array_dei_numeri = array_dei_giorni.map(Number) # trasforma la stringa di array in un array di numeri
      if giornods in array_dei_numeri                 # transform the string of day to a new array
        return array01

    _setAttribute: (attributeName, value) ->
      if @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value

    _fromVariableValue: (t) ->
      return t

    _toVariableValue: (t) ->
      return t

    getResult: -> Promise.resolve(@result)

  return plugin
