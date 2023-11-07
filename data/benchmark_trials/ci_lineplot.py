#!/usr/bin/env python3

import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from collections import OrderedDict
from functools import partial
from pathlib import Path

sns.set_context('talk')

def func(x, index):
    """
    Splits file at `_` and returns part at position `index`
    """
    # remove extension
    x = Path(x).stem
    return int(x.split('_')[index])

def get_fitnesses(x, index=7):
    """
    `x` is expected to be a pandas dataframe.
    The function grabs the last column from the (default 7th) row on.
    """
    return x.iloc[index:-1,-1].astype(float).to_numpy()

def create_dataframe(csvs):
    data_frames = []
    gen_indexes = []
    for ci in csvs:
        csv = pd.read_csv(ci, header=None, na_filter=False)
        gen_idx = func(ci, 1)
        gen_indexes.append(gen_idx)
        # gen_idx = [func(g, 2) for g in csvs]
        fitness = get_fitnesses(x=csv, index=7)
        print(f"Gen idx: {gen_idx}, Length: {len(fitness)}")
        gen_col = [gen_idx] * len(fitness)
        d = {'Generations': gen_col, 'Fitness': fitness}
        data_frames.append(pd.DataFrame(d))
    return pd.concat(data_frames), gen_indexes

if __name__ == '__main__':
    colors = ['tab:blue', 'tab:green']
    plt.figure(figsize=(10, 8))
    csvs = glob.glob('*.csv')
    # the csvs are in form: reviewer_benchmark_1600_30.csv
    csvs = sorted(csvs) # , key=partial(func, index=3))
    print(csvs)
    df, gen_indexes = create_dataframe(csvs)
    sns.lineplot(data=df, x='Generations', y='Fitness',
                 errorbar=('ci', 95), err_style='band', color=colors[0])
    plt.savefig('fitness_ci_lineplot.pdf', bbox_inches='tight', pad_inches=0.1)
    plt.show()
