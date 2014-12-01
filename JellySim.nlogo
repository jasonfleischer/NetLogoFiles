breed[ jellies jelly ]
breed[ fishes fish ]

; Note: Variables explained in write up

globals[ day 
         sea-floor-height
         width_of_world
         air-temperature      
         wind-strength         
         maximum-jelly-turn-radius
         ;flocking variables for fish
         minimum-separation
         vision
         max-separate-turn
         max-align-turn
         max-cohere-turn
]

fishes-own[happiness          ; ?? may remove
           age                
           lifespan           
           is-female
           pregnant-due-date 
           flock-mates         
           nearest-neighbor   
]
    
jellies-own[age               
            lifespan            
            number-of-fish-eaten
            max-turn-radius
            is-larva
            ticks-left        
]

patches-own[temperature      
            depth             
            current           
            ; coral related        
            is-seed          
            list-of-branches 
            max-growth       
            coral-colour
] 

to setup
  clear-all
  reset-ticks
  setup-default-values
  setup-patches
  setup-jellies
  setup-fishes
end

to setup-default-values
  set air-temperature random 25
  set wind-strength random 4
  set sea-floor-height 3
  set width_of_world 100
  set maximum-jelly-turn-radius 45
  
  ;flocking vars
  set minimum-separation 1
  set vision 3
  set max-separate-turn 1.5
  set max-align-turn 5
  set max-cohere-turn 3
end

to go
  tick
  move-jellies
  move-fish
  update-environment
  set day floor (ticks / number_of_ticks_in_a_day)
end

;ENVIRONMENT function

to setup-patches
  
  let atmosphere-height 5
  resize-world 0 width_of_world 0 (atmosphere-height + sea-floor-height + water_depth) 
  
  let num-of-seeds floor (percentage_of_coral / 100 * (width_of_world + 1))
  
  ask patches[
    
    if(pycor > sea-floor-height + water_depth)[ ;atmosphere
      set pcolor blue
      set temperature air-temperature
    ]
    if(pycor < sea-floor-height)[ ;seafloor
      set pcolor brown
    ]
    if(pycor >= sea-floor-height and pycor <= sea-floor-height + water_depth)[ ;water
      
      set depth water_depth - (pycor - sea-floor-height) 
      set temperature (getWaterTemperature depth)
      set current (getWaterCurrent depth temperature)
      
      if show_labels[
        if pxcor = 1 [ set plabel round depth ]
        if pxcor = 4 [ set plabel temperature ] 
        if pxcor = 7 [ set plabel current ]
      ]    
      
      ifelse show_current[
         if current = 3[ set pcolor blue - 4 ]
         if current = 2[ set pcolor blue - 3 ]
         if current = 1[ set pcolor blue - 2 ]
         if current = 0[ set pcolor blue - 1 ]
      ][
         set pcolor blue - 2
      ] 
    ]
    
    set is-seed false
    if pycor = sea-floor-height - 1 and pcolor = brown and num-of-seeds > 0[ ; coral
      set pcolor brown - 1
      set num-of-seeds num-of-seeds - 1
      set is-seed true
      set list-of-branches []
      set max-growth 200 ; todo fix
      set coral-colour green + (random 5) 
    ]
  ]
end

to update-environment
  
  ask patches [
     if (pcolor = (red - 2)) and ( ticks mod (max_life_span_of_jellies * number_of_ticks_in_a_day * 2) = 0 )[ ; spawn jellies at same time, every max jelly life span * 2
       set pcolor blue - 2
       if not isCoral patch pxcor (pycor + 1) [ ; todo
         sprout-jellies 1[
           set color white
           set heading 0
           set size 1.5
           set is-larva false
           set max-turn-radius (random maximum-jelly-turn-radius) + 1
           set number-of-fish-eaten 0
           set ticks-left -1 
           set age (random max_life_span_of_jellies) 
           set lifespan (random (max_life_span_of_jellies - age)) + age + 1
         ]
       ]
     ]   
     
     if isWater pcolor [
       if show_current[
         if current = 3[ set pcolor blue - 4 ]
         if current = 2[ set pcolor blue - 3 ]
         if current = 1[ set pcolor blue - 2 ]
         if current = 0[ set pcolor blue - 1 ]
       ]
     ]
     
     if is-seed and ticks mod 10 = 0[ ; try to grow every 10 ticks
       if length list-of-branches < max-growth[ 
       
         let branch nobody
         
         ifelse empty? list-of-branches[
           set branch ( patch pxcor (pycor + 1))
           
           
         ][
           ifelse random-float 1 > 0.5 [ ;grow vertically
              set branch ( one-of list-of-branches )
              set branch patch ([pxcor] of branch) (([pycor] of branch) + 1)
           ][ ; grow horizontally
              set branch ( one-of list-of-branches )
              ifelse random-float 1 > 0.5[
                set branch patch (([pxcor] of branch)+ 1) ([pycor] of branch)
              ][
                set branch patch (([pxcor] of branch)- 1) ([pycor] of branch)
              ]
           ]
         
        ]
         
         if isWater [pcolor] of branch [
           set list-of-branches lput branch list-of-branches
           let coral-clr coral-colour
           ask branch [set pcolor coral-clr]
           
         ] 
        
       ]
     ]
  ]
