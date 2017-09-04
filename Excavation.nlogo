extensions [csv  bitmap]
breed [flagmen flagman]
breed [trucks truck]
breed [loaders loader]
breed [material dirt]

__includes ["loaders.nls" "routesegments.nls"]

globals [
  ramp-up?
  ramp-down?
]

patches-own [
  is-ramp?          ;; part of the ramp
  is-excavated?     ;; in the area to be excavated
]

trucks-own [
  road              ;; section of road the truck is currently on
  target            ;;
  using-ramp?       ;; is this truck on the ramp?
  loaderid          ;; which loader is this truck going to?
  loading?
  loaded            ;; quantity loaded (scoops * scoop-size)
  take-a-dump
  contaminated?
]



flagmen-own [
  is-out?                ;; true/false - guy on the way out of the site
  countdown
  id
]

to setup
  set-route-constants

  clear-turtles


  ask patches [
    set is-ramp? false
    set is-excavated? false
    set pcolor white
  ]

  import-drawing "site_noramp.png"

  set ramp-up? false
  set ramp-down? true


if use-ramp? [
  ask patches with [pxcor >= -1 and pxcor <= 1 and pycor >= -4 and pycor <= 6] [
    set is-ramp? true
    set pcolor 57
  ]
    ask patches with [(pxcor = -5 and pycor = 3) or (pxcor = -4 and pycor = 1) or (pxcor = -3 and pycor = -1) or (pxcor = -2 and pycor = -3)
                                                 or (pxcor = -3 and pycor = 2)   or (pxcor = -2 and pycor = 3)  or (pxcor = -2 and pycor = 0)
      or (pxcor = 2 and pycor = 3) or (pxcor = 2 and pycor = 0) or (pxcor = 2 and pycor = -3)
      or (pxcor = 3 and pycor = 2) or (pxcor = 3 and pycor = -1) or (pxcor = 4 and pycor = 1) or (pxcor = 5 and pycor = 3)
    ]
    [ set pcolor 7]
]

  setup-trucks number-trucks false  42
  setup-trucks cont-number-trucks true  72

  ask patches with [pxcor >= -8 and pxcor <= -2 and pycor >= -12 and pycor <= 3] [
    set is-excavated? true
  ]

;;  init-loaders
read-loaderlist


create-flagmen 1 [
  setxy -10 5
      set shape "person construction"
      set color 65
      set size 2
      set countdown time-wait-exit
      set id 1
]
create-flagmen 1 [
  setxy 12 7
      set shape "person construction"
      set color red
      set size 2
      set countdown time-wait-exit
      set id 2
]
reset-ticks
end

to setup-trucks [num-trucks is-contaminated?  colour]
  create-trucks num-trucks [
    set color colour + who
    set size 2
    set shape "truck"
    setxy -11 -15
    set using-ramp? false
    set loading? false
    set road road-to-entrance
    set target dest-entrance
    face-nowrap target
    set take-a-dump 0
    set contaminated? is-contaminated?
]
end

to go
  if  material-remaining <= 0 and cont-material-remaining <= 0 [stop]

  ask trucks with [loading? = true] [
    get-loader
  ]
  ask trucks with [loading? = false] [
     move-truck
  ]
  ask loaders [
    scoop
  ]

  ask flagmen [
    flip-sign
  ]
  tick
end

to flip-sign
   set countdown countdown - 1
   if countdown < 1 [
      set countdown random-normal time-wait-exit 1
      ifelse color = red [
         set color 65
     ][
         set color red
     ]
   ]
end

to get-loader
  let myloader  one-of loaders in-radius 1
  let myid [who] of self

  ;; if i am being loaded
  ifelse  [current-truck] of myloader = myid [

    ifelse contaminated? = false [
      ;; if I am full, release the loader
      if loaded >= volume-truck [
        ask myloader [set current-truck -1]
        set loading? false
      ]
    ][
      ;; if I am full, release the loader
      if loaded >= cont-volume-truck [
        ask myloader [set current-truck -1]
        set loading? false
      ]
    ]
  ][

    ;; grab the loader if it is free
    if  [current-truck] of myloader = -1 [
      ask myloader [set current-truck myid]
      set loading? true
    ]
  ]
end


to move-truck
  let exit-light  exit-light-color
  let step-size 1

  ifelse take-a-dump > 0 [
    set take-a-dump take-a-dump - 1
  ][
  if (road = road-to-loader-A or road = road-to-loader-B or road = road-to-bottom-ramp or road = road-to-exit-non-ramp) [
    set step-size pit-pace
  ]
  ifelse (patch-here = dest-site-exit-A  or patch-here = dest-site-exit-B) and exit-light = red [
    ;; at the exit, wait for green to go
  ] [

    ;; not in the pit, follow the route
    let trucks-ahead trucks-on patch-ahead 1
    let all-cool false
    if (count trucks-ahead = 0 or (count trucks-ahead = 1 and member? self trucks-ahead)) [
      set all-cool true
    ]

    ifelse all-cool = true [
      if ramp-ready? = true [
        forward step-size
        if patch-here = target [
           set-next-section
        ]
      ]
    ][
      ;; trucks just stepped into the pit need to step out of the way
      if road = road-to-loader-A or road = road-to-loader-B or road = road-to-bottom-ramp [
        right 90
        set trucks-ahead trucks-on patch-ahead 1
        if count trucks-ahead = 0 [
          forward step-size
        ]
        face-nowrap target
      ]

    ]

    ]
  ]
