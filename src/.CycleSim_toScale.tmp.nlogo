;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Define Environment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals[ xmin xmax ymin ymax countdown leadP]
breed [ cyclists cyclist ]

cyclists-own[
  rider-mass                    ; Cyclist weight
  bike-mass                     ; Bike weight
  energy                        ; Energy left in the race
  maxSpeed                      ; Maximum speed that cyclist can travel
  speed                         ; Current speed that agent is travelling
  maxPower                      ; Maximum power a cyclist can produce for 10 minutes
  cooperation                   ; Cooperation probability of the group, assigns each cyclist in a pack a probability of cooperation
  isBreakawayCoop?              ; Decide if the cyclist will defect with leader
  isCoop?                       ; Allocate true or false if the cyclist is cooperative or not, respectively
  isLead?                       ; Allocate whether cyclist is in the front of the pack or not
  mates                         ; Allocates teammates generally to cyclist not for actual team
  group                         ; Allocates the full team including cyclist-here

  nearest-neighbor              ; Looks for the cyclist's nearest neighbours
  leader                        ; Identify leader of pack and assign to each agent
  breakLead                     ; BreakLeader, identifies cyclist that will lead break

  isBreak?                      ; The probability of breaking away

  crash-prob                    ; The probability that the cyclist will crash
  aggression                    ; A cyclists level of aggression
  turtle-meaning                ; Set meaning

  hasLead?                      ;

  leadTime                      ; Variable used to determine whether to lead or not to lead
  cooldown                      ; Variable used to determine if cyclist is cooling down
  breakTime

  dist                          ; Calculate the distance travelled for each turtle (Do it in groups)
  CF_draft
  powerP

  cohesion-group
  separation-group
  next-neighbor

  totalEnergy
  exhausted
  extremeExhausted
  recovery

  attackStatus?
  blockStatus?
  bridgeStatus?
  teamAttackStatus?

  teamLead?

  fin?

  slowdown?
  ]

patches-own[
  meaning
]

to setup
  clear-all
  set ymin -15
  set ymax 15
  draw-roads
  draw-neighbourhood
  place-cyclists

  set leadP 0
  ask cyclists[
    coop
    breakawayCoop]

  reset-ticks
end


to go
  if not any? turtles [stop]


  move                      ; Move agents for 5 minutes (one tick is one minute)

  pack                      ; Perfom flocking mechanism

  lead                      ; Find leader in group and move prvious lead to the back

  ask cyclists [
    if ticks mod 5 = 0 and isBreak? = false [
      coop                  ; Find probability that turtles are cooperative
      breakawayCoop         ; Find probability that turtles will breakAway with Leader
    ]
  ]

  updateSpeed               ; Update speed of the group

  attackA

  attackT

  block

  catch-group

  fatigued

  sprint

  tick
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Managerial Work ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to attackAlone
  ask cyclists with [ turtle-meaning = "teamLead"] [
    if countdown = 0 [
      set countdown 15
      set attackStatus? true
      print "Your lead cyclist is attacking alone, watch their energy levels!"
    ]
  ]
end

to attackA
  ask cyclists with [ attackStatus? = true ]
  [
    ifelse countdown > 0 [
      set speed 0.9 * maxSpeed
      decrement-countdown
    ][
      set attackStatus? false
      print "Your lead cyclist is no longer attacking!"
    ]
  ]
end

to teamBlock
  ask cyclists with [turtle-meaning = "team"][
    if countdown = 0 [
      set countdown 15
      set blockStatus? true
    ]
  ]
end

to block
  ask cyclists with [blockStatus? = true][
    ifelse countdown > 0 [
      ifelse not any? other turtles in-cone 10 165  [
        ask mates with [ blockStatus? = false ] [set isLead? false]
        set isLead? true
        set leadTime 5
        set speed maxSpeed * 0.3
        ask mates with [ blockStatus? = false and meaning != "teamLead"] [set speed speed]
        ask mates with [ meaning = "teamLead" ][set speed 0.75 * maxSpeed]
        print ( word "A teammate is blocking!" )
      ][
        print "A teammate is not in a favourable position to block!"
        set speed maxSpeed * 0.9
      ]
      set countdown countdown - 1 / 6 ;decrement-countdown
    ][
      set blockStatus? false
      print "A teammate is no longer blocking!"
      set countdown 0
    ]
  ]
