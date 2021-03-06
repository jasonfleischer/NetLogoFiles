links-own [weight]

breed [bias-nodes bias-node]
breed [input-nodes input-node]
breed [output-nodes output-node]
breed [hidden-nodes hidden-node]


turtles-own [
  activation     ;; Determines the nodes output
  err            ;; Used by backpropagation to feed error backwards
]

globals [
  irises
  rand-iris

  
  epoch-error    ;; measurement of how many training examples the network got wrong in the epoch
  input-node-1   ;; keep the input and output nodes in global variables so we can refer to them directly
  input-node-2    
  input-node-3
  input-node-4  
  output-node-1
  output-node-2 
  output-node-3    
]

;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-iris
  
  ask patches [ set pcolor gray ]
  set-default-shape bias-nodes "bias-node"
  set-default-shape input-nodes "circle"
  set-default-shape output-nodes "output-node"
  set-default-shape hidden-nodes "output-node"
  set-default-shape links "small-arrow-shape"
  setup-nodes
  setup-links
  propagate
  reset-ticks
end

to setup-iris
  set irises []
  file-open "iris.txt"
  while [ not file-at-end? ] [
    set irises lput  (list (file-read) (file-read) (file-read) (file-read) (file-read)) irises
  ]
  file-close 
end

to setup-nodes
  create-bias-nodes 1 [ setxy -4 6 ]
  ask bias-nodes [ set activation 1 ]
  
  set rand-iris one-of irises
  create-input-nodes 1 [ ; sepal length
    setxy -6 4
    set input-node-1 self
    set activation normalize (item 0 rand-iris) 4.3 7.9
    ;set activation ((random 37) + 43) / 10 ; 4.3 - 7.9
    set label activation
  ]
  create-input-nodes 1 [ ; sepal width
    setxy -6 2
    set input-node-2 self
    set activation normalize (item 1 rand-iris) 2 4.4
    ;set activation ((random 25) + 20) / 10 ; 2 - 4.4
    set label activation
  ]
  
  create-input-nodes 1 [ ; petal length
    setxy -6 0
    set input-node-3 self
    set activation normalize (item 2 rand-iris) 1 6.9
    ;set activation ((random 60) + 10) / 10 ; 1 - 6.9
    set label activation
  ]
  
  create-input-nodes 1 [ ; petal width
    setxy -6 -2
    set input-node-4 self
    set activation normalize (item 3 rand-iris) 0.1 2.9
    ;set activation ((random 29) + 1) / 10 ; 0.1 - 2.9
    set label activation
  ]
  
  ;ask input-nodes [ set activation random 2 ]
  create-hidden-nodes 1 [ setxy 0 -2 ]
  create-hidden-nodes 1 [ setxy 0  2 ]
  ask hidden-nodes [
    set activation random 2
    set size 1.5
  ]
  create-output-nodes 1 [
    setxy 5 -2
    set output-node-1 self
    set activation random 2
  ]
  create-output-nodes 1 [
    setxy 5 0
    set output-node-2 self
    set activation random 2
  ]
  create-output-nodes 1 [
    setxy 5 2
    set output-node-3 self
    set activation random 2
  ]
end

to setup-links
  connect-all bias-nodes hidden-nodes
  connect-all bias-nodes output-nodes
  connect-all input-nodes hidden-nodes
  connect-all hidden-nodes output-nodes
end

to connect-all [nodes1 nodes2]
  ask nodes1 [
    create-links-to nodes2 [
      set weight random-float 0.2 - 0.1
    ]
  ]
end

to recolor
  ask turtles [
    set color white
  ]
  ask input-nodes [ set color green ]
  ask links [
    set thickness 0.05 * abs weight
    ifelse show-weights? [
      set label precision weight 4
    ] [
      set label ""
    ]
    ifelse weight > 0
      [ set color [ 255 0 0 196 ] ]   ; transparent red
      [ set color [ 0 0 255 196 ] ] ; transparent light blue
  ]
end

;;;
;;; TRAINING PROCEDURES
;;;

to train
  set epoch-error 0
  repeat examples-per-epoch [
    ;ask input-nodes [ 
     ; set activation random 2 
      ;set label activation
    ;]
    set rand-iris one-of irises
    ask input-node-1 [
      set activation normalize (item 0 rand-iris) 4.3 7.9
      ;set activation ((random 37) + 43) / 10 ; 4.3 - 7.9
      set label activation
    ]
    ask input-node-2 [ 
      set activation normalize (item 1 rand-iris) 2 4.4
      ;set activation ((random 25) + 20) / 10 ; 2 - 4.4
      set label activation
    ]
    ask input-node-3 [ 
      set activation normalize (item 2 rand-iris) 1 6.9
      ;set activation ((random 60) + 10) / 10 ; 1 - 6.9
      set label activation
    ]
    ask input-node-4 [ 
      set activation normalize (item 3 rand-iris) 0.1 2.9
      ;set activation ((random 29) + 1) / 10 ; 0.1 - 2.9
      set label activation
    ]
    
    propagate
    back-propagate
  ]
  set epoch-error epoch-error / examples-per-epoch
  tick
end

