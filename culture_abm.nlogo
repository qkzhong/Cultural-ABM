extensions [vid nw]
globals
[
  reach-num
  elite-centrality
  pop-centrality
  preferential   ;; prefential procedure
  elite-original
]

turtles-own
[
  rich?            ;;social class
  income           ;;income
  resource         ;;current amount resources ture
  elite-culture?   ;;elite culture capital
  pop-culture?     ;;pop culture capital
  elite-downtime   ;;the number of time steps passed since the agent last consumption of elite culture
  pop-downtime     ;;the number of time steps passed since the agent last consumption of pop culture
  potential?       ;;variable in preferential attachment process to avoid double loop ties
]

links-own
[
  contact        ;;steps that the two agents contact each other
  non-contact    ;;steps that the two agents didn't contact each other
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-default-shape turtles "person"
  make-turtles
  ;; at this stage, all the components will be of size 1,
  ;; since there are no edges yet
  reset-ticks
  ;;create wealth distribution
  set reach-num round reach * num-nodes * 0.01 - 1
  set elite-original elite-culture-cost
  ask turtles
  [
    set color grey
    set potential? false
    ifelse random-float 1 > equality
    [
      set income poor-income
      set rich? FALSE
     ]
    [
      set income rich-income
      set rich? TRUE]
    set resource 0
    set elite-culture? FALSE
    set pop-culture? FALSE

  ]
end

to make-turtles
  create-turtles num-nodes [ set size 1 ]
  layout-circle turtles max-pxcor - 1
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  ask turtles
  [
    set potential? false
    ifelse elite-culture?
       [
          ifelse pop-culture?
          [ set color violet
           ]
          [ set color red ]

          ]
       [set color blue]

     set resource resource + income
     ifelse random-float 1.0 < bourdieu-marx
      [marx-cultural-choice]
      [bourdieu-cultural-choice]
    ifelse random-float 1.0 < random-pref
      [preferential-attachment]
      [random-network]


  ]
;  ask turtles [
;    set size count links / 500
;  ]
  layout
  show nw:mean-path-length
 tick

  if shock = true and ticks = 100 [
    set elite-culture-cost pop-culture-cost
  ]
  if recover = true and ticks = 150 [
    set elite-culture-cost elite-original
  ]
let total-r 0
ask turtles with [elite-culture? = true] [set total-r total-r + count my-links]
ifelse count turtles with [elite-culture? = true] > 0
  [
  set  elite-centrality total-r / ((count turtles with [elite-culture? = true] ) * num-nodes)         ; monitor elite culture average degree centrality
  ]
  [set elite-centrality 0]

let total-p 0
ask turtles with [pop-culture? = true] [set total-p total-p + count my-links]
ifelse count turtles with [pop-culture? = true] > 0
  [
  set  pop-centrality total-p / ((count turtles with [pop-culture? = true]) * num-nodes)
  ]
  [
   set  pop-centrality 0
  ]
   ; monitor elite culture average degree centrality



end

to consume-elite-culture
  set pop-culture? FALSE
  set elite-culture? TRUE
  set resource resource - elite-culture-cost
end

to consume-pop-culture
  set elite-culture? FALSE
  set pop-culture? TRUE
  set resource resource - pop-culture-cost
end

to consume-nothing
  set pop-culture? FALSE
  set elite-culture? FALSE
end

to marx-cultural-choice
  ifelse elite-culture-cost >= pop-culture-cost    ;; in case of economic changes
  [
   ifelse resource >= elite-culture-cost ;;people can afford:
    [consume-elite-culture]
  ;;no elite culture -- get elite culture
   [ifelse resource >= pop-culture-cost
    [consume-pop-culture]
    [consume-nothing]
    ;;people cannot afford elite culture will get pop culture if they are not ambitious, otherwise they save up
  ]
  ]
    [
    ifelse resource >= pop-culture-cost ;; buy the best they can afford
    [consume-pop-culture]
      [consume-nothing]
    ]
;    ]
end

to bourdieu-cultural-choice
  let elite-culture-friend count turtles with [link-neighbor? myself and elite-culture?]
  let all-friends count turtles with [link-neighbor? myself]
  ifelse all-friends > 0
    [ifelse random-float 1 < elite-culture-friend / all-friends
      [ifelse resource >= elite-culture-cost
        [consume-elite-culture]
        [consume-nothing]]
      [ifelse resource >= pop-culture-cost
        [consume-pop-culture]
        [consume-nothing]
    ]]   ;;what you consume depends on what your friends consume and your income
  [marx-cultural-choice]

end