end


to-report getWaterTemperature [water-depth] 
  let rate-of-depreciation 10
  let result air-temperature - round (water-depth / rate-of-depreciation)
  if result <= 4 [set result 4]  
  report result
end

to-report getWaterCurrent [water-depth water-temp]
  let rate-of-depreciation 10
  let result wind-strength - round (water-depth / rate-of-depreciation )
  if result <= 0 [set result 0]  
  report result
  report 2
end

to-report isWater [colour]
  ifelse show_current[
     report colour = blue - 4 or colour = blue - 3 or colour = blue - 2 or colour = blue - 1
  ][
     report colour = blue - 2
  ]
end

to-report isCoral [colour]
  report colour = green - 4 or colour = green - 3 or colour = green - 2 or colour = green - 1 or colour = green
end 

;JELLY functions
to setup-jellies
  create-jellies init_number_of_jellies[
    set color white
    set size 1.5
    let rand-patch one-of patches with [isWater pcolor]
    while [not any? turtles-here] [
      set rand-patch one-of patches with [isWater pcolor]
    ]
    
    set xcor [pxcor] of rand-patch
    set ycor [pycor] of rand-patch
    set heading 0 ; for now
    set is-larva false
    set max-turn-radius (random maximum-jelly-turn-radius) + 1
    set number-of-fish-eaten 0
    set ticks-left -1 
    set age (random max_life_span_of_jellies) 
    set lifespan (random (max_life_span_of_jellies - age)) + age + 1
    if age >= lifespan [ ; remove later
      print "error1" 
    ]
    if  lifespan >  max_life_span_of_jellies [ ; remove later
        print "error"    
    ]
  ]
end

to move-jellies
  ask jellies[
    
    ifelse is-larva[
      ifelse isWater [pcolor] of patch-ahead 1  [
        forward 1
      ][
        if number-of-fish-eaten > 5 [
            ask patch-here [ ; generate polyp
              set pcolor red - 2 
            ]   
        ]
        die
      ]
      
    ][ ; if jelly
    
       if ticks mod 4 = 0  [ ; turn every 4 ticks
          ifelse not isWater [pcolor] of patch-ahead 1 [
           set heading heading - ((random 20) + 170)
         ][
           ifelse random-float 1 > 0.5[
             set heading heading + (random max-turn-radius)
           ][
             set heading heading - (random max-turn-radius)
           ]
         ]
       ]
       if ticks mod 5 = 0  and  isWater [pcolor] of patch-ahead 1  [ ; move every 5 ticks if possible
          forward 1
       ]
    
       if any? fishes-here [ ; eat
          set number-of-fish-eaten number-of-fish-eaten + 1
          ask one-of fishes-here [ die ]
          set lifespan min list (lifespan + 2) max_life_span_of_jellies
       ]
    
       if day != floor (ticks / number_of_ticks_in_a_day)[ ; day change
         if color != violet[
           set age age + 1
           if lifespan <= age[
             set ticks-left (random (number_of_ticks_in_a_day - 1) + 2)
             set color violet
           ]
         ] 
       ]
       if (age > lifespan)[ ; remove later
         print "error"
       ]
       
       if(( ticks mod ticks-left = 0 and color = violet)  )[
          set heading 180
          set color red 
          set is-larva true
       ]
       if show_labels[
         set label number-of-fish-eaten
       ]
    ]    
  ]
end

;FISH functions
to setup-fishes
  create-fishes init_number_of_fish[
    
    set size 1
    let rand-patch one-of patches with [isWater pcolor]
    while [not any? turtles-here] [
      set rand-patch one-of patches with [isWater pcolor]
    ]
    set xcor [pxcor] of rand-patch
    set ycor [pycor] of rand-patch
    
    ifelse random-float 1 > 0.5 [ ; male
      set is-female false
      set color yellow - 2
    ][ ; female
      set is-female true
      set color yellow
    ]
    
    set heading (random 20) + 85 ; 85 to 105 degrees
    
    set age (random max_life_span_of_fishes) 
    set lifespan (random (max_life_span_of_fishes - age)) + age + 1
    if age >= lifespan [ ; remove later
      print "error1" 
    ]
    if  lifespan >  max_life_span_of_fishes [ ; remove later
        print "error"    
    ]
  ]
end