;;;
;;; FUNCTIONS TO LEARN
;;;

to-report target-answer
  ;let a [activation] of input-node-1 = 1
  ;let b [activation] of input-node-2 = 1
  ;; run-result will interpret target-function as the appropriate boolean operator
  ;report ifelse-value run-result
   ; (word "a " target-function " b") [1][0]
   report item 4 rand-iris
end

;;;
;;; PROPAGATION PROCEDURES
;;;

;; carry out one calculation from beginning to end
to propagate
  ask hidden-nodes [ set activation new-activation ]
  ask output-nodes [ set activation new-activation ]
  recolor
end

;; Determine the activation of a node based on the activation of its input nodes
to-report new-activation  ;; node procedure
  report sigmoid sum [[activation] of end1 * weight] of my-in-links
end

;; changes weights to correct for errors
to back-propagate
  let example-error 0
  let answer target-answer
  let e1 0
  let e2 0

  

  ask output-node-1 [
    if target-answer = 0 [ set answer 1 ]
    if target-answer = 1 [ set answer 0 ]
    if target-answer = 2 [ set answer 0 ]
    set err activation * (1 - activation) * (answer - activation)
    set example-error example-error + ( (answer - activation) ^ 2 ) / 3
  ]
  
  set e1 example-error
  
  ask hidden-nodes [
    set err activation * (1 - activation) * sum [weight * [err] of end2] of my-out-links
  ]
  ask links [
    set weight weight + learning-rate * [err] of end2 * [activation] of end1 / 3
  ]
  
  
  
  ask output-node-2 [
    if target-answer = 0 [ set answer 0 ]
    if target-answer = 1 [ set answer 1 ]
    if target-answer = 2 [ set answer 0 ]
    set err activation * (1 - activation) * (answer - activation)
    set example-error example-error + ( (answer - activation) ^ 2 ) / 3
  ]
  
  set e2 example-error
  
  ask hidden-nodes [
    set err activation * (1 - activation) * sum [weight * [err] of end2] of my-out-links
  ]
  ask links [
    set weight weight + learning-rate * [err] of end2 * [activation] of end1
  ]
  
  
  
  ask output-node-3 [
    if target-answer = 0 [ set answer 0 ]
    if target-answer = 1 [ set answer 0 ]
    if target-answer = 2 [ set answer 1 ]
    set err activation * (1 - activation) * (answer - activation)
    set example-error example-error + ( (answer - activation) ^ 2 ) / 3
  ]
  
  set epoch-error epoch-error + ( e1 + e2 + example-error ) / 3
  
  ;; The hidden layer nodes are given error values adjusted appropriately for their
  ;; link weights
  ask hidden-nodes [
    set err activation * (1 - activation) * sum [weight * [err] of end2] of my-out-links
  ]
  ask links [
    set weight weight + learning-rate * [err] of end2 * [activation] of end1
  ]
end

;;;
;;; MISC PROCEDURES
;;;

;; computes the sigmoid function given an input value and the weight on the link
to-report sigmoid [input]
  report 1 / (1 + e ^ (- input))
end

;; computes the step function given an input value and the weight on the link
to-report step [input]
  report ifelse-value (input > 0.5) [1][0]
end

;;;
;;; TESTING PROCEDURES
;;;

;; test runs one instance and computes the output
to gen_inputs
  set rand-iris one-of irises
  set input-1 item 0 rand-iris
  set input-2 item 1 rand-iris
  set input-3 item 2 rand-iris
  set input-4 item 3 rand-iris
  
  ask input-node-1 [
      set activation normalize (item 0 rand-iris) 4.3 7.9
      set label activation
    ]
    ask input-node-2 [ 
      set activation normalize (item 1 rand-iris) 2 4.4
      set label activation
    ]
    ask input-node-3 [ 
      set activation normalize (item 2 rand-iris) 1 6.9
      set label activation
    ]
    ask input-node-4 [ 
      set activation normalize (item 3 rand-iris) 0.1 2.9
      set label activation
    ]
  
end

to test-all
  let num-correct 0
  
  foreach irises[
    type ?
    
    set input-1 item 0 ?
    set input-2 item 1 ?
    set input-3 item 2 ?
    set input-4 item 3 ?   
    let answer item 4 ?
    
    
    ask input-node-1 [
      set activation normalize (item 0 ?) 4.3 7.9
      set label activation
    ]
    ask input-node-2 [ 
      set activation normalize (item 1 ?) 2 4.4
      set label activation
    ]
    ask input-node-3 [ 
      set activation normalize (item 2 ?) 1 6.9
      set label activation
    ]
    ask input-node-4 [ 
      set activation normalize (item 3 ?) 0.1 2.9
      set label activation
    ]
    propagate
 
    let output-list [ ]
    set output-list lput (step [activation] of output-node-1) output-list
    set output-list lput (step [activation] of output-node-2) output-list 
    set output-list lput (step [activation] of output-node-3) output-list
    
    let percent calulate-percent output-list (integer-to-answer-list answer)
    if-else (percent = 100) [
        print " correct"
        set num-correct 1 + num-correct  
    ][
        print " incorrect"
    ] 
  ]
  type "Number correct: " type num-correct type " out of " print (length irises)
