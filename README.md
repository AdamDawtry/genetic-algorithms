# genetic-algorithms
A project using genetic algorithms to solve a few different problems.

## Predicting Escooter Sales
The Jupyter notebook contains an exploration of data about eScooter sales on different days, and a large list of properties for each day. I used a genetic programming approach to essentially stitch together variables and mathematical operators in order to optimise a predictor for how many eScooter sales could be expected on a day with certain properties.

This work has been also been rendered into a PDF, complete with graphs.

## Border Collie Optimisation
Making a simulation of dogs to herd sheep into as tight a formation as possible is a problem known as Border Collie Optimisation. I used NetLogo as my simulation framework and created an implementation of a Dog agent which could be evolved, featuring genes and selection criteria to choose mostly fit individuals from the population while still allowing genetic diversity. Some of the maths involved in this is described in the Info section of the NetLogo files, but it boils down to imposing penalties on individuals' fitnesses based on how genetically similar they are to other members of their population, incentivising them to specialise or find their own behavioural niche.