to move-fish  
  ask fishes [ 
    
    if day != floor (ticks / number_of_ticks_in_a_day)[ ; day change
        set age age + 1
    ]
    
    if lifespan <= age[ ; die
        die
        stop;
        ;set ticks-left (random (number_of_ticks_in_a_day - 1) + 2)
        ;set color violet
    ]
    
    if is-female and color != pink [ ; get pregnant
      if flock-mates != 0 [
        if any? flock-mates and nearest-neighbor != nobody [ 
          if 
          count flock-mates >= 2 and count flock-mates < 10 and
          age > max_life_span_of_fishes * .5  and [age] of nearest-neighbor > max_life_span_of_fishes * .5 and
          age < max_life_span_of_fishes * .75 and [age] of nearest-neighbor < max_life_span_of_fishes * .75 and
          not [is-female] of nearest-neighbor 
          [ 
            
            set pregnant-due-date (ceiling (0.01 * max_life_span_of_fishes)) * number_of_ticks_in_a_day
            set color pink
         
          ] 
        ]
      ]
    ]
    
    if color = pink [ ; gestation
    
      set pregnant-due-date pregnant-due-date - 1
      if pregnant-due-date = 0[
         let num_of_offspring (random 4) + 3 ; todo more if happier
         hatch-fishes num_of_offspring [ ; give birth
           set size 1
           ifelse random-float 1 > 0.5 [ ; male
              set is-female false
              set color yellow - 2
           ][ ; female
              set is-female true
              set color yellow
           ]
           set heading (random 20) + 85 ; 85 to 105 degrees
           set age 0
           set lifespan (random max_life_span_of_fishes) + 1
         ]
         
         set color yellow
      ]
    ]
    
    ifelse  isWater [pcolor] of patch-ahead 1  or isCoral [pcolor] of patch-ahead 1 [
      flock
      
    ][
      ifelse heading > 90[
        set heading 80
      ][
        set heading 100
      ] 
    ]
  ]
  ask fishes [ forward 1 ]
end

to flock  ;; turtle procedure
  find-flockmates
  if any? flock-mates
    [ find-nearest-neighbor
      ifelse distance nearest-neighbor < minimum-separation
        [ separate ]
        [ align
          cohere ] ]
end

to find-flockmates  ;; turtle procedure
  set flock-mates other fishes in-radius vision
end

to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of flock-mates [distance myself]
end

to separate  
  turn-away ([heading] of nearest-neighbor) max-separate-turn
end
to align 
  turn-towards average-flockmate-heading max-align-turn
end
to cohere  
  turn-towards average-heading-towards-flockmates max-cohere-turn
end

to-report average-flockmate-heading  
  let x-component sum [dx] of flock-mates
  let y-component sum [dy] of flock-mates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to-report average-heading-towards-flockmates  
  let x-component mean [sin (towards myself + 180)] of flock-mates
  let y-component mean [cos (towards myself + 180)] of flock-mates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to turn-towards [new-heading max-turn] 
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  
  turn-at-most (subtract-headings heading new-heading) max-turn
end

to turn-at-most [turn max-turn]  
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

; end of fish functions
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1230
581
-1
-1
10.0
1
10
1
1
1
0
1
0
1
0
100
0
53
0
0
1
ticks
30.0

SLIDER
6
56
201
89
water_depth
water_depth
5
300
45
1
1
NIL
HORIZONTAL

BUTTON
4
10
70
43
NIL
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
72
10
135
43
NIL
go
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
137
10
200
43
NIL
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

PLOT
8
353
202
503
Number of Jellies vs Number of Fish
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count jellies"
"pen-1" 1.0 0 -7500403 true "" "plot count fishes"
"pen-2" 1.0 0 -13840069 true "" "plot count patches with [pcolor = green]"

SLIDER
6
159
202
192
init_number_of_fish
init_number_of_fish
0
1000
1000
1
1
NIL
HORIZONTAL

SLIDER
6
125
201
158
init_number_of_jellies
init_number_of_jellies
0
300
13
1
1
NIL
HORIZONTAL

SLIDER
7
241
203
274
number_of_ticks_in_a_day
number_of_ticks_in_a_day
50
5000
50
1
1
NIL
HORIZONTAL

MONITOR
62
507
112
552
Temp
air-temperature
17
1
11

MONITOR
117
507
167
552
Wind
wind-strength
17
1
11

MONITOR
8
507
58
552
Day
day
17
1
11

SWITCH
8
556
131
589
show_labels
show_labels
1
1
-1000

SLIDER
7
277
202
310
max_life_span_of_jellies
max_life_span_of_jellies
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
6
197
202
230
percentage_of_coral
percentage_of_coral
0
100
16
1
1
NIL
HORIZONTAL

SLIDER
7
314
202
347
max_life_span_of_fishes
max_life_span_of_fishes
10
100
31
1
1
NIL
HORIZONTAL

SWITCH
9
591
131
624
show_current
show_current
1
1
-1000

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
NetLogo 5.1.0
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
