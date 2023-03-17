import glob
import pickle
import os
import numpy as np

import elephant
import elephant.spike_train_correlation as STC
import matplotlib.pyplot as plt
import neo
import pandas as pd
import quantities as pq
import seaborn as sns

from elephant.conversion import BinnedSpikeTrain as BST

sns.set(style="white")
sns.set_color_codes("dark")
sns.set_context("paper", font_scale=1.3,
                rc={"lines.linewidth": 2., "grid.linewidth": 0.1})



def split(x, idx=1):
    x = os.path.splitext(x)[0]
    return int(x.split('_')[idx])


if __name__ == '__main__':
    directories = ['output_10_10/', 'output_200_4/', 'output_600_22/', 'output_1600_30']
    middles = [f'middle {i}' for i in range(20)]
    fig, axes = plt.subplots(2, 2, figsize=(18, 12), sharex=True, sharey=True)
    plt.subplots_adjust(hspace=0.07, wspace=0.05)
    cbar_ax = fig.add_axes([.91, .3, .03, .4])
    font_size = 18
    n_bins = 2000
    bin_size = 20 * pq.ms
    binned_sts = []  # list for binned spiketrains
    t_start = 3 * pq.ms
    t_stop = 40000 * pq.ms
    for ax, directory in zip(axes.ravel(), directories):
        files = glob.glob(f'{directory}/output_all_*.pkl')
        corrmap = []
        print(f'Directory {directory}')
        for output in files:
            print(output)
            with open(output, 'rb') as f:
                res = pickle.load(f)
            sts = []
            for st in res['input']:
                sts.append(neo.SpikeTrain(st['times']*pq.ms, t_start=t_start, t_stop=t_stop))
            for st in res['output']:
                sts.append(neo.SpikeTrain(st['times']*pq.ms, t_start=t_start, t_stop=t_stop))
            binned = BST(sts, bin_size=bin_size)
            corrmap.append(STC.correlation_coefficient(binned))
        corr = np.array(corrmap).mean(0)
        print(f'corr max {corr[11:, :11].max()}, corr min {corr[11:, :11].min()}')
        labels_in = ['Visual Red', 'Visual Green', 'Smell Left',
                     'Smell Middle', 'Smell Right', 'Nociceptive', 'Reward',
                     'Nest Left', 'Nest Middle', 'Nest Right', 'On Nest']
        labels_out = ['Move', 'Left', 'Right', 'Pheromone']
        vmax = 0.6 # -.45913
        g = sns.heatmap(corr[11:, :11], annot=True, vmin=-vmax,
                        vmax=vmax, cmap='vlag',
                        ax=ax, cbar_ax=cbar_ax, annot_kws={"size": 12}, fmt='.3f')
        print(corr[11:, :11].min(), corr[11:, :11].max(),)
        g.set_yticklabels(labels_out, size=font_size, rotation=0)
        g.set_xticklabels(labels_in, size=font_size, rotation=90)
        generation = split(directory, 1)
        ax.set_title(f'Generation {generation}', size=font_size)
    # plt.show()
    fig.savefig(f'correlation_map_mean.pdf',
               dpi=600, bbox_inches='tight', pad_inches=0.1)