end

to test
  
  propagate
  
  let answer item 4 rand-iris
  let output-list [ ]
  set output-list lput (step [activation] of output-node-1) output-list
  set output-list lput (step [activation] of output-node-2) output-list 
  set output-list lput (step [activation] of output-node-3) output-list
  let percent calulate-percent output-list (integer-to-answer-list answer)
  let correct? ifelse-value (percent = 100) ["CORRECT"] ["INCORRECT"]
  
  user-message (word
    "The expected answer for iris with\nsepal length " input-1 ", sepal width " input-2 
    "\npetal length " input-3 ", petal width " input-4 "\nis " 
    integer-to-iris-string (answer) " (" answer ").\n\n"
    "Output:\n"
    output-list 
    "\nExpected:\n"
    integer-to-answer-list answer
    "\n\n" correct? ", percent correct: " percent "%")
end

to-report result-for-inputs [n1 n2 n3 n4]
  ask input-node-1 [ set activation normalize n1 4.3 7.9 ]
  ask input-node-2 [ set activation normalize n2 2 4.4 ]
  ask input-node-3 [ set activation normalize n3 1 6.9 ]
  ask input-node-4 [ set activation normalize n4 0.1 2.9 ]
  propagate
  report step [activation] of one-of output-nodes
end

to-report integer-to-iris-string [index] ; index is 0-2
  if index = 0 [
    report "Iris-setosa"
  ]
  if index = 1 [
    report "Iris-versicolor"
  ]
  if index = 2 [
    report "Iris-virginica"
  ]
end

to-report calulate-percent [output-list expected-list]
    let number-correct 0
    if item 0 output-list = item 0 expected-list[
      set number-correct 1 + number-correct
    ]
    if item 1 output-list = item 1 expected-list[
      set number-correct 1 + number-correct
    ]
    if item 2 output-list = item 2 expected-list[
      set number-correct 1 + number-correct
    ]
    report round ((number-correct / 3) * 100)
end

to-report integer-to-answer-list [index]
if index = 0 [
    report [1 0 0]
  ]
  if index = 1 [
    report [0 1 0]
  ]
  if index = 2 [
    report [0 0 1]
  ]
end


to-report normalize [attr minimum maximum]
  
  report (attr - minimum) / ( maximum - minimum)
end

; Copyright 2006 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
245
10
708
350
-1
-1
23.84211
1
10
1
1
1
0
0
0
1
-10
8
-5
7
1
1
1
ticks
30.0

BUTTON
135
10
220
43
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
135
50
220
85
train
train
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
732
304
807
338
test
test
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
500
355
557
400
output1
[precision activation 2] of output-node-1
3
1
11

SLIDER
14
128
220
161
learning-rate
learning-rate
0.0
1.0
0.5
1.0E-4
1
NIL
HORIZONTAL

PLOT
13
209
220
364
Error vs. Epochs
Epochs
Error
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot epoch-error"

SLIDER
14
168
220
201
examples-per-epoch
examples-per-epoch
1.0
1000.0
533
1.0
1
NIL
HORIZONTAL

TEXTBOX
10
20
127
38
1. Setup neural net:
11
0.0
0

TEXTBOX
10
60
119
88
2. Train neural net:
11
0.0
0

TEXTBOX
732
14
882
32
3. Test neural net:
11
0.0
0

SWITCH
245
360
380
393
show-weights?
show-weights?
0
1
-1000

BUTTON
135
90
220
123
train once
train
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
732
154
807
214
input-3
5.1
1
0
Number

INPUTBOX
732
214
807
274
input-4
1.8
1
0
Number

INPUTBOX
732
34
807
94
input-1
5.9
1
0
Number

INPUTBOX
732
94
807
154
input-2
3
1
0
Number

BUTTON
732
274
807
307
NIL
gen_inputs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
385
355
495
400
target-answer
integer-to-iris-string target-answer
17
1
11

MONITOR
560
355
622
400
output-2
[precision activation 2] of output-node-2
17
1
11

MONITOR
625
355
687
400
output-3
[precision activation 2] of output-node-3
17
1
11

BUTTON
735
365
807
398
NIL
test-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
This needs the text file named 'iris.txt'

'gen-input' button will generate one random input and the 'test' button will display the results of that input

'test-all' button will test all samples in the input set and display the results in the command center

100 = Iris-setosa
010 = Iris-versicolor
001 = Iris-virginica
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

bias-node
false
0
Circle -16777216 true false 0 0 300
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 120 60 150 60 165 60 165 225 180 225 180 240 135 240 135 225 150 225 150 75 135 75 150 60

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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0

output-node
false
1
Circle -7500403 true false 0 0 300
Circle -2674135 true true 30 30 240
Polygon -7500403 true false 195 75 90 75 150 150 90 225 195 225 195 210 195 195 180 210 120 210 165 150 120 90 180 90 195 105 195 75

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
setup repeat 100 [ train ]
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

small-arrow-shape
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 135 180
Line -7500403 true 150 150 165 180

@#$#@#$#@
1
@#$#@#$#@
