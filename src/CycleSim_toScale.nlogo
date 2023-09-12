;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Define Environment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;extensions [table csv]
globals[ xmin xmax ymin ymax countdown leadP vision sep coh ]
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
  hasLead?                      ; Has the cyclist lead
  leadTime                      ; Variable used to determine whether to lead or not to lead
  cooldown                      ; Variable used to determine if cyclist is cooling down
  breakTime                     ; Time that cyclist has been in breakaway
  dist                          ; Calculate the distance travelled for each turtle (Do it in groups)
  CF_draft                      ; Drafting coefficient
  powerP                        ; Proportion of power cyclist uses
  cohesion-group                ; Number of cyclists in-cone 0.02 140
  separation-group              ; Number of cyclists in-cone 0.002 140
  next-neighbor                 ; Closest turtle ahead
  totalEnergy                   ; Total energy that cyclist has
  exhausted                     ; Is the cyclist exhauseted
  extremeExhausted              ; Is the cyclist extremely exhausted
  recovery                      ; Recovery rate of cyclist
  attackStatus?                 ; Is the cyclist attacking
  blockStatus?                  ; Is the cyclist blocking
  bridgeStatus?                 ; Is the cyclist bridging
  teamAttackStatus?             ; Is the team attacking
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
  set vision 5
  set sep 1.561
  set coh 0.991
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

  attackA                   ; Individual Attack

  attackT                   ; Team Attack

  block                     ; Team performs a block

  catch-group               ; Cyclist bridges the gap

  fatigued                  ; Is cyclist tired?

  sprint                    ; Final sprint

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
    ][
      set extremeExhausted false
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

;;;;;;;;;;;;;;;;;;;;; ALIGN

to align  ;; turtle procedure
  set heading 90
end

to-report average-matesheading  ;; turtle procedure
  ; average heading
  let x-component sum [dx] of mates
  let y-component sum [dy] of mates
  ifelse x-component = 0 and y-component = 0
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
    set exhausted false
    set extremeExhausted false
    set recovery random-normal 180 20
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
    set exhausted false
    set extremeExhausted false
    set recovery random-normal 180 20
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
    set exhausted false
    set extremeExhausted false
    set recovery random-normal 180 20
    set CF_draft 1
    move-to one-of patches with [meaning = "start"]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
0
10
1313
232
-1
-1
5.2
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

CHOOSER
85
266
223
311
teamAbility
teamAbility
"Good" "Average" "Bad"
0

SLIDER
6
380
178
413
leadWeight
leadWeight
60
100
63.0
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
1.0
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
800.0
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
"Adviseries" 1.0 0 -7858858 true "" "if any? cyclists with [turtle-meaning = \"notTeam\"] [plot mean [ energy ] of cyclists with [turtle-meaning = \"notTeam\"]]"
"Team Lead" 1.0 0 -14070903 true "" "if any? cyclists with [turtle-meaning = \"teamLead\"] [plot mean [ energy ] of cyclists with [turtle-meaning = \"teamLead\"]]"
"Team" 1.0 0 -7500403 true "" "if any? cyclists with [turtle-meaning = \"team\"] [plot mean [ energy ] of cyclists with [turtle-meaning = \"team\"]]"

MONITOR
1122
246
1215
307
Position
leadP
0
1
15

PLOT
515
427
904
653
Drafting
Time (Minutes)
Drafting Coefficient
0.0
10.0
0.0
0.0
true
true
"" ""
PENS
"Adviseries" 1.0 0 -7858858 true "" "if any? cyclists with [turtle-meaning = \"notTeam\"] [ plot mean [ CF_draft ] of cyclists with [turtle-meaning = \"notTeam\"]]"
"Team Lead" 1.0 0 -14070903 true "" "if any? cyclists with [turtle-meaning = \"teamLead\"] [ plot mean [ CF_draft ] of cyclists with [turtle-meaning = \"teamLead\"]]"
"Team" 1.0 0 -9276814 true "" "if any? cyclists with [turtle-meaning = \"team\"][ plot mean [ CF_draft ] of cyclists with [turtle-meaning = \"team\"]]"

PLOT
911
428
1236
654
PowerProportions
Time (Minutes)
Proportion of Power
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"Adviseries" 1.0 0 -7858858 true "" "if any? cyclists with [turtle-meaning = \"notTeam\"][plot mean [ powerP ] of cyclists with [turtle-meaning = \"notTeam\"]]"
"Team Lead" 1.0 0 -14070903 true "" "if any? cyclists with [turtle-meaning = \"teamLead\"][plot mean [ powerP ] of cyclists with [turtle-meaning = \"teamLead\"]]\n\n"
"Team" 1.0 0 -11053225 true "" "if any? cyclists with [turtle-meaning = \"team\"][plot mean [ powerP ] of cyclists with [turtle-meaning = \"team\"]]"

PLOT
692
248
1095
398
Exhausted Turtles
Time (Minutes)
Count
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"Exhaust" 1.0 0 -4079321 true "" "plot count turtles with [exhausted = true]"
"Ext. Exhaust" 1.0 0 -14439633 true "" "plot count turtles with [extremeExhausted = true]"

@#$#@#$#@
# Cycle Simulation

## WHAT IS IT?

Road cycling is a popular sport where a group of riders start together, often with a rolling start - a race that begins whilst the cyclists are already in motion, contrasting a standing start where they commence at a standstill. The cyclists race one another to the finish line to win the race. Throughout the year, cyclists participate in many prestigious events known as classics, with some of the most renowned being: The Grand Tours (i.e. Tour de France, Giro d'Italia, Vuelta a Espana), The Monument Classics (i.e. Milan-Sanremo, Tour of Flanders, Paris-Roubaix, Liege-Bastogne-Liege, Giro di Lombardia) and The World Championships. The focus of this simulation is on the Monument Classics, which are intense one-day races, typically spanning 200km to 300km.
 
Cycling races often encompass both individual and team dynamics. On an individual level, there can only be one winner. However, when operating as a team sport, there are intricate strategies that revolve around the lead rider, who is typically the strongest cyclist in the team, and the domestiques who provide vital support. These efforts are strategically combined to propel the lead rider towards a winning position.

It is a sport that manages to illustrate complex systems as a result of dynamic behaviours and energy considerations. As cyclists accelerate they are faced with air resistance, which results in a substantial increase in energy expenditure. To mitigate this energy loss, cyclists often form strategic alliances with riders from rival teams. In these alliances, each cyclist takes turns leading the group while others tuck into the slipstream, thereby using a technique known as drafting. It's worth noting that cyclists in a drafting position expend 30-40% less energy compared to when they are in the leading position. This cooperation often leads to the formation of a peloton, a large group of riders. By forming a peloton, cyclists often exhibit flocking behaviour similar to a flock of birds or a school of fish. However, not all cyclists are cooperative, some may not take their turn leading whilst others may proceed to leave the pack altogether in a breakaway - an attempt to either conserve energy for the end of the race or gain a strategic position.



This simulation emphasizes the managerial role in the context of road cycling. During the race managers are allowed to consult the cyclists in their team and facilitate real-time information and strategic guidance. To make this more engaging, this simulation has been turned into a game. In this game, the user assumes the role of the team manager, with the ability to dispense crucial instructions and devise race-winning strategies while monitoring the energy levels of their team members. 

If the user runs the simulation without playing the game, then their team will act as regular agents.

## HOW IT WORKS

### Envrionment

The environment is depicted as a square lattice, where agents are constrained to movement in directions: left, right, diagonal, and straight. The cyclists cannot move backwards and their heading should always be greater than 0 and less than 180, with 90 degree headings majority of the time during the race.

Within the environment, agents travel on the grey and brown areas, representing road and cobble respectively. These areas serve as the designated route where riders are treated to scenary as illustrated by the neighborhoods and trees on either side of the road.

The race track spans 250 km. This has been represented by dividing the x-axis into 250 patches, with each patch representing a kilometre. This length is consistent with races like the Giro di Lombardia and Liege-Bostogne-Liege, both of which are approximately 255 km long. 

The time steps are measured in minutes. Measuring the time steps in hours would result in too short a run time while measuring in seconds would make the model excessively large. Minutes are capable of providing sufficient granularity to capture the dynamics of the system. Consequently, rider speeds are represented by km/minute.

The topology is bounded, as the primary objective for the riders is to travel from the far left side of the map to the far right side.

### Agents
#### Type:
- Cyclists - In a professional Monuments Classics race there are 175 cyclists, or 25 teams each made up of 7 cyclists. In CycleSim there are 168 cyclists with set properties acting as your adversaries. In your team, there are 6 cyclists acting as your teammates whose abilities can be manipulated. 1 cyclist will be the lead cyclist whose abilities can be more finely tuned by the user.
#### Properties:
- Vision - The cyclist has a ore-determine field of vision. The cyclist can see about 10 metres in front of themself, this will help determine the flocking manoeuvre the the cyclist should take.
- Radius - Within a peloton, the cyclist is able to determine who is in their riding pack by selecting cyclists that are within a radius of 20 metres.
- Size, Shape, Heading - these aspects are all preset respectively to 1, a circle and 90 degrees.
- Colour - The lead rider of the user's team is assigned blue, the cyan agents are the domestiques of the team. The magenta cyclists are the adversaries. When a cyclist turns green it means they are performing a breakaway. If they turn grey it means they are joining a breakaway attempt. If a cyclist turns yellow it means they are a cyclist in a leading position, if they turn orange it means they have either just finished leading or are defecting.
- Bike mass - This represents the mass of the bicycle, set at 7kg by default.
- rider mass - This is the mass of the cyclist which is set to 63kg by default.
#### Behaviour
- Move - The cyclist moves forward in the specified direction by a speed in km/minute.
- Flocking - The cyclist obeys two behaviours: If they are too close to another cyclist in front of them, they will change their direction to avoid that cyclist. If a cyclist can see another cyclist but is a but not close to them, they will direct their heading to move towards them.
- Lead - If a cyclist is at the head of the pack they will be leading the pack as other cyclists fall in to their slipstream. If they've led for 5 minutes, they slow their pace in order to retreat as the leader of the pack and cool down for 5 minutes. The speed will then be set to the pack's average (0.8 * maxSpeed). 
- Attack - This is an aggressive jump away from other cyclists, or an attempt to leave the pack. The cyclist will increase their speed to 0.9 * maxSpeed.
- Bridge - If a cyclist is too far away from the pack they look to catch up.
- Block - A strategy employed to slow down the peloton. The leads teammates get to the front of the pack and slow down the pace. They will reduce the pace of the peloton to 0.3 * maxSpeed
- Breakaway - If a cyclist is able to, is at the front of the pack and is strategic to some extent, they will attempt to attack the pack. They will increase their speed to 0.9 * maxSpeed
- Follow Breakaway - If a cyclist is strategic enough they will try to get in the slipstream of a cyclist performing a breakaway.
	
#### Parameters
- Lead Power - This is a slider that the user can utilise to adjust the lead riders power. Adjusting this lead power will affect their max speed and their energy consumption. A cyclist with more power can travel faster while expending less energy.  
- Lead mass - This is a slider that can adjust the lead cyclist's body mass. This will also affect a riders max speed and energy expenditure. A cyclist with greater mass will have greater speed as they can generate more power, but will have less stamina.
- Lead Energy - This will determine how much energy the lead cyclist has at the beginning of the race. The greater the energy the longer it will take for a cyclist to reach a point of exhaustion.
- Lead Cooperation - This slider adjusts how cooperative the lead cyclist is. If they are cooperative (setting the slider to 1), then as the simulation runs they will conform to the standards of the peloton and lead when it's their turn. Otherwise, if they are strategic, they may decide to breakaway from the pack or to conserve energy by not taking their turn. In real life cyclists in the same pack may hold grudges or increase the speed if another is not cooperative, but in this simulation nothing of the sort will happen.
- Team ability - This chooser helps decide how good each member of the team is. If it's set to good they will be given above average power and energy levels. If set to bad they will be given below average values.

#### Meausres
There are a number of plots included in the interface: Energy vs Time, Drafting Coefficient vs Time, Proportion of Power vs Time, Count of Exhausted, Position of lead rider. 

- Energy vs Time - This will help the user make informed decisions. This would allow the user to keep track of the team and lead's energy throughout the race.

- Drafting Coefficient vs Time - This will illustrate if cyclists are indeed drafting. It is a good way to keep track of the efficiency of the cyclist. If their draft coefficient is 1 this means that they are not taking advantage of a slipstream; if it is below 1, then the cyclist is.

- Proportion of Power vs Time - This is a very sensitive measure that is closely linked to the gain and loss of energy. It is also related to the time until exhaustion measure mentioned by T. Olds and R. Hoenigman. If the value is high then the agent will tire quickly, however, if it is low they will not, they may in fact gain energy. 

- Count of Exhausted - This keeps the user informed as to when cyclists are starting to fatigue, it may be wise to attack before this occurs if our cyclist does not have a lot of power or energy. If the lead cyclist does have an abundance of power and energy this is probably the most opportune time to take advantage of race and attack.

- Position of lead rider - This is just to illustrate the final position of the lead rider of the team.



## HOW TO USE IT

1. The user is able to first select their team's ability. Here the user is able to choose whether, the team is comprised of good cyclists, average cyclists or bad cyclists. This will correspondingly alter how the teammates' energy and power are allocated. If they are good, they will have great energy and power, if bad they will have terrible energy and power and if they are average, they will have average attributes.
2. The user may also select more specific characteristics for the lead rider.
	- The leadPower slider allows the user to select how much power their lead cyclist has.
	- The leadCooperation slider allows the user to select how cooperative the lead cyclist is in a general setting. This will affect how they react when they are in a leading position in a peloton. A higher number means they are more willing to cooperate and conform to the ideal behaviour within a peloton.
	- The leadWeight slider allows the user to select the weight of our cyclists. It should be noted that every other cyclist a common weight of 63kg as this is the average weight of a professional cyclist. This has been kept constant for every other cyclist for the sake of comparison and for easy calculation of the power equations seen in the code file. It is interesting to see if the weight of a cyclist would indeed affect their ability in a race, and for that reason, only the lead cyclist has the ability to change their weight while every other turtle acts as a control. 
	- The leadEnergy slider is used to allocate the lead cyclists starting energy.
3. Click Setup to create the environment.
4. Click go to begin the simulation.
5. At this stage, the user may want to use the action buttons to influence the movement of their team. The user, therefore, plays the fundamental role of a manager in a cycling team. At the press of any one of the buttons, the count down will begin. The user may not issue any other commands until the countdown has hit 0, at which stage the movement of the team or individual or both has been completed.
	- Attack alone button - Lead cyclist will increase speed to 0.9 * maxSpeed for 15 minutes
	- Team attack button - Team will increase speed to 0.9 * maxSpeed for 15 minutes
	- Team block button - Team will get in front of peloton and slow speed of peloton to 0.3 * maxSpeed
	- Bridge button - If a cyclist is too far behind another cyclist, they will increase their speed until they catch up.
6. The plots will begin and you may now watch the race!

## THINGS TO NOTICE

It is easy to see that the track is straight, where in real life a race track is filled with turns throughout. The effects of turns on cyclists is minimal to their speed and positioning. So it is not neccessary to consider turns in the simulation of this race.

As the manager it is very important to understand what is happening to your team. At every step of the way, you know their energy in comparison to the amount of time they've been cycling. The user also gets to view the drafting coefficient, power proportions and number of exhausted cyclists. A drafting coefficient less than 1 means that a cyclist is trying to conserve energy and is currently in a slipstream of another, which should result in either an increase in energy or a plateau, this also has a relationship to the proportion of power that an agent is using. This proportion of max power that the agent is utilising will indicate how much stress they are under.

When running the model, you may sometimes visualise a great increase in energy before a sharp decline. This occurs as some cyclists have been drafting for majority of the race. As cyclists pass the finish line they are no longer considered in the calculation of the average energy, so those who have been drafting, or taking it easy at the back have a lot more energy and start to skew the results. The strong dip after the big incline in energy levels happens because these riders make a last ditch attempt to give the final 5km their all.

There are some stigmergy effects at play within this model. The cyclists that are in leading positions essentially leave a trail for other cyclists to follow. This trail is their slipstream that allows other cyclists behind them to draft. This continues to be the case for every next agent, which often in some parts of the race could result in V-shapes flocks or straight lines to maximise drafting.

Emergent effects are also present as the cyclists display flocking behaviour like a school of fish.

The original flocking algorithm has been altered to only consider the cyclists in front of them, not all around them. A cyclist is not concerned with the cyclist behind them as they are focused on going forward.

## THINGS TO TRY

### Strategies
There are some strategies that may result in a better chance of winning:

For a weak cyclist who is not cooperating, it might be better to attack the peloton at the beginning of the race. This allows them to get into a good position and to spend the rest of the race recovering in the front. When they come to the final sprint, they may have just enough energy to win.

For a strong cyclist who is cooperating, it may be much better to attack when all the cyclists begin to get extremely exhausted. This would be a great moment to get ahead as they would have the energy to continue even after attacking.

If at some point our lead cyclist finds themself tired early on in the race, it would be advised to send the team to block the peloton so that the lead can have time to recover and to catch up to the front, even by just a little bit. That moment of recovery might just give the cyclist enough energy to make a final attack at the end. 

If the team is weak but the cyclist is strong. I would suggest looking to block the peloton towards the beginning of the race. Following this I would suggest doing a team attack, and hopefully, by drafting, the team can carry each other through.

If the team is strong but the cyclist is weak. I would suggesting blocking as much as possible. Just so that the leader remains at the front and does not consume much energy, towards the end, make the attack!

These are my suggestions based off playing the game. It is a game, so experiment, and you might find your own winning strategy!

## EXTENDING THE MODEL

A change in energy owing to a change in elevation is something to consider. Climbing (the ability to scale elevation quickly) and sprinting are both very huge parts of cycling. The Tour de France, even goes so far as to award winners in each category. Many of the Monument Classics are divided up into races for climbers and races for sprinters, with some being in the middle of the two. It would be interesting to add switches to the models and allow each agent to choose whether they are a sprinter or a climber and to see how they perform on a race track with elevation at various spaces on the map.

Whether the rider is a sprinter or climber. It is unknown whether some of these courses are great for climbers or sprinters so it would be great to look into that. Maybe teams can look at allowing domestiques who are stronger at climbing to win those races to maintain rider happiness.

Crashing is a very like occurence in cycling races. in 2022, one crash took out almost half of the peloton at the Tour of Flanders. Cyclists that do not separate as they should in the flocking portion of the algorithm should be given a crash probability. However, there aren't very many statistics to support this probability. What we would be looking into here is crash avoidance. Should a cyclist slow down or should a cyclist turn away if they are getting too close to one another.

One thing to consider are mechanical dynamics and different terrain. As cyclists move, managers often follow with spare tires, bikes, chains, etc. Mechanical failures are very common, especially on varying terrains. In this model a cobbled road has been added, but given no special treatment. Often cobbled roads are a cyclist's nightmare as they incur mechanical failures more often and require a different level of power to overcome the rolling resistance. 


## RELATED MODELS
- Flocking
- V-Flocking

## CREDITS AND REFERENCES
- Wilensky, U. (1998). NetLogo Flocking model. http://ccl.northwestern.edu/netlogo/models/Flocking. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
- Olds, T. The mathematics of breaking away and chasing in cycling. Eur J Appl Physiol 77, 492–497 (1998). https://doi.org/10.1007/s004210050365
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
- Hoenigman, R., Bradley, E. and Lim, A. (2011), Cooperation in bike racing—When to work together and when to go it alone. Complexity, 17: 39-44. https://doi.org/10.1002/cplx.20372
- Martins Ratamero, E. (2015). Modelling Peloton Dynamics in Competitive Cycling: A Quantitative Approach. In: Cabri, J., Pezarat Correia, P., Barreiros, J. (eds) Sports Science Research and Technology Support. icSPORTS 2013. Communications in Computer and Information Science, vol 464. Springer, Cham. https://doi.org/10.1007/978-3-319-17548-5_4
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
<experiments>
  <experiment name="Results" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "notTeam"] [ mean [ energy ] of cyclists with [turtle-meaning = "notTeam"]][ 100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "teamLead"] [ mean [ energy ] of cyclists with [turtle-meaning = "teamLead"]] [100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "team"] [mean [ energy ] of cyclists with [turtle-meaning = "team"]][100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "notTeam"] [mean [ CF_draft ] of cyclists with [turtle-meaning = "notTeam"]][100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "teamLead"] [mean [ CF_draft ] of cyclists with [turtle-meaning = "teamLead"]][100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "team"] [mean [ CF_draft ] of cyclists with [turtle-meaning = "team"]][100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "notTeam"] [mean [ powerP ] of cyclists with [turtle-meaning = "notTeam"]][100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "teamLead"] [mean [ powerP ] of cyclists with [turtle-meaning = "teamLead"]][100000]</metric>
    <metric>ifelse-value any? cyclists with [turtle-meaning = "team"] [mean [ powerP ] of cyclists with [turtle-meaning = "team"]][100000]</metric>
    <metric>count turtles with [exhausted = true]</metric>
    <metric>count turtles with [extremeExhausted = true]</metric>
    <metric>leadP</metric>
    <enumeratedValueSet variable="leadPower">
      <value value="6.5"/>
      <value value="7.5"/>
      <value value="8.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leadEnergy">
      <value value="600"/>
      <value value="720"/>
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leadWeight">
      <value value="63"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teamAbility">
      <value value="&quot;Bad&quot;"/>
      <value value="&quot;Average&quot;"/>
      <value value="&quot;Good&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leadCooperation">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
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
