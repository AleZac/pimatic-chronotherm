$(document).on( "templateinit", (event) ->

  class CronoAccesoSpentoItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      # Do something, after create: console.log(this)

      @stringa_dati = @getAttribute('perweb').value()


    afterRender: (elements) ->
      super(elements)
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
        alt = Math.round(nuovovalore) + 1 # regolo l'altezza in base al max valore dei gradi
        barra = {orario: valore1, temperatura: "#{valore2}°", posizione: "#{pos}%", larghezza: "#{larg}%", altezza: "#{alt}%"}
        tabella.push(barra)
      return tabella



  pimatic.templateClasses['CronoAccesoSpentoDevice'] = CronoAccesoSpentoItem
)