end


to teamAttack
  ask cyclists with [ turtle-meaning = "team" or turtle-meaning = "teamLead"][
    if countdown = 0 [
      set teamAttackStatus? true
    ]
  ]

  if countdown = 0 [ set countdown 15]
end

to attackT
  ask cyclists with [ teamAttackStatus? = true][
    ifelse countdown > 0 [
      ifelse any? mates with [ teamAttackStatus? = false] or any? other cyclists in-cone 20 180 with [ teamAttackStatus? = false ][
        ; First need to leave the pack
        set speed 0.9 * maxSpeed
        print "A teammate has attacked the peloton"
      ][
        ; Now regrup and create formation
       if any? cohesion-group and not any? separation-group [
          set bridgeStatus? true
       ]
      ]
      set countdown countdown - ( 1 / 20 )
    ][
      set teamAttackStatus? false
      set bridgeStatus? false
      print "Your team has finished their attack"
    ]
  ]

  if countdown < 0 [ set countdown 0]
end

to bridge
  ask cyclists with [ turtle-meaning = "team" or turtle-meaning = "teamLead"][
    if countdown = 0 [
      if any? cohesion-group and not any? separation-group [
        set countdown -1 ; -1 is just infinite, but this will continue until group is found
        set bridgeStatus? true
      ]
    ]
  ]

end

; resets the timer
to catch-group
  ask cyclists with [ bridgeStatus? = true and teamAttackStatus? = false ][
    ifelse any? separation-group [
      set speed [speed] of min-one-of separation-group [distance myself] + 1
      set bridgestatus? false
      set countdown 0
      print ( word "A teammate has bridged the gap!" )
    ][
      breakaway
      print ( word "A teammate is bridging!" )
      if any? mates [
        ask mates [ join-breakaway ]
      ]
    ]
  ]
end

; This one does not reset the timer
to catch-group2
  ask cyclists with [ bridgeStatus? = true and teamAttackStatus? = true][
    ifelse any? separation-group [
      set speed [speed] of min-one-of separation-group [distance myself] + 1
      set bridgestatus? false
      print "A teammate has bridged the gap! And joined the attack group"
    ][
      breakaway
      print "A teammate is trying to bridge and join the attack group!"
      if any? mates [
        ask mates [ join-breakaway ]
      ]
    ]
  ]
end


to setup-countdown
  set countdown 0
end

to decrement-countdown
  set countdown countdown - 1
end

