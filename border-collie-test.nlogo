globals [
  sum-fitness
  best-avg
  min-fitness
  best-min
  cur-gen
  gene-min
  gene-range
]
breed [ sheep a-sheep ]
breed [ dogs dog ]
sheep-own [ last-action ]
dogs-own [ last-action chromosome fitness ischild? ]

to setup
  clear-all
  let chromset [
    [8.506285382877977 10]
    [-2.3779980736012996 -1.9333874846348447]
    [3.74580751796838 -8.16958422564483]
    [-9.325895165476703 10]
    [-8.093460342264846 -7.691549417956075]
  ]
  ask patches [ set pcolor green ]
  set cur-gen 0
  ask dogs [move-to one-of patches]
  ask sheep [move-to one-of patches]
  ;set gene-min -10
  ;set gene-range 21

  create-sheep num-sheep  ; create the sheep, then initialize their variables
  [
    set shape  "sheep"
    set color white
    set size 1.5  ; easier to see
    set label-color blue - 2
    set last-action 0
    move-to one-of patches
  ]

  create-dogs num-dogs  ; create the dogs, then initialize their variables
  [
    set shape "wolf"
    set color black
    set last-action 0
    set fitness 9999
    set ischild? False
    set chromosome list (gene-min + random-float gene-range) (gene-min + random-float gene-range) ; 2 genes representing attraction/repulsion to other sheep/dogs
    set size 2  ; easier to see
    move-to one-of patches
  ]

  let d 0 ; Set dog chromosomes to pre-evolved ones
  ask dogs [
    set chromosome item d chromset
    set d d + 1
  ]

  set sum-fitness calc-score
  set min-fitness sum-fitness
  set best-avg 9999
  set best-min min-fitness
  clear-plot
  reset-ticks
end

;to reset ; For evolution purposes
;  let avg avg-fitness
;  if avg < best-avg [ set best-avg avg ] ; Only setting best average at the end of a gen
;  set cur-gen cur-gen + 1
;  if cur-gen = ngen [
;    print "Finished evolving! Testing final generation."
;  ];
;
;  ; Evolve the solution
;  ask dogs [set-ind-fitness];
;
;  ; Crossover
;  ask dogs [
;    let cx random-float 1
;    if cx > 1 - cxpb [
;      let parent tournament-select
;      let childc crossover chromosome ([chromosome] of parent)
;      hatch 1 [
;        set fitness 9999
;        set chromosome childc
;        set ischild? True
;      ]
;    ]
;  ];

  ; Mutation
;  ask dogs [
;    let mut random-float 1
;    if mut <= mutpb [
;      set chromosome mutate chromosome
;    ]
;  ]

  ; Acceptance of children into pop.
;  let children dogs with [ischild?]
;  let parents dogs with [not ischild?]
;  ask children [
;    let me self
;    let replacement min-one-of parents [genetic-difference me]
    ;let replacement min-one-of parents [fitness]
;    ask replacement [die]
;  ]

;  ask children [ set ischild? False]

  ; Reset the environment
;  ask dogs [ move-to one-of patches ]
;  ask sheep [ move-to one-of patches ]
;  set sum-fitness calc-score
;  set min-fitness calc-score
;  clear-plot
;  reset-ticks
;end

to go
  ask sheep [
    sheep-move
  ]
  ask dogs [
    if dog-behaviour = "default" [dog-default-move]
    if dog-behaviour = "genetic" or dog-behaviour = "genetic-evolve" [dog-ga-move]
  ]
  let score calc-score
  set sum-fitness sum-fitness + score
  if min-fitness > score [set min-fitness score]
  if min-fitness < best-min [set best-min min-fitness]
  tick

  if ticks = evo-runtime and dog-behaviour = "genetic-evolve" and cur-gen < ngen [ ; if we've reached the sim cutoff and are evolving
    ask dogs [ set-ind-fitness ]
;    reset
  ]
  if dog-behaviour = "default" or dog-behaviour = "genetic" or cur-gen = ngen  [
    if ticks = test-ticks [
      ask dogs [set-ind-fitness]
      show reverse sort-on [fitness] dogs
      user-message "Test time elapsed, final fitness per dog has been calculated (printed to terminal from best -> worst)" stop
    ]
  ]
end

