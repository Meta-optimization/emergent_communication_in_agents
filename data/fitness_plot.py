import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from collections import OrderedDict
from functools import partial

sns.set_context('talk')

def func(x, index):
    return int(x.split('_')[index])


if __name__ == '__main__':
    folders = ['fitness_full', 'fitness_impaired']
    colors = ['tab:blue', 'tab:green']
    plt.figure(figsize=(10, 8))
    for idx, f in enumerate(folders):
        print(f'traversing folder {f}')
        csvs = glob.glob(f'{f}{os.path.sep}*.csv')
        # the csvs are in form: individual_gen_indi_results.csv
        # create a function to split strings via "_" and take 2. argument
        index = [3, 1][idx]
        # we sort according the gen index
        csvs = sorted(csvs, key=partial(func, index=index))
        # create an ordered dictionary to store gen_idx as key and
        # fitness values for that index
        ordered_dict = OrderedDict()
        for ci in csvs:
            c = os.path.basename(ci)
            # get generation and individual index
            gen_idx = func(c, 1)
            indi_idx = func(c, 2)
            fitness_value = pd.read_csv(
                ci, header=None, na_filter=False).iloc[-1][0]
            if gen_idx not in ordered_dict:
                ordered_dict[gen_idx] = [fitness_value]
            else:
                ordered_dict[gen_idx].append(fitness_value)
            mu = []
            sigma = []
            maxes = []
            for k, v in ordered_dict.items():
                mu.append(np.mean(v, 0))
                sigma.append(np.std(v, 0))
                maxes.append(np.max(v, 0))
        # plt.errorbar(ordered_dict.keys(), mu, sigma, fmt='-o')
        plt.plot(ordered_dict.keys(), mu, c=colors[idx], lw=2)
        plt.plot(ordered_dict.keys(), maxes, ':', c=colors[idx], linewidth=2)
        y1 = np.array(mu) + np.array(sigma)
        y2 = np.array(mu) - np.array(sigma)
        plt.plot(ordered_dict.keys(), y1, color=colors[idx], alpha=0.1)
        plt.plot(ordered_dict.keys(), y2, color=colors[idx], alpha=0.1)
        plt.fill_between(ordered_dict.keys(), y1, y2, alpha=.2, color=colors[idx])
    plt.xlabel('Generations')
    plt.ylabel('Fitness')
    plt.savefig('fitness.pdf', bbox_inches='tight', pad_inches=0.1)
    # plt.show()
