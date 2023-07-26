import glob
import pickle
import os
import numpy as np
import scipy

import elephant
import elephant.spike_train_correlation as STC
import matplotlib.pyplot as plt
import neo
import pandas as pd
import quantities as pq
import seaborn as sns

from elephant.conversion import BinnedSpikeTrain as BST


sns.set(style="white",
        rc={'xtick.bottom': True, 'ytick.left': True})
sns.set_color_codes("dark")
sns.set_context("paper", font_scale=1.3,
                rc={"lines.linewidth": 1.8, "grid.linewidth": 0.1})


def split(x, idx=1):
    x = x.split('/')[1]
    print(x)
    x = os.path.splitext(x)[0]
    print(x)
    return int(x.split('_')[idx])


def create_dataframe(binned_spiketrains):
    dataframes = [pd.DataFrame(STC.correlation_coefficient(b)[11:, :11]) for b in binned_spiketrains]
    dataframe = pd.concat([d.T for d in dataframes])
    dataframe.columns = ['Move', 'Left', 'Right', 'Pheromone']
    actions = ['Visual Red', 'Visual Green', 'Smell Left',
                'Smell Middle', 'Smell Right', 'Nociceptive', 'Reward',
                'Nest Left', 'Nest Middle', 'Nest Right', 'On Nest']
    dataframe['Inputs'] = actions * len(files)
    dataframe['Generations'] = np.repeat(np.arange(10, len(files) + 10), len(dataframe)/len(files)) * 10
    dataframe.index = range(len(dataframe))
    # hues = ['Visual Red', 'Visual Green', 'Smell Left', 'Smell Middle', 'Smell Right']
    # new_frame = dataframe[dataframe['Inputs'].isin(hues)]
    return dataframe, actions


def plot_regression(binned_spiketrains, show=True):
    # corrcoeff = STC.correlation_coefficient(binned_sts[-1])
    # corrcoeff.shape
    # sns.heatmap(corrcoeff[11:,:11],cmap='vlag',vmin=-1, vmax=1)
    dataframes, actions = create_dataframe(binned_spiketrains)
    pal = sns.color_palette('rocket', 5)
    # whether to standarize the y data
    standardized = False
    fig = plt.figure(figsize=(22, 12))
    for row_i, cols in enumerate(['Move', 'Left', 'Right', 'Pheromone']):
        print(cols)
        j = 0
        col_set = False
        for i, inp in enumerate(actions):
            if i < len(actions):
                # ax = plt.subplot(4, 11, (row_i + 1) * (i+1))
                mask = dataframes['Inputs'] == inp
                y = dataframes[mask][f'{cols}']
                if y.isnull().any():
                    x = dataframes[mask].Generations.values
                    x = x[~y.isnull()]
                    y = y[~y.isnull()].values
                else:
                    x = dataframes[mask].Generations.values
                if standardized:
                    y =  (y - y.mean()) / y.std() # (y - y.min()) / (y.max() - y.min())
                slope, intercept, r_value, p_value, std_err = scipy.stats.linregress(x=x, y=y)
                # print(slope, intercept, r_value, p_value, std_err, r_value**2)
                if p_value < 0.005:
                    ax = plt.subplot2grid((4, 22), (row_i, j), colspan=2, **{'ylim': (-1, 1)})
                    j += 2
                    ax.axhline(**{'color':'gray', 'alpha':0.5, 'ls':'--', 'lw': 1})
                    p = sns.regplot(data=dataframes[mask], x=x, y=y,
                                    scatter=True, fit_reg=True, seed=0, ax=ax, n_boot=1000,
                                    label=f' $\sigma=${y.std():.4f} \n s={slope*1700/2:.4f}', #\n p={p_value:.4f}'
                                    color=pal[row_i],)
                                    # line_kws={"color": pal[-1]})
                    p.set_title(inp)
                    # legend without border and without marker
                    p.legend(frameon=False, handlelength=0, handletextpad=0, markerscale=0)
                    if not col_set:
                        p.set_ylabel(f'{cols}')
                        col_set = True
                    else:
                        p.set_ylabel(f' ')
                        p.set_yticks([])
                    # remove labels on the x-axis besides the last row
                    if row_i != 3:
                        # p.set_xticks([])
                        p.tick_params(axis='x', labelbottom=False, bottom=False,)
                    else:
                        p.tick_params(axis='x', rotation=30)
    plt.subplots_adjust(hspace=0.3, wspace=0.3)
    if standardized:
        fname = 'correlation_regression_standardized.pdf'
    else:
        fname = 'correlation_regression.pdf'
    if show:
        plt.show()
    else:
        plt.savefig(fname,
                    dpi=600, bbox_inches='tight', pad_inches=0.1)


if __name__ == '__main__':
    files = glob.glob('results_spikes_best_of_generation/*.pkl')
    files = np.array(sorted(files, key=lambda x: split(x, 3)))
    # load individual data and create matrix to correlate
    binned_sts = []  # list for binned spiketrains
    t_start = 3 * pq.ms
    t_stop = 40000 * pq.ms
    n_bins = 2000
    for output in files:
        print(output)
        with open(output, 'rb') as f:
            res = pickle.load(f)
        sts = []
        for st in res['input']:
            sts.append(neo.SpikeTrain(st['times']*pq.ms, t_start=t_start, t_stop=t_stop))
        for st in res['output']:
            sts.append(neo.SpikeTrain(st['times']*pq.ms, t_start=t_start, t_stop=t_stop))
        binned_sts.append(BST(sts, n_bins=n_bins))
    plot_regression(binned_sts, False)