to-report avg-fitness
  report sum-fitness / (ticks + 1)
end

to-report calc-score
  let sum-x 0
  let mean-x 0
  let sum-y 0
  let mean-y 0
  let sum-var-x 0
  let sum-var-y 0

  ask sheep [
    set sum-x sum-x + xcor
    set sum-y sum-y + ycor
  ]
  set mean-x sum-x / num-sheep         ; avg x cor
  set mean-y sum-y / num-sheep         ; avg y cor

  ask sheep [
    set sum-var-x sum-var-x + ((xcor - mean-x) ^ 2)
    set sum-var-y sum-var-y + ((ycor - mean-y) ^ 2)
  ]
  report (sum-var-x + sum-var-y) / num-sheep
end

; ------------------------------------------- Action Set -------------------------------------------
to-report move-dog-on-patch ; 1. If current patch has dog, get outta there
  if any? dogs-here [ ; If there is a dog on current patch
    let dog-free-patches neighbors4 with [not (any? dogs-here)] ; Gets dog-free neighbors
    if dog-free-patches != nobody [
       move-to one-of dog-free-patches ; Moves to a dog-free neighbor
       set last-action 1
       report 1
    ]
  ]
  report 0
end

to-report move-away-from-dogs ; 2. If near dogs, go to non-dog patch
  if any? neighbors4 with [any? dogs-here] [ ; If there are neighboring patches with a dog
     let dog-free-patches neighbors4 with [not (any? dogs-here)] ; Gets dog-free neighbors
     if count dog-free-patches > 0 [
       move-to one-of dog-free-patches ; Moves to a dog-free neighbor
       set last-action 2
       report 1
     ]
  ]
  report 0
end

to-report move-group-sheep ; 3. Move to empty patch with nearby sheep
  let this-sheep self
  let candidates []
  let no-sheep-patches neighbors4 with [not (any? sheep-here)]
  ask no-sheep-patches [if any? neighbors4 with [any? sheep-here with [self != this-sheep]] [
    set candidates lput self candidates ; Put neighbors that fulfill sheep-ful condition into candidate set
  ]]
  set candidates patch-set candidates ; Convert candidates to stop NetLogo whining
  if any? candidates [ ; If there are neighboring patches with no sheep
    move-to one-of candidates ; Moves to a neighbor next to friends
    set last-action 3
    report 1
  ]
  report 0
end

to-report move-to-fewer-sheep ; 4. Move to patch with less sheep
  let num count sheep-here
  let candidates neighbors4 with [count sheep-here < num]
  if any? candidates [
     move-to one-of candidates
     set last-action 4
     report 1
  ]
  report 0
end

to move-random ; 5. Do as before, or randomly select one of 4 choices
  let a 0
  let choice random-float 100 ; 5.
  ( ifelse
    ( choice < 50 ) [
      if last-action = 0 [stop]
      if last-action = 1 [
        set a move-dog-on-patch
        stop
      ]
      if last-action = 2 [
        set a move-away-from-dogs
        stop
      ]
      if last-action = 3 [
        set a move-group-sheep
        stop
      ]
      if last-action = 4 [
        set a move-to-fewer-sheep
        stop
      ]
    ]
    (choice < 62.5) [
        set a move-dog-on-patch
        stop
    ]
    (choice < 75) [
        set a move-away-from-dogs
        stop
    ]
    (choice < 87.5) [
        set a move-group-sheep
        stop
    ]
    (choice < 100) [
        set a move-to-fewer-sheep
        stop
    ]
  )
end



; --------------------------------------- Dog Implementation ---------------------------------------
to dog-default-move ; Choose from Action Set with equal probabilities over all 5 choices
  let a 0
  let choice random 100 ; 5.
  ( ifelse
    ( choice < 20 ) [ ; Do previous action
      if last-action = 0 [stop]
      if last-action = 1 [
        set a move-dog-on-patch
        stop
      ]
      if last-action = 2 [
        set a move-away-from-dogs
        stop
      ]
      if last-action = 3 [
        set a move-group-sheep
        stop
      ]
      if last-action = 4 [
        set a move-to-fewer-sheep
        stop
      ]
    ]
    (choice < 40) [
        set a move-dog-on-patch
        stop
    ]
    (choice < 60) [
        set a move-away-from-dogs
        stop
    ]
    (choice < 80) [
        set a move-group-sheep
        stop
    ]
    (choice < 100) [
        set a move-to-fewer-sheep
        stop
    ]
  )