end

to-report exit-light-color
  let exit-color red
  ask flagmen with [id = 2] [
    set exit-color color
  ]
  report exit-color
end

;; get the total remaining material at each loader
to-report material-remaining
  let remaining  0
  ask loaders with [contaminated? = false] [
    set remaining remaining + remaining-material
  ]
  report remaining
end

to-report cont-material-remaining
  let remaining  0
  ask loaders with [contaminated? = true] [
    set remaining remaining + remaining-material
  ]
  report remaining
end
@#$#@#$#@
GRAPHICS-WINDOW
154
10
591
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
9
22
73
55
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
77
22
140
55
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
620
31
762
91
number-trucks
5.0
1
0
Number

INPUTBOX
791
31
951
91
cont-number-trucks
2.0
1
0
Number

INPUTBOX
7
79
122
139
time-wait-exit
4.0
1
0
Number

INPUTBOX
618
357
700
417
time-unload
30.0
1
0
Number

INPUTBOX
791
357
875
417
cont-time-unload
50.0
1
0
Number

INPUTBOX
620
91
693
151
volume-truck
10.0
1
0
Number

INPUTBOX
791
91
871
151
cont-volume-truck
10.0
1
0
Number

INPUTBOX
693
91
763
151
volume_truck_deviation
1.0
1
0
Number

INPUTBOX
871
91
951
151
cont-volume_truck_deviation
1.0
1
0
Number

INPUTBOX
619
176
695
236
volume-scoop
1.0
1
0
Number

INPUTBOX
791
176
871
236
cont-volume-scoop
1.0
1
0
Number

INPUTBOX
695
176
764
236
volume-scoop-deviation
0.2
1
0
Number

INPUTBOX
871
176
951
236
cont-volume-scoop-deviation
0.2
1
0
Number

INPUTBOX
618
297
765
357
total-volume-excavation
1000.0
1
0
Number

INPUTBOX
791
297
951
357
cont-total-volume-excavation
300.0
1
0
Number

INPUTBOX
619
237
697
297
time-scoop
3.0
1
0
Number

INPUTBOX
791
237
871
297
cont-time-scoop
3.0
1
0
Number

INPUTBOX
697
236
765
296
time-scoop-deviation
0.2
1
0
Number

INPUTBOX
871
236
951
296
cont-time-scoop-deviation
0.2
1
0
Number

SWITCH
6
149
120
182
use-ramp?
use-ramp?
1
1
-1000

MONITOR
6
317
120
362
material-remaining
material-remaining
2
1
11

CHOOSER
6
182
120
227
non-ramp-exit
non-ramp-exit
"A" "B"
0

INPUTBOX
6
240
121
300
pit-pace
0.5
1
0
Number

TEXTBOX
623
11
773
29
Clean soil
11
0.0
1

TEXTBOX
792
11
942
29
Contaiminated\n
11
0.0
1

MONITOR
6
362
120
407
NIL
cont-material-remaining
2
1
11

INPUTBOX
699
357
766
417
time-unload-deviation
7.0
1
0
Number

INPUTBOX
874
357
950
417
cont-time-unload-deviation
10.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

bulldozer top
true
0
Rectangle -7500403 true true 195 60 255 255
Rectangle -16777216 false false 195 60 255 255
Rectangle -7500403 true true 45 60 105 255
Rectangle -16777216 false false 45 60 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -1184463 true true 90 60 75 90 75 240 120 255 180 255 225 240 225 90 210 60
Polygon -16777216 false false 225 90 210 60 211 246 225 240
Polygon -16777216 false false 75 90 90 60 89 246 75 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 211 90 210
Rectangle -16777216 false false 90 60 210 90
Rectangle -1184463 true true 180 30 195 90
Rectangle -16777216 false false 105 30 120 90
Rectangle -1184463 true true 105 45 120 90
Rectangle -16777216 false false 180 45 195 90
Polygon -16777216 true false 195 105 180 120 120 120 105 105
Polygon -16777216 true false 105 199 120 188 180 188 195 199
Polygon -16777216 true false 195 120 180 135 180 180 195 195
Polygon -16777216 true false 105 120 120 135 120 180 105 195
Line -1184463 true 105 165 195 165
Circle -16777216 true false 113 226 14
Polygon -1184463 true true 105 15 60 30 60 45 240 45 240 30 195 15
Polygon -16777216 false false 105 15 60 30 60 45 240 45 240 30 195 15

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -7500403 true true 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285
Polygon -7500403 true true 105 90 60 195 90 210 105 195 105 180 105 90

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
