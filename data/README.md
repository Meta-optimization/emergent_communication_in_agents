# Data and figure guide 
## Data 

1. `fitness_full` and `fitness_impaired` contain the fitnesses as `csv` files. `fitness_full` are the results in which case the 
    pheromone pathways are activated. `fitness_impaired` contains the results, where the ants' pheromone pathways are impaired and they have 
    to rely on their visual system. The first line of the file encompasses the weights, the second line are the delays, the last row shows 
    the achieved fitness.  
1. `output_*_*` contain Python pickle files with the networks' spiking activity coming from the NEST simulation.
    E.g. `output_10_20` indicates generation `10` individual `20`. When the pickle file is loaded, it contains dictionaries with the spikes divided 
    into the three layers of the network.
1. `performance_comparison` contains `csv` files indicating the foraging performance on a test simulation. NetLogo (BeaviourSpace) generates 
   these files, thus the relevant information is from line 6 on. The columns contain the `seed`, `step` (simulation steps), 
   and `food_collected` (units of food collected, i.e. the performance) over 100 trials. 
1. `heatmap` contains `csv` files with the `x, y` position within the environment and the amount of pheromone on that position 
    to create the heatmap of the pheromone concentration. 
 
## Figures 
This part explains how to create the figures in the manuscript. 

1. `fitness_plot.py` plots Figure 11, the fitness of the ant colony. Requires folders `fitness_full` and `fitness_impaired`.
1. in the directory `trials_benchmark`, `ci_lineplot.py` plots Figure 12, depicting the best individual's performance as a confidence interval over the last hundred generations and averaged over 100 trials.
1. `heatmap_concentration_gens.py` plots Figure 13, the pheromone concentration heatmap over different generations. Requires folder `heatmap`.
1. `plot_performance.py` plots Figure 14, the performance comparison of different ant colony models. Requires folder `performance_comparison`.
1. `correlation_heatmap.py` plots Figure 15, the correlation heatmap between the network input and output spike trains. Requires folders `output_*_*`.
1. `correlation_coeffecient.py` plots Figure 16, the correlation coefficients of input and output spike trains for the first ant of the best individual. Please first unpack the tar file `results_spikes_best_of_generation.tar.gz`. 
Requires folder `results_spikes_best_of_generation`