end

to dog-ga-move ; Movement using chromosomes
  let s item 0 chromosome
  let d item 1 chromosome
  let candidates neighbors4
  let best-patch max-one-of candidates [neighbor-scores s d] ; Calculate cost of candidates based on proximity to sheep/dogs, weighted by genes
  move-to best-patch
end

to-report neighbor-scores [ s d ]; Aim to maximise score of tile
  let score 0
  let p myself
  ask sheep [
    let dist distance p
    if dist != 0 [set score score + ( 1 / dist ) * s]
  ]
  ask dogs [
    let dist distance p
    if dist != 0 [set score score + ( 1 / dist ) * d]
  ]
  report score
end

to set-ind-fitness
  ;let score calc-score
  let score avg-fitness
  set fitness score * (1 + sum (inv-dist))
end

to-report inv-dist ;[other-ind] ; Inverse distance
  let dists []
  ask other dogs [ set dists lput ind-dist chromosome dists]
  report map [ [dist] -> alpha / (1 + dist) ] dists
end

to-report ind-dist [c];[other-ind]; Distance from an individual in fitness landscape
  let a ((item 0 c) - (item 0 chromosome)) ^ 2
  let b ((item 1 c) - (item 1 chromosome)) ^ 2
  report sqrt (a + b)
end

to-report genetic-difference [other-dog]
  report sqrt ( ( item 0 chromosome - item 0 ([chromosome] of other-dog)) ^ 2 +
                ( item 1 chromosome - item 1 ([chromosome] of other-dog)) ^ 2)
end

