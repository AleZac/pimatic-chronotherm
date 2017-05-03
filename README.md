#Pimatic ChronoTherm
Thermostat plugin for the Pimatic

![alt tag](https://github.com/AleZac/pimatic-chronotherm/blob/master/screenshot/ChronoTherm.png)

###Configuration
To include the plugin in pimatic add the device to plugin section with...
```
{
  "plugin": "chronotherm"
},
```
then add device to config.json
```
{
  "id": "room",
  "class": "ChronoThermDevice",
  "name": "Room",
  "cas1Ref": "$di1",
  "cas2Ref": "$di2",
  "cas3Ref": "$di3",
  "cas4Ref": "$di4",
  "cas5Ref": "$di5",
  "cas6Ref": "$di6",
  "cas7Ref": "$di7",
  "sum1Ref": "$sa1",
  "sum2Ref": "$sa2",
  "sum3Ref": "$di3",
  "sum4Ref": "$di4",
  "sum5Ref": "$di5",
  "sum6Ref": "$di6",
  "sum7Ref": "$di7",
  "realtemperature": "$switch.manuTemp",
  "interval": 240,
  "offtemperature": 4,
  "ontemperature" : 30
}
```

In pimatic started by creating a variable named $di1
The variable is to be filled in this way…

Example:
- ***1***,00:00,10,12:00,25

***1*** the number equivalent to the day of the week that this will make the programming of the following numbers (hours).
In this case monday ( 1 is monday, 2 is Tuesday, 3 is Wednesday… 7 is Sunday)

Subsequent numbers are respectively the hours followed by the temperature in that time.
- 1,***00:00***,*10*,12:00,25

At **midnight** (the second number between commas is 0) sets the temperature at *10* grades(the third number between commas is 10) and then the plugin sets the variable $ ID.result = 10

- 1,0,10,***12:00***,*25*

At ***noon*** sets the temperature to *25* grades ($ ID.result = 25)

You can add as many hours as you want with respective temperature,
important is that the first number of hours is always 0 (midnight)

Example:
- 1,00:00,15,08:20,18,12:00,22,15:30,25

Mondays from midnight 15° then at 08:20 18°,at 12:00 22° and at 15:30 25°

If you want the same program will be repeated for other days
just enter the day number of the week in the first number before the comma
example
- 1, x, y, x, y … Monday Only
- 12, x, y, x, y … Monday and Tuesday
- 125, x, y, x, y … Monday Tuesday and Friday
- 1234567, x, y, x, y … all week

I have included the link to 7 variables (cas Ref 1, Ref 2 cas, cas3Ref …) if you need a different schedule for every day of the week.
You can create only those you use.

***For those who do not use, the value of its variable must be 0***

IMPORTANT is that every days of the week must be present in a variable
See EXAMPLE

When the ***realtime temperature*** is lower then the ***result*** of the schedule or of the manual mode the plugin set ***valve*** (variable) to true

If you insert
```
"showseason": true,
```
a new function is added to the plugin.
Now you can control the winter and the summer
When summer is active the plugin no longer work with cas1Ref,cas2Ref.... but with sum1Ref,sum2Ref,sum3Ref,sum4Ref,sum5Ref,sum6Ref,sum7Ref.
To compile sum1Ref....... the rules are the same but the variable ***valve*** work in reverse
When the ***realtime temperature*** is greater then the ***result*** of the schedule or of the manual mode the plugin set ***valve*** (variable) to true

***If you are not interested about the "Season" you can set sum1Ref,sum2Ref,sum3Ref,sum4Ref,sum5Ref,sum6Ref,sum7Ref with a variable that is 0***

***realtemperature*** is the link to a variable sensor that detects the temperature in real time, it will then be displayed in the green circle of the web interface.

***interval*** is the cycle in seconds for updating the schedule.
240 seconds should be sufficient.

***offtemperature*** is the temperature when you put to OFF

***ontemperature*** is the temperature when you put to ON

***boost*** if you are interested to boost function, add in config.json the line
```
"boost": true,
```
A button will appear in the 'interface which, when pressed, will set the "mode" to "boost"


###Rule to work with Pimatic

To set the temperature of you thermostat, you have to set a rule like this:
```
$room.result --> is the actually SetPoint of your ChronoThermDevice
```
```
when $room.result changes then set temp of Thermostat to $room.result
```
To enable your thermostat
```
$room.valve --> is the on/off of your ChronoThermDevice
```
```
valve of room is true then set YOUR_THERMOSTAT to ON
```
To set the temperature to 10° in manualmode for 2 hours(120min)( after 2 hour turn back to schedule in automatic) after you click on a dummy-switch
```
if dummy-switch is turned on then set temp of ROOM to 10 and set mode of ROOM to "manu" and set minute to automode of ROOM to 120
```
TRICK:
If you want to set from rule the min to automode to End of Day, set minute to automode to 0.307
If you want to set from rule the min to automode to End of Schedule, set minute to automode to 0.305

###WEB INTERFACE

***Plus Button*** open graph interface

***Minus Button*** close graph interface

***The green circle*** indicates the actual temperature detected

***The blue circle*** indicates the supposed temperature programming

When the border of ***The blue circle*** is ***green*** the valve variable is true

When the border of ***The blue circle*** is ***white*** the valve variable is false

***Auto*** indicates that the supposed temperature will be based on the schedule

***Manu*** indicates that the supposed temperature will be to set manually

***On*** will set the supposed temperature to ***"ontemperature"***

***OFF*** will set the supposed temperature to ***"offtemperature"***

Once click to ***Manu***,***On***,***Off*** It will be asked how long you should be active that function
Buttons that appear are respectively: add 1 minute, add 5 minutes, add 30 minutes, add 1 hour, add 1 day, add minute to the End Of the Day(***EOD***), add minutes to the end of the schedule(***EOS***) and ALWAYS

***winter or summer*** show the season current

### API
To set mode from API
  http://host:port/api/device/ROOM/changeModeTo?mode=MODE
    ROOM = Id of the room
    MODE = auto, manu, on, off
To set mintoautomode
  http://host:port/api/device/ROOM/changeMinToAutoModeTo?mintoautomode=XXX
    XXX = minute tu turn to automode(Normal schedule)
  TRICK:  if you want to set mintoautomode to End of Day, XXX = 0.307
          if you want to set mintoautomode to End of Schedule, XXX = 0.305
To set season
  http://host:port/api/device/ROOM/changeSeasonTo?season=SEASON
    SEASON = winter, summer
To change manual temperature
  http://host:port/api/device/ROOM/changeTemperatureTo?manuTemp=TEMPERATURE


###EXAMPLE 1
```
  "cas1Ref": "$di1",
  "cas2Ref": "$di2",
  "cas3Ref": "$di3",
  "cas4Ref": "$di3",
  "cas5Ref": "$di3",
  "cas6Ref": "$di3",
  "cas7Ref": "$di3",
```
- $di1=123456,0,19,12:02,21,21:30,18
- $di2=7,0,18,11:00,4,17:50,22
- $di3=0

so…variable =
* $di1 = Monday Tuesday Wednesday Thursday Friday Saturday
  * at midnight -> 19°,
  * at 12:02 -> 21°
  * and from 21:30 to 23:59 -> 18°
variable =
* $di2 = Sunday
  * at midnight -> 18°,
  * at 11:00 -> 4°
  * and from 17:50 to 23:59 -> 22°

All the day of the week are in these two variables then i do not need more variable then i close all assigning all the other variables to $di3 ($di3=0)

The important thing is that every day of the week are included in the first numbers

###EXAMPLE 2
```
  "cas1Ref": "$di1",
  "cas2Ref": "$di2",
  "cas3Ref": "$di3",
  "cas4Ref": "$di4",
  "cas5Ref": "$di5",
  "cas6Ref": "$di6",
  "cas7Ref": "$di7",
```
- $di1=1,00:00,19,14:00,21,21:30,18
- $di2=2,00:00,13,12:02,21,21:30,18
- $di3=3,00:00,19,11:00,21,21:30,18
- $di4=4,00:00,11,15:00,21,21:30,18
- $di5=5,00:00,19,12:02,21,21:30,18
- $di6=6,00:00,18,11:00,4,17:50,22
- $di7=7,00:00,20,16:00,17

In this case all the variables are different because all the days are differents

#Pimatic ChronoTherm lite version
If you want only a simple chrono for ON and OFF

![alt tag](https://github.com/AleZac/pimatic-chronotherm/blob/master/screenshot/ChronoTherm1.png)

Simple add interface : 1 to the config.json

```
{
  "id": "room",
  "class": "ChronoThermDevice",
  "name": "Room",
  "interface": 1,
  "cas1Ref": "$di1",
  "cas2Ref": "$di2",
  "cas3Ref": "$di3",
  "cas4Ref": "$di4",
  "cas5Ref": "$di5",
  "cas6Ref": "$di6",
  "cas7Ref": "$di7",
  "realtemperature": "$switch.manuTemp",
  "interval": 240,
  "offtemperature": 4
}
```

The rules are the same but, instead of entering temperatures, are entered 0 for OFF and 1 for ON

```
  "cas1Ref": "$di1",
  "cas2Ref": "$di2",
  "cas3Ref": "$di3",
  "cas4Ref": "$di3",
  "cas5Ref": "$di3",
  "cas6Ref": "$di3",
  "cas7Ref": "$di3",
```
- $di1=123456,00:00,***1***,12:02,***0***,21:30,***1***
- $di2=7,00:00,***1***,11:00,***0***,17:50,***1***
- $di3=0