to fatigued
  ask cyclists with [exhausted = true][
    set speed maxSpeed * 0.7
  ]

  ask cyclists with [ extremeExhausted = true ][
    set speed maxSpeed * 0.5
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Handle Agents ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move
    ask cyclists [
    fd speed * 0.06
    energy-calc
  ]

  finish-cyclists

  ask cyclists [set dist dist + speed * 0.06]
end

to finish-cyclists
  ask patches with [ meaning = "finish"][
    ask cyclists-here [
      if any? cyclists with [ turtle-meaning = "teamLead"][ set leadP leadP + 1]
      stamp die]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Identify lead ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to lead

  decrement-lead-time

  decrement-cooldown-time

  defect

  find-leader

  ask cyclists with [ turtle-meaning != "teamLead" and isLead? = true][
    set color yellow
  ]

   ask cyclists with [ isLead? = false and isBreak? = false ][
    if turtle-meaning = "notTeam" [ set color magenta ]
    if turtle-meaning = "team" [ set color cyan ]
    if turtle-meaning = "teamLead" [ set color blue ]
  ]

end

to decrement-lead-time
  ask cyclists with [isLead? = true][
    ifelse leadTime = 0 [
      set leadTime 5
      set isLead? false
      set hasLead? true
    ][
      set leadTime leadTime - 1
    ]
  ]
end

to decrement-cooldown-time
  ask cyclists with [ hasLead? = true][
    ifelse cooldown = 0 [
      set cooldown 5
      set hasLead? false
    ][
      set cooldown cooldown - 1
    ]
  ]
end

to defect
  ask cyclists with [ isCoop? = false and isLead? = true ][
    ; ask uncooperative cyclists to set leadTime to 0
    set leadTime 0
    set color blue + 13
  ]
end

to find-leader
  ; check if they have already lead, find the next leader
  ; if they have not already lead and no one nearby is a leader, they are leader
  ask cyclists with [ any? mates and not any? other turtles in-cone 0.01 165 ] [
    ifelse hasLead? = true [
      next-leader
    ][
      if not any? group with [isLead? = true][
        set isLead? true
      ]
    ]
  ]
end

to next-leader
  if not any? mates with [ isLead? = true ][
    find-nearest-neighbor
    ask nearest-neighbor [ set isLead? true ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; UpdateSpeed ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to updateSpeed

  set-group-speed

  find-breakaway-chance
  ; Catch-up (If energy allows)

end

to set-group-speed
  ask cyclists [
    if any? group with [ isLead? = true ][
      set leader min-one-of group with [ isLead? = true ] [distance myself]
      ask leader [ set speed 0.8 * ( mean [ maxSpeed ] of group) ]
      set speed [ speed ] of leader

      if hasLead? = true [
        set color orange
        set speed 0.6 * ([ speed ] of leader)
      ]
    ]
  ]

  ask cyclists with [not any? mates] [
    set speed 0.75 * maxSpeed
  ]
end

to find-breakaway-chance
  ask cyclists with [ isLead? = true and isCoop? = false and maxSpeed * 0.8 > speed ] [
    set isBreak? true
    set isLead? false
    breakaway
  ]

  ask cyclists with [ isBreak? = true][
    ifelse breakTime = 0 [
      set isBreak? false
      set hasLead? true
      set breakTime 3
    ][
      set breakTime breakTime - 1
    ]
  ]


  ask cyclists with [isBreakawayCoop? = true and any? mates with [isBreak? = true]][
    join-Breakaway
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Final Sprint ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to sprint
  ; engage in final sprint
  ask cyclists with [ (max-pxcor - 2 - xcor) <= 6][
    ifelse energy / totalEnergy > 0.3 [
      set speed maxSpeed
    ][
      if energy / totalEnergy > 0 [
        set speed maxSpeed * 0.7
      ]
    ]
    if energy / totalEnergy = 0 [
      set speed 0.5 * maxSpeed
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Breakaway ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to breakaway
    set speed 0.9 * maxSpeed
    set color green
end

to join-Breakaway
  set breakLead min-one-of mates with [ isBreak? = true or bridgeStatus? = true ] [ distance myself]
  set speed [speed] of breakLead
  set color 37
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Cooperation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

       ; if cooperation is less than 0.3 then the agent may or may not cooperate
       ; if cooperation is above 0.3 then the agent will cooperate
to coop
  ifelse random-float 1 < cooperation [
      set isCoop? false
  ][
      set isCoop? true
  ]
end

to breakawayCoop
  ifelse random-float 1 < 0.4 [
      set isBreakawayCoop? true
   ][
      set isBreakawayCoop? false
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Power Equations ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report calcMaxSpeed
  ; Newton-Raphson method to calculate cubic roots
  let hold 0
  let threshold 1000
  let v 12

  while [ threshold > 0.00000000001 ] [
    set hold v
    set v (v - ( ( 0.0053 * 9.8 * ( rider-mass + bike-mass ) * v ) + (0.185 * v ^ 3) - maxPower * rider-mass ) /  ( ( 0.0053 * 9.8 * ( rider-mass + bike-mass ) ) + 3 * (0.185 * v ^ 2) ))
    set threshold abs(v -  hold)
  ]

  report v
end

; d_w should be the distance between cyclist and cyclist in front, using in-cone will help
to-report powerEqns [ d_w v ]
  ; There is no drafting benefit available if a cyclist is more than 3 metres away from preceding rider, so set CF_draft to 1 if this is the case
  ;CF_draft =  0.62 − 0.0104 d_w + 0.0452 d_w^2
  set CF_draft 1
  if d_w <= 3 [
    set CF_draft ( 0.62 - 0.0104 * d_w + 0.0452 * d_w ^ 2)
  ]

  ;P_air is the power needed by the cyclist to overcome air-resistance, corrected for drafting
  ;P_air    = k . CF_draft . velocity^3
  let P_air (0.185 * CF_draft * v ^ 3)

  ; P_roll is the power required to overcome rolling resistance
  ;P_roll   = C_r . g . ( M + M_b) . v
  let P_roll ( 0.0053 * 9.8 * ( rider-mass + bike-mass ) * v )

  ; To incorporate elevation will need to use P_grade ( so not looking at elevation until the very end ) - T. Olds

  ;P_tot    = P_roll + P_air
  let P_tot (P_roll + P_air)

  set powerP P_tot / 450

  report ( P_tot )
end

to-report energyEqns
  let d 100
  let vel 0
  let close other turtles in-cone 3 160
  let closest min-one-of close [distance myself]
  ifelse any? other cyclists in-cone 3 160 [
    set d distance closest
  ][
    set d 100
  ]
  set vel speed * 0.06

 report (energy - ( e ^ ( -6.35 * ln ( (powerEqns d vel) / maxPower ) + 2.478 ) ) * 60)
end

to energy-calc
  let d 10
  let close other turtles in-cone 160 3
  let closest min-one-of close [distance myself]
  ifelse any? other cyclists in-cone 160 3 [
    set d distance closest
  ][
    set d 100
  ]

  ; set to metres from kilometres
  set d d * 1000
  ; keep velocity at m/s
  let vel speed

  ; has to be in seconds not minutes
  let energy-used 0
  set energy-used ( powerEqns d vel ) * 60

  ;show energy-used

  ; energy expenditure
  set energy energy - energy-used / 1000
  set energy energy + recovery * 60 / 1000

  ;show energy

  if energy > 1000[set energy 1000] ;caps storage of energy at 1000kJ

  ifelse energy < 100 [   ;defines a cyclist as exhausted
    set exhausted true
  ][
    set exhausted false
  ]

  ifelse energy <= 0  ;cyclist completely spent - he moves to the leftmost coordinate and becomes much slower
    [
      set extremeExhausted true
      ;set energy 0
    ][
      set extremeExhausted false
  ]


end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Position ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to find-position
  ask cyclists with [fin? = true ][
    let pos 0
    if not any? cyclists with [ turtle-meaning = "teamLead"][
      set fin? false
      set pos count turtles
    ]

    set pos 175 - pos
    show pos
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Flocking ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to pack
  ask cyclists[
  find-mates
  find-group
  find-alg-group
  ifelse any? cohesion-group [
      find-nearest-neighbor
      ifelse distance next-neighbor < 0.0001
        [ separate ]
        [ align
          cohere ] ] [ set heading 90]
  ]
end

to find-alg-group
  set cohesion-group other turtles in-cone 0.01 140
  set separation-group other turtles in-cone 0.001 140
end

to find-group
  set group turtles in-radius ( vision * 0.02 )
end
to find-mates
  set mates other turtles in-radius ( vision * 0.02 ) ; set radius to find teammates
end

to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of mates[ distance myself ] ; finds the neighbour with the minimum distance from cyclist\
  set next-neighbor min-one-of cohesion-group [distance myself]
end

to separate
  turn-away ([heading] of next-neighbor) sep  ; set angle that cyclicst can turn away from
  ; ifelse random-float 1 < 0.9 [ turn-sep] [slow-down]       ; If I want my agents to either slow down or turn away
end


to turn-sep
  turn-away ([heading] of nearest-neighbor) sep
end

to slow-down
  set speed 0.97 * speed
end

;;;;;;;;;;;;;;;;;;;;; ALIGN

to align  ;; turtle procedure
  set heading 90
  ;turn-towards average-matesheading 1  ; set angle that cyclist turns toward teamate
  ; This just makes sure that if a turtle drifts too far away, that it will come back into the race
  ;let closest-distance distance nearest-neighbor
  ;if closest-distance > 3 [
  ;  turn-at-most (subtract-headings [heading] of nearest-neighbor heading) 5]
end

to-report average-matesheading  ;; turtle procedure
  ; average heading
  let x-component sum [dx] of mates  let y-component sum [dy] of mates  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end


to cohere  ;; turtle procedure
  turn-towards average-heading-towards-mates coh
end

to-report average-heading-towards-mates
  let x-component mean [sin (towards myself + 180)] of cohesion-group
  let y-component mean [cos (towards myself + 180)] of cohesion-group
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

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup Environment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to draw-roads
  ask patches with [ pycor > ymin and pycor < ymax] [
      set pcolor grey
    ]

  ask patches with [ pxcor <= 40 and pxcor > 15 and pycor > ymin and pycor < ymax][
    sprout 1 [
      set shape "cobbles"
      set color brown
      stamp die
    ]
    set meaning "cobbles" ; can use this in if statements to set conditions of cobbles
  ]

  ask patches with [pycor > ymin + 1 and pycor < ymin + 2 and pxcor <= 145 or pycor > ymax - 2 and pycor < ymax - 1 and pxcor <= 145][
     sprout 1 [
      set shape "sideline"
      stamp die
    ]
  ]

  ask patches with [ pxcor <= max-pxcor and pxcor > max-pxcor - 2 and pycor > ymin and pycor < ymax] [
    sprout 1 [
      set shape "finish"
      stamp die
    ]
    set meaning "finish" ; can use this in if statements to set conditions of cobbles
  ]


  ; cyclists are within a 10 x 10 meter box at the start line, however, since scale is 0.001 they all start in same patch
  ; If they started in differennt patches then they'd be around a kilometre apart
  ask patches with [ pycor > -0.005 and pycor < 0.005 and pxcor >= min-pxcor and pxcor <= min-pxcor + 0.01 ][
    sprout 1 [
      set shape "line"
      set color white
      set size 5
      stamp die]
    set meaning "start"
  ]
end

to draw-neighbourhood
  ; Draw grass
  ask patches with [pycor <= ymin or pycor >= ymax] [
      let g random 16 + 96
      let c (list 0 g 0)
      set pcolor c
      set meaning "grass"
  ]


  ; Draw homes
  ask n-of 20 patches with [ meaning = "grass"][
     if count neighbors with [meaning = "grass"] = 8 and not any? turtles in-radius 2[
      sprout 1 [
        set shape one-of ["house" "house colonial" "house two story"]
        set size 6
        stamp die
      ]
    ]
    set meaning "house"
  ]

  ; Draw trees
  ask patches with [meaning = "grass"][
    if count neighbors with [meaning = "grass"] = 8 and not any? patches with [meaning = "houses"] in-radius 4 or not any? turtles in-radius 1 [
      if random 100 > 95 [
        sprout 1 [
          set shape one-of [ "tree" "tree pine" ]
          set size 4
          set color green
          stamp die
        ]
      ]
    ]
    set meaning "tree"
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Place Agents ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to place-cyclists
  create-cyclists 168 [
    set size 1
    set shape "circle"
    set heading 90
    set color magenta
    set rider-mass 65
    set bike-mass 7
    set maxPower random-normal 7.1 0.4
    set cooperation random-normal 0.3 0.3;0.48 0.2
    set energy random-normal 750 30
    set totalEnergy energy
    set turtle-meaning "notTeam"
    set isLead? false

    set isBreak? false
    set hasLead? false

    set speed random-normal 10 0.5

    set maxSpeed calcMaxSpeed

    set  exhausted false
    set  extremeExhausted false
    set recovery random-normal 180 20

    set fin? true
    set CF_draft 1
    move-to one-of patches with [meaning = "start"]
  ]

  create-cyclists 6 [
    set size 1
    set shape "circle"
    set heading 90
    set color cyan

    set rider-mass 65
    set bike-mass 7
    if teamAbility = "Good" [ set maxPower random-normal 8 0.4 set energy random-normal 800 30 ]
    if teamAbility = "Average" [ set maxPower random-normal 7.1 0.4 set energy random-normal 750 30]
    if teamAbility = "Bad" [ set maxPower random-normal 6 0.4 set energy random-normal 700 30]
    set cooperation random-normal 0.3 0.3;0.48 0.2
    set totalEnergy energy

    set isBreak? false

    set turtle-meaning "team"
    set isLead? false

    set hasLead? false

    set speed random-normal 10 0.5

    set maxSpeed calcMaxSpeed

    set  exhausted false
    set  extremeExhausted false
    set recovery random-normal 180 20
    set fin? true
        set CF_draft 1

    move-to one-of patches with [meaning = "start"]
  ]

  create-cyclists 1 [
    set size 1
    set shape "circle"
    set heading 90
    set color blue
    set rider-mass leadWeight
    set bike-mass 7
    set maxPower leadPower
    set cooperation leadCooperation
    set energy leadEnergy
    set totalEnergy leadEnergy
    set turtle-meaning "teamLead"
    set isLead? false

    set hasLead? false

    set isBreak? false

    set speed random-normal 10 0.5

    set maxSpeed calcMaxSpeed

    set  exhausted false
    set  extremeExhausted false
    set recovery random-normal 180 20

    set fin? true

    set CF_draft 1

    move-to one-of patches with [meaning = "start"]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
0
10
1263
224
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-125
125
-20
20
1
1
1
ticks
30.0

BUTTON
3
238
66
271
go
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

BUTTON
4
278
67
311
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

SLIDER
860
243
1032
276
Vision
Vision
0
5
5.0
0.01
1
m
HORIZONTAL

SLIDER
861
294
1033
327
sep
sep
0
5
1.561
0.001
1
degrees
HORIZONTAL

SLIDER
863
340
1035
373
coh
coh
0
3
0.991
0.001
1
degrees
HORIZONTAL

CHOOSER
85
266
223
311
teamAbility
teamAbility
"Good" "Average" "Bad"
1

SLIDER
6
380
178
413
leadWeight
leadWeight
60
100
62.8
0.1
1
kg
HORIZONTAL

SLIDER
6
334
178
367
leadPower
leadPower
6
8.5
8.5
0.1
1
W/kg
HORIZONTAL

SLIDER
189
334
362
367
leadCooperation
leadCooperation
0
1
0.45
0.01
1
NIL
HORIZONTAL

SLIDER
188
381
360
414
leadEnergy
leadEnergy
650
800
650.0
1
1
kiloJoules
HORIZONTAL

BUTTON
405
250
509
283
Attack Alone
attackAlone
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

BUTTON
534
304
631
337
Team Block
teamBlock
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
534
354
601
387
Bridge
bridge
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
534
252
638
285
Team Attack
teamAttack
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

MONITOR
376
293
512
338
Countdown (Minutes)
countdown
1
1
11

PLOT
0
424
506
654
Energy of Turtles over time
Time (Minutes)
Energy (kiloJoules)
0.0
0.0
0.0
1100.0
true
true
"" ""
PENS
"Adviseries" 1.0 0 -7858858 true "" "plot mean [ energy ] of cyclists with [turtle-meaning = \"notTeam\"]"
"Team Lead" 1.0 0 -14070903 true "" "plot mean [ energy ] of cyclists with [turtle-meaning = \"teamLead\"]"
"Team" 1.0 0 -7500403 true "" "plot mean [ energy ] of cyclists with [turtle-meaning = \"team\"]"

MONITOR
1253
433
1311
478
Position
leadP
0
1
11

PLOT
515
427
904
653
Drafting
Time
Drafting Coefficient
0.0
10.0
0.0
0.0
true
true
"" ""
PENS
"Adviseries" 1.0 0 -7858858 true "" "plot mean [ CF_draft ] of cyclists with [turtle-meaning = \"notTeam\"]"
"Team Lead" 1.0 0 -14070903 true "" "plot mean [ CF_draft ] of cyclists with [turtle-meaning = \"teamLead\"]"
"Team" 1.0 0 -9276814 true "" "plot mean [ CF_draft ] of cyclists with [turtle-meaning = \"team\"]"

PLOT
911
428
1236
654
PowerProportions
Time
Proportion of Power
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"Adviseries" 1.0 0 -7858858 true "" "plot mean [ powerP ] of cyclists with [turtle-meaning = \"notTeam\"]"
"Team Lead" 1.0 0 -14070903 true "" "plot mean [ powerP ] of cyclists with [turtle-meaning = \"teamLead\"]\n"
"Team" 1.0 0 -11053225 true "" "plot mean [ powerP ] of cyclists with [turtle-meaning = \"team\"]"

@#$#@#$#@
# Cycle Simulation

## WHAT IS IT?

Road cycling is a popular sport where a group of riders start together, often as a rolling start - a race that begins while cyclists are already in motion, in contrast to a standing start where they commence from a standstill. The cyclists race one another to the finish line to win the race. Cyclists participate in many prestigious events known as classics throughout the year, with some of the most renowned being: The Grand Tours (i.e. Tour de France, Giro d'Italia, Vuelta a Espana), The Monument Classics (i.e. Milan-Sanremo, Tour of Flanders, Paris-Roubaix, Liege-Bastogne-Liege, Giro di Lombardia) and The World Championships. Tours span multiple days, the focus here is on the Monument Classics, which are intense one-day races, typically spanning 200km to 300km.
 
Cycling is a sport that encompasses both individual and team dynamics. On an individual level, there can only be one winner. However, it also operates as a team sport, where intricate strategies revolve around the lead rider, typically the strongest cyclist in the team, and the domestiques who provide vital support. These efforts are strategically combined to propel the lead rider towards a winning position.

It is a sport that manages to illustrate complex systems as a result of dynamic behaviours and energy considerations. As cyclists accelerate they are faced with air resistance, which results in a substantial increase in energy expenditure. To mitigate this energy loss, cyclists often form strategic alliances with riders from rival teams. In these alliances, each cyclist takes turns leading the group while others tuck into the slipstream, a technique known as drafting. It's worth noting that cyclists in a drafting position expend 30-40% less energy compared to when they are in the leading position. This act of cooperation often creates a peloton, a large group of riders. However, not all cyclists are cooperative, some may not take their turn leading whilst others may proceed to leave the pack altogether in a breakaway, in an attempt to either conserve energy for the end of the race or gain a strategic position.

Cyclists in this way often depict flocking behaviour much like birds or a school of fish. 

This simulation emphasizes the managerial role in the context of road cycling. During the race, in a vehicle, managers are allowed to approach their cyclists and facilitate real-time information and strategic guidance. To make this more engaging, this simulation has been turned into a game. The user assumes the role of the team manager, able to dispense crucial instructions and devise race-winning strategies while monitoring the energy levels of their team members. 

If the user runs the simulation without playing the game, then their team will act as regular agents.

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

### Envrionment
- Time Stepn
- Lattice
- Boundary Conditions


### Patches

### Agents
- Type
- Vision
- Properties
- Behaviour
- Parameters

### Reults
- Measures

, the lead rider of the user's team is the blue agent and the cyan agents are the domestiques of the team. 



## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

- Mention if there is stigmergy 
- Mention if there is emergence

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

Elevation and energy drain as a result of elevation

Whether the rider is a sprinter or climber. It is unknown whether some of these courses are great for climbers or sprinters so it would be cool to look into that. Maybe teams can look at allowing domestiques who are stronger at climbing to win those races to maintain rider happiness

Crashing probabilities

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

cobbles
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

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

finish
false
0
Rectangle -1 false false -15 0 315 300
Rectangle -16777216 true false 0 0 150 150
Rectangle -16777216 true false 150 150 300 300
Rectangle -1 true false 150 0 300 150
Rectangle -1 true false 0 150 150 300

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

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
false
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

sideline
false
0
Rectangle -1184463 true false 0 75 300 240

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

tree pine
false
0
Rectangle -6459832 true false 120 225 180 300
Polygon -7500403 true true 150 240 240 270 150 135 60 270
Polygon -7500403 true true 150 75 75 210 150 195 225 210
Polygon -7500403 true true 150 7 90 157 150 142 210 157 150 7

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
NetLogo 6.3.0
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