to-report tournament-select
  let participants n-of 3 other dogs
  let p 0.6 ; Probability of selecting top dog over lesser beings
  let participants-f reverse sort-on [fitness] participants ; Sort by fitness, lowest first
  let sel random-float 1
  ; Select a tournament winner according to: ρ*((1- ρ)^α
  ; where α is the index of the sorted participant
  let index 0
  let curp 0
  loop [
    if index > 2 [report max-one-of participants [fitness]]
    set curp curp + (p * (( 1 - p ) ^ index))
    if curp > sel [ report item index participants-f ]
    set index index + 1
  ]
end

to-report crossover [ c1 c2 ]
  let sel random-float 1
  if sel <= 0.5 [report list (item 0 c1) (item 1 c2)]
  report list (item 0 c2) (item 1 c1)
end

to-report mutate [c] ; Mutate a single gene
  let sel random length c
  let mutconst -1 + random-float 2 ; Random float between -1 and 1
  let newg (item sel c) + mutconst
  if newg < gene-min [set newg gene-min]
  if newg > (gene-min + gene-range) [set newg (gene-min + gene-range)]
  report replace-item sel c newg
end

; -------------------------------------- Sheep Implementation --------------------------------------
to sheep-move
  let a move-dog-on-patch ; 1.
  if a = 1 [stop]
  set a move-away-from-dogs ; 2.
  if a = 1 [stop]
  set a move-group-sheep ; 3.
  if a = 1 [stop]
  set a move-to-fewer-sheep ; 4.
  if a = 1 [stop]
  move-random
end
@#$#@#$#@
GRAPHICS-WINDOW
10
10
608
609
-1
-1
12.041
1
10
1
1
1
0
1
1
1
-24
24
-24
24
0
0
1
ticks
30.0

SLIDER
10
815
157
848
num-dogs
num-dogs
5
15
5.0
1
1
NIL
HORIZONTAL

SLIDER
10
856
157
889
num-sheep
num-sheep
25
60
50.0
1
1
NIL
HORIZONTAL

BUTTON
545
864
609
897
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
457
864
520
897
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

PLOT
10
617
424
784
Dogs' Score
Time
Fitness
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"score" 1.0 0 -16777216 true "" "plot calc-score"

MONITOR
432
669
515
714
Avg. Score
precision avg-fitness 3
17
1
11

MONITOR
432
720
515
765
Min. Score
precision min-fitness 3
17
1
11

MONITOR
432
619
515
664
Current Score
precision calc-score 3
17
1
11

TEXTBOX
172
790
187
930
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n
11
0.0
1

SLIDER
187
815
324
848
evo-runtime
evo-runtime
1000
10000
5000.0
500
1
ticks
HORIZONTAL

MONITOR
523
618
608
663
Generation
cur-gen
17
1
11

MONITOR
523
668
608
713
Best Avg.
precision best-avg 3
17
1
11

MONITOR
524
720
608
765
Best Min.
precision best-min 3
17
1
11

SLIDER
188
855
324
888
ngen
ngen
50
200
50.0
10
1
NIL
HORIZONTAL

TEXTBOX
26
788
156
816
Basic Params (DISABLED)
11
0.0
1

TEXTBOX
222
789
449
817
GA/Evolution Settings (DISABLED)
11
0.0
1

SLIDER
188
896
325
929
alpha
alpha
0
5
0.2
0.1
1
NIL
HORIZONTAL

TEXTBOX
336
898
442
926
How much to punish poor genetic diversity
11
0.0
1

CHOOSER
10
896
158
941
dog-behaviour
dog-behaviour
"default" "genetic"
1

SLIDER
332
815
424
848
cxpb
cxpb
0
1
0.2
0.05
1
NIL
HORIZONTAL

SLIDER
332
855
424
888
mutpb
mutpb
0
1
0.2
0.05
1
NIL
HORIZONTAL

SLIDER
457
903
609
936
test-ticks
test-ticks
5000
30000
20000.0
1000
1
NIL
HORIZONTAL

TEXTBOX
462
817
612
873
Setup uses fixed chromosomes in this file to generate 1 set of pre-evolved dogs
11
0.0
1

@#$#@#$#@
# Adaptation Implementation

## How to Use
Directly underneath the main view of the simulation is a plot which tracks shared fitness of the dogs each tick using the equation provided in the assessment (variance of coordinates for all sheep). To the right of the plot are monitors to track the average shared fitness over the length of the simulation, the minimum achieved fitness, and the best average/minimum out of all generations if the dogs are allowed to evolve their solution.

Under the Basic Parameters header are sliders to choose the number of sheep/dogs created on setup and what behaviour set dogs should use (default, genetic algorithm with current chromosomes, or genetic algorithm with evolution). A larger number of dogs is used for the purposes of evolution, but the final evaluation is performed with only the fittest 5 dogs achieved by adaptation.

GA/Evolution Settings allows for the setting of metaparameters such as crossover probability, mutation probability, the number of ticks to run a generation for, how many generations to adapt for, and an alpha value that determines if/how much genetic diversity is explicitly encouraged (more in the "Fitness of Individuals and Genetic Diversity" section)

test-ticks automatically halts the simulation after the specified ticks have been elapsed, then prints the list of dogs to the terminal in order of best (first) to worst (last) fitness. If the dogs are set to evolve then this only occurs on the final generation after all evolution has occurred.

## Representation of Dog Behaviour
Dogs each possess a chromosome with 2 genes, both representing repulsion or attraction to either sheep (gene 1) or dogs (gene 2). A dog with a high value for gene 1 will favour moving to tiles which bring them closer to a large number of sheep, and vice versa.

When a dog evaluates where it wants to go each tick, it checks its 4 neighbours for the highest-scoring tile. The tile's score is calculated by the following equation:
```
tile_score(p, d, s) = sum ( gene1 / distance(p, di) ) + sum ( gene2 / distance(p, si) )
                      (di -> dx where di != this dog)   (si -> sx)
```
Where distance(p, t) is calculated by using the Pythagorean formula on the currently occupied patch's x and y coordinates, and the other turtle's x and y coordinates. Dogs do not evaluate their own tile (i.e. they will always move to another tile each tick) so the case in which distance (p, t) = 0 does not occur.

This solution was chosen for its small search space while still providing a representation that considers the most important factors (the location of other agents relative to the dog) and having the minimum size necessary to have meaningful adaptation. It also allows for individuals to develop distinct context-sensitive behaviours based on how all other agents are currently positioned.

## Fitness of Individuals and Genetic Diversity
Setting the alpha parameter to 0 stops the model from encouraging genetic diversity.

The fitness score is shared across the whole population, but we need some way to evaluate how much an individual contributes to that score while maintaining genetic diversity so that unique behaviours can be represented in the final solution.

An individual's fitness should be directly proportional to the fitness of the whole group, f(d).

In order to ensure diversity among the population, a dog's fitness should be penalised if they occupy a position in the fitness landscape close to another dog, as this means they are not contributing to diversity in the population. Since this is a minimisation problem, a dog's individual fitness score should be scaled up according to the number of other dogs near them in the fitness landscape, as well as their proximity. 

This means an individual dog's fitness is an equation proportional to the group's fitness, scaled by a term representing how many other dogs occupy a position in the fitness landscape that is close to them. Let's call this term C for closeness. 

The equation representing an individual's fitness is then: f(d) * C
Where C is a positive constant

C should represent how isolated an individual is in the fitness landscape, so should be inversely proportional to the individual's distances to other individuals - i.e. a low distance should penalise more (more crowding, so increase the score) than a large distance (more sparse distribution of individuals across landscape, so lower or no penalty)

C can be the summation of inversely scaled distances from an individual, di, to all other individuals, dj (where j != i). C should therefore look something like: sum(invdist(di, dx))

Where:
invdist(di, dx) = a / (1+distance(di, dx))

1 is added to the denominator to avoid a rare but possible division by 0 error.

'a' (alpha) is a positive scaling term to represent how much diversity should affect the fitness evaluation. A larger distance causes the resulting term to tend towards a minimum of 0, reducing its impact on fitness. Conversely, as the distance gets smaller the resulting term tends towards a maximum of alpha. Thus if alpha is set to 0 the effect of this scaling term is eliminated.

Since the dogs' chromosomes only contain 2 genes, it is easier to visualise what distance(di, dx) represents graphically:
```
     Gene 1
 d2 |
    |d1
----+---- Gene 2
    |
  dx|
```

distance(di, dx) is just the size of the hypotenuse between two chromosomes, where gene 1 is the y coordinate and gene 2 is the x coordinate: 

sqrt ( (d1.g1) - (dx.g1) )<sup>2</sup> + ( (d1.g2) - (dx.g2) )<sup>2</sup> )