to preferential-attachment

     ;;there's a limit to how many people a turtle can reach out to each round, but turtles will reach to their friends first
  ifelse random-float 1.0 > homophily
      [;; not homophily situation
        let strangers count other turtles with [link-neighbor? myself = false]
        if count other turtles with [link-neighbor? myself] > reach-num
        [
          ask min-n-of reach-num other turtles with [link-neighbor? myself][count links]
           [
            ask link who [who] of myself [die]
            ]
         ]
         ifelse strangers > reach-num or strangers < 3
             [
                  let numerator 1
                   ask max-n-of strangers other turtles with [link-neighbor? myself = false] [count links]
                 [
                      if random-float 1.0 < exp(0 - numerator)
                                  [ set potential? true ]
                      set numerator numerator + 1
                   ]

                ]
;; possibility of making tie is exp(-rank)
             [
                   let numerator 1
                   ask max-n-of reach-num other turtles with [link-neighbor? myself = false] [count links]
                     [
                        if random-float 1.0 < exp(0 - numerator)
                                  [ set potential? true ]
                        set numerator numerator + 1
                      ]
              ]
         ]
     [;; homophily situation
         ifelse pop-culture?
           [;;popculture situation
               let strangers count other turtles with [link-neighbor? myself = false and pop-culture?]
               if count other turtles with [link-neighbor? myself] > reach-num
        [
          ask min-n-of reach-num other turtles with [link-neighbor? myself][count links]
           [
            ask link who [who] of myself [die]
            ]
         ]
         ifelse strangers > reach-num or strangers < 3
             [
                  let numerator 1
                   ask max-n-of strangers other turtles with [link-neighbor? myself = false and pop-culture?] [count links]
                 [
                      if random-float 1.0 < exp(0 - numerator)
                                  [ set potential? true ]
                      set numerator numerator + 1
                   ]

                ]
;; possibility of making tie is exp(-rank)
             [
                   let numerator 1
                   ask max-n-of reach-num other turtles with [link-neighbor? myself = false and pop-culture?] [count links]
                     [
                        if random-float 1.0 < exp(0 - numerator)
                                  [ set potential? true ]
                        set numerator numerator + 1
                      ]
              ]
         ]
           [;;elite culture situation
      let strangers count other turtles with [link-neighbor? myself = false and elite-culture?]
               if count other turtles with [link-neighbor? myself] > reach-num
        [
          ask min-n-of reach-num other turtles with [link-neighbor? myself][count links]
           [
            ask link who [who] of myself [die]
            ]
         ]
         ifelse strangers > reach-num or strangers < 3
             [
                  let numerator 1
                   ask max-n-of strangers other turtles with [link-neighbor? myself = false and elite-culture?] [count links]
                 [
                      if random-float 1.0 < exp(0 - numerator)
                                  [ set potential? true ]
                      set numerator numerator + 1
                   ]

                ]
;; possibility of making tie is exp(-rank)
             [
                   let numerator 1
                   ask max-n-of reach-num other turtles with [link-neighbor? myself = false and elite-culture?] [count links]
                     [
                        if random-float 1.0 < exp(0 - numerator)
                                  [ set potential? true ]
                        set numerator numerator + 1
                      ]
              ]]
       ]
   ask other turtles with [potential? = true]
   [create-link-with myself]
  ;; come back to normal
  ask other turtles
   [set potential? false]
end

to random-network
   ifelse random-float 1.0 > homophily
    [;;random network with no homophily
      let strangers count other turtles with [link-neighbor? myself = false]
      ;; random rewire, first give up reach-num number of friends
      if count other turtles with [link-neighbor? myself] > reach-num
      [ask n-of reach-num other turtles with [link-neighbor? myself]
         [ask link who [who] of myself [die]]
       ]
      ;;randomly make friends with reach-num strangers
            ifelse strangers > reach-num
                [ ask n-of reach-num other turtles with [link-neighbor? myself = false]
                         [
                            create-link-with myself
                            [set color blue]
                         ]
                  ]

                 [ask other turtles with [link-neighbor? myself = false]
                       [create-link-with myself
                         [set color blue]
  ]]
  ]

      [;;random network + homophily
   let strangers count other turtles with [link-neighbor? myself = false]
   if pop-culture?[
    if count other turtles with [link-neighbor? myself] > reach-num
      [ask n-of reach-num other turtles with [link-neighbor? myself]
         [if pop-culture? = false
		          [ask link who [who] of myself [die]]]
       ]
                     ;;reach to strangers, if they are not popular, a [randomfriend] chance to form a tie
          ifelse strangers > reach-num
                [ ask n-of reach-num other turtles with [link-neighbor? myself = false]
                                               ;; input homophily
                    [ifelse pop-culture? = false
                       [if random 100 < randomfriend
                            [create-link-with myself
                            [set color blue]
              ]
              ]

                    ;;if they are popular, form the tie
                       [create-link-with myself
                [set color blue]]  ]]
                 [ask other turtles with [link-neighbor? myself = false]
                    [ifelse pop-culture? = false
                       [if random 100 < randomfriend
                            [create-link-with myself
                            [set color blue]]]
                    ;;if they are popular, form the tie
                       [create-link-with myself
                         [set color blue]
  ]]]]

 if elite-culture?[
    if count other turtles with [link-neighbor? myself] > reach-num
      [ask n-of reach-num other turtles with [link-neighbor? myself]
         [if elite-culture? = false
		          [ask link who [who] of myself [die]]]
    ]
                     ;;reach to strangers, if they are not popular, a [randomfriend] chance to form a tie
          ifelse strangers > reach-num
                [ ask n-of reach-num other turtles with [link-neighbor? myself = false]
                    [ifelse elite-culture? = false
                       [if random 100 < randomfriend
                            [create-link-with myself
                            [set color blue]]]
                    ;;if they are popular, form the tie
                       [create-link-with myself
                [set color blue]]  ]]
                 [ask other turtles with [link-neighbor? myself = false]
                    [ifelse elite-culture? = false
                       [if random 100 < randomfriend
                            [create-link-with myself
                            [set color blue]]]
                    ;;if they are popular, form the tie
                       [create-link-with myself
                              [set color blue]]]]]
        ]
