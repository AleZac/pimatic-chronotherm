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
  "realtemperature": "$switch.manuTemp",
  "interval": 240,
  "offtemperature": 4,
  "ontemperature" : 30
}
```

In pimatic started by creating a variable named $di1
The variable is to be filled in this way…

Example:
- ***1***,0,10,12.00,25

***1*** the number equivalent to the day of the week that this will make the programming of the following numbers (hours).
In this case monday ( 1 is monday, 2 is Tuesday, 3 is Wednesday… 7 is Sunday)

Subsequent numbers are respectively the hours followed by the temperature in that time.
- 1,***0***,*10*,12.00,25

At **midnight** (the second number between commas is 0) sets the temperature at *10* grades(the third number between commas is 10) and then the plugin sets the variable $ ID.result = 10

- 1,0,10,***12.00***,*25*

At ***noon*** sets the temperature to *25* grades ($ ID.result = 25)

You can add as many hours as you want with respective temperature,
important is that the first number of hours is always 0 (midnight)

Example:
- 1,0,15,8.20,18,12.00,22,15.30,25

Mondays from midnight 15° then at 8.20 18°,at 12.00 22° and at 15.30 25°

If you want the same program will be repeated for other days
just enter the day number of the week in the first number before the comma
example
- 1, x, y, x, y … Monday Only
- 12, x, y, x, y … Monday and Tuesday
- 125, x, y, x, y … Monday Tuesday and Friday
- 1234567, x, y, x, y … all week

I have included the link to 7 variables (cas Ref 1, Ref 2 cas, cas3Ref …) if you need a different schedule for every day of the week.
You can create only those you use.
For those who do not use, the value of its variable must be 0

IMPORTANT is that every days of the week must be present in a variable
See EXAMPLE

***realtemperature*** is the link to a variable sensor that detects the temperature in real time, it will then be displayed in the green circle of the web interface.

***interval*** is the cycle in seconds for updating the schedule.
240 seconds should be sufficient.

***offtemperature*** is the temperature when you put to OFF

***ontemperature*** is the temperature when you put to ON

***Rule to work with Pimatic***

To set the temperature of you thermostat, you have to set a rule like this:
```
$room.result --> is the actually SetPoint of your ChronoThermDevice
```
```
when $room.result changes then set temp of Thermostat to $room.result
```

###WEB INTERFACE

***The green circle*** indicates the actual temperature detected

***The blue circle*** indicates the supposed temperature programming

***Auto*** indicates that the supposed temperature will be based on the schedule

***Manu*** indicates that the supposed temperature will be to set manually

***On*** will set the supposed temperature to ***"ontemperature"***

***OFF*** will set the supposed temperature to ***"offtemperature"***

Once click to ***Manu***,***On***,***Off*** It will be asked how long you should be active that function

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
- $di1=123456,0,19,12.02,21,21.30,18
- $di2=7,0,18,11,4,17.50,22
- $di3=0

so…variable =
* $di1 = Monday Tuesday Wednesday Thursday Friday Saturday
  * at midnight -> 19°,
  * at 12.02 -> 21°
  * and from 21.30 to 23.59 -> 18°
variable =
* $di2 = Sunday
  * at midnight -> 18°,
  * at 11.00 -> 4°
  * and from 17.50 to 23.59 -> 22°

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
- $di1=1,0,19,14,21,21.30,18
- $di2=2,0,13,12.02,21,21.30,18
- $di3=3,0,19,11,21,21.30,18
- $di4=4,0,11,15,21,21.30,18
- $di5=5,0,19,12.02,21,21.30,18
- $di6=6,0,18,11,4,17.50,22
- $di7=7,0,20,16,17

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
- $di1=123456,0,***1***,12.02,***0***,21.30,***1***
- $di2=7,0,***1***,11,***0***,17.50,***1***
- $di3=0