The final fitness function for individuals is then:
```
f_ind(di) = f(d) * (1 + (sum(invdist(di, dx)))
                        (dx -> dN where dx != di)

invdist(di, dx) = a / (1+distance(di, dx))

distance(di, dx) = sqrt ( (di.g1) - (dx.g1) )^2 + ( (di.g2) - (dx.g2)^2 )
```
1 is added to the result of the summed inverse distances in order to ensure the minimum fitness for an individual is still equal to the fitness of the population. This way individuals will still be sufficiently rewarded for lowering the population score and not be over-incentivised to seek maximum genetic diversity without benefit to the overall solution.

## Reproduction
Setting the cxpb parameter to 0 stops crossover from happening.

Crossover is done by rolling a random number for each dog, and if this number meets or exceeds `1 - cxpb` then another parent is chosen from the population via tournament selection to reproduce with them. Tournament selection takes `N=3` participants, who are not the already selected parent, and uses a probability function `p*((1-p)^a)` to determine how likely each participant is to win based on fitness. `p` is set to 0.6 so that the fittest participant has a 60% chance of winning. `a` is the ranking of the participant in terms of fitness, with the fittest having a rank of 0 and the least fit having a rank of N-1

Children always replace a member of the parent population, and choose who to replace based on how similar their gentic code is (i.e. who is closest to them in the solution space). Crossover reduces genetic diversity, however replacing only the most genetically similar parent means this effect is less pronounced. A more ideal solution might make it so that children only replace the genetically closest parent if the child has a better fitness than them, however as the agent based model features stochastic elements the fitness cannot be measured at the point of conception. Therefore I have chosen to have children always replace their most genetically similar parent.

## Mutation
Setting the mutpb parameter to 0 stops mutation from happening.

Mutation is done by adding or subtracting a small constant (between -1 and 1) to one of the dog's genes. The resulting value is bounded by the same maximum and minimum values used to create the genes when the initial population of dogs are made.

## Evaluation Method
Each population will be tested over 20,000 ticks with 5 dogs and 50 sheep in a size N=49 environment. The observed value used to statistically test populations against one another will be the average fitness over the 20,000 tick test, as this statistic should best indicate the population's overall performance while still accounting for randomness between runs.