end


to layout
  repeat 12 [
    layout-spring turtles links 0.5 10 2
    display
  ]
end

to-report elite-density
  nw:set-context turtles with [elite-culture?] links
  let complete count turtles * ( count turtles - 1 )
  report count my-links / complete
end

to-report pop-density
   nw:set-context turtles with [pop-culture?] links
   let complete count turtles * ( count turtles - 1 )
   report count my-links / complete
end

to-report heterogeneous-ties
  let total-ties 0
  ask turtles with [rich?]
      [set total-ties total-ties + count other turtles with [link-neighbor? myself and rich? = false]]
  report total-ties
end
@#$#@#$#@
GRAPHICS-WINDOW
356
10
793
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

SLIDER
167
262
339
295
equality
equality
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
167
306
339
339
poor-income
poor-income
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
168
353
338
386
rich-income
rich-income
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
29
262
146
295
bourdieu-marx
bourdieu-marx
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
29
302
147
335
homophily
homophily
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
31
400
152
433
reach
reach
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
29
14
201
47
num-nodes
num-nodes
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
29
65
201
98
elite-culture-cost
elite-culture-cost
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
30
109
202
142
pop-culture-cost
pop-culture-cost
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
31
442
152
475
randomfriend
randomfriend
0
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
34
164
97
197
setup
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
117
164
196
197
Go Once
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
35
210
129
243
Go Forever
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
855
10
1194
225
Degree Centrality
Time
Degree
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"Elite Culture" 1.0 0 -2674135 true "" "plot elite-centrality"
"Pop Culture" 1.0 0 -13791810 true "" "plot pop-centrality"

PLOT
857
240
1196
450
Cultural Choice
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Elite Culture" 1.0 0 -2674135 true "" "plot count turtles with [elite-culture? =  TRUE]"
"Pop Culture" 1.0 0 -13791810 true "" "plot count turtles with [pop-culture? = TRUE]"

SWITCH
226
14
329
47
shock
shock
0
1
-1000

SWITCH
228
68
331
101
Recover
Recover
0
1
-1000

MONITOR
174
403
270
448
rich-pop choice
count turtles with [rich?  and pop-culture? ]
17
1
11

PLOT
1236
10
1548
228
Degree Distribution
Degree
# of nodes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "let max-degree max [count link-neighbors] of turtles\nplot-pen-reset  ;; erase what we plotted before\nset-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar\nhistogram [count link-neighbors] of turtles"

SLIDER
30
349
147
382
random-pref
random-pref
0
1
0.0
0.1
1
NIL
HORIZONTAL

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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment behavior" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles with [elite-culture?]</metric>
    <metric>count turtles with [elite-culture? and rich? = false]</metric>
    <metric>count turtles with [pop-culture?]</metric>
    <metric>count turtles with [pop-culture? and rich?]</metric>
    <metric>count turtles with [rich?]</metric>
    <metric>heterogeneous-ties</metric>
    <metric>count links</metric>
    <metric>pop-centrality</metric>
    <metric>elite-centrality</metric>
    <enumeratedValueSet variable="shock">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rich-income">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homo-pref">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.5"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bourdieu-marx">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reach">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elite-culture-cost">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Recover">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomfriend">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pop-culture-cost">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poor-income">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equality">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment behavior shock" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles with [elite-culture?]</metric>
    <metric>count turtles with [elite-culture? and rich? = false]</metric>
    <metric>count turtles with [pop-culture?]</metric>
    <metric>count turtles with [pop-culture? and rich?]</metric>
    <metric>count turtles with [rich?]</metric>
    <metric>heterogeneous-ties</metric>
    <metric>count links</metric>
    <metric>pop-centrality</metric>
    <metric>elite-centrality</metric>
    <enumeratedValueSet variable="shock">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rich-income">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homo-pref">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bourdieu-marx">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reach">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elite-culture-cost">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Recover">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomfriend">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pop-culture-cost">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poor-income">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equality">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment behavior shock boundary" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles with [elite-culture?]</metric>
    <metric>count turtles with [elite-culture? and rich? = false]</metric>
    <metric>count turtles with [pop-culture?]</metric>
    <metric>count turtles with [pop-culture? and rich?]</metric>
    <metric>count turtles with [rich?]</metric>
    <metric>heterogeneous-ties</metric>
    <metric>count links</metric>
    <metric>pop-centrality</metric>
    <metric>elite-centrality</metric>
    <enumeratedValueSet variable="shock">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rich-income">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bourdieu-marx">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-pref">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reach">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elite-culture-cost">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Recover">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomfriend">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pop-culture-cost">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poor-income">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equality">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