In order to explore the effect of meta-parameters on the genetic algorithm-based solution, a baseline needs to be defined for comparison against. This baseline will use the following meta-parameters:
```
num-dogs = 15
num-sheep = 50
ngen=50
cxpb = 0.2
mutpb = 0.2
alpha = 0.2
evo-runtime = 5000 ticks
```
The number of dogs is only set this high for the evolution stage. Once the solution has evolved for the specified number of generations, only the fittest 5 dogs will be tested. This will be done by getting the top 5 dogs printed to the observer terminal after the evolutionary process finishes running, copying their chromosomes, then resetting the simulation with 5 dogs and the "genetic" behaviour, then manually setting each dog's chromosomes to the 5 top-performing chromosomes from the evolved solution and running that.

A new set of dogs will be evolved for each observation for a set of meta-parameters. This is so that the reliability of evolution with the meta-parameter set is represented rather than the reliability of a single solution.

The solutions produced by different meta-parameters are independent of one another, and as the distributions of their average fitnesses cannot be assured, I will use a non-parametric unpaired statistical test to compare the statistical difference between my results. Thus I will use the Mann-Whitney U test with a significance level of α=0.05.

## Results
Default: `399.318, 393.748, 364.914, 396.099, 372.611, 380.569` (Avg. 384.543)
Base GA: `371.458, 376.802, 359.832, 372.805, 390.092, 377.078` (Avg. 374.678)

Performing Mann-Whitney U on the average fitnesses of the default and evolved models results in a p value of 0.240. This is not small enough to suggest there is a statistically significant difference in the results of the genetic algorithm compared to the default dog implementation. The genetic representation and behaviour is more than likely too simple to develop substantially different performance than the default behaviour. A more complex solution that could evolve better results might possess some way to identify where sheep have grouped up, and have genes which determine what group size a dog prefers to chase, and a behaviour which says once they are in proximity to that group that they should chase it towards another group of sheep, where target size and closeness to the second group could be determined genetically. This would bake in some more intentionality into the dogs' actions, while still allowing for differing behaviours (e.g. some dogs may pursue singular rogue sheep or small groups and attempt to push them into the closest group; others may try and keep larger groups compacted)

Alpha=2: `383.158, 398.704, 374.732, 386.495, 391.023, 391.186` (Avg. 387.550)

Performing Mann-Whitney U on the average fitnesses of the Base GA and alpha=2 models results in a p value of 0.041. This is less than the significance level of 0.05, so the alpha value clearly has a noteworthy effect on results. The average results of the model with the increased alpha value is worse than that of the GA with an alpha of 0.2. This is likely the case because a high alpha over-penalises similar solutions and drives each individual to be as genetically different as possible, putting too much emphasis on genetic diversity over the shared fitness over the population and thus leading to a worse overall fitness.

cxpb=0.8: `373.725, 390.985, 389.225, 386.172, 382.301, 391.326` (Avg. 385.622)

Performing Mann-Whitney U on the average fitnesses of the Base GA and cxpb=0.8 models results in a p value of 0.0649. This is not quite low enough to confidently say that increasing the crossover probability significantly affects the results of the model.

mutpb=0.8: `383.392, 379.274, 379.579, 355.362, 366.826, 357.776` (Avg. 370.368)

Performing Mann-Whitney U on the average fitnesses of the Base GA and mutpb=0.8 models results in a p value of 0.818. This is not small enough to suggest that a high mutation probability drastically impacts the average shared fitness of the resulting model. This result is unexpected, since a high mutation probability makes the solution more similar to a random search and therefore should give a higher spread of resultant fitnesses than a reliable genetic algorithm that evolves a similarly performing solution each run. What this might suggest is that the current model's evolution process is no more powerful than a random search, perhaps because the solution space being explored for 2 genes with set boundary values is too small.

evo-runtime=10000 ticks: `394.569, 377.134, 378.909, 378.325, 384.621, 389.936` (Avg. 383.915)

Performing Mann-Whitney U on the average fitnesses of the Base GA and evo-runtime=10000 models results in a p value of 0.041. This is lower than the significance level, which suggests that the results are significantly different. The average of these results is worse than those of the lower evolution runtime, which shows that giving the dogs more time to improve their score does not actually help to identify fitter individuals with the current implementation.

In light of these results, the final evolved solution for the test file has been evolved using the Base GA parameters.
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
