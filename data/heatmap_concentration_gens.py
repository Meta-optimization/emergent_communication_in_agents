import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
import seaborn as sns

sns.set_theme(style="white")
sns.set(font_scale=2.5, rc={'axes.edgecolor':'white','axes.facecolor': '#03051A',  'axes.grid': False, 'figure.facecolor': 'white'})

def plot_jointplot(ants, chemical, food, filename, font_size=18):
    g = sns.JointGrid(data=chemical, x="x", y="y", xlim=(-9,44), ylim=(-10, 70), space=0, height=10)
    g.plot_joint(sns.kdeplot, fill=True, thresh=0, levels=100, cmap="rocket")
    sns.scatterplot(data=pd.DataFrame({'x':[100-82], 'y':[30]}), x='x', y='y', ax=g.ax_joint,
                    color='brown', alpha=0.7, marker='H', s=2000, **dict(edgecolor="face"))
    sns.scatterplot(data=ants, x='x', y='y', ax=g.ax_joint, color='white', s=100,)
    sns.scatterplot(data=food, x='x', y='y', ax=g.ax_joint, color='green', alpha=0.7)

    g.plot_marginals(sns.kdeplot, color="#03051A", alpha=0.7, fill=True), #bins=50, kde=True)
    g.ax_marg_x.set_facecolor('white')
    g.ax_marg_y.set_facecolor('white')
    fig = g.figure
    fig.savefig(filename + '.png', bbox_inches='tight', pad_inches=0.1, dpi=600)
    return fig


if __name__ == '__main__':
    # timestamps
    timestamps = np.sort([f for f in os.listdir('heatmap') if f.startswith('colony_data_gen') and f.endswith('.csv')])
    for t in timestamps:
        print(t)
        csv = pd.read_csv(os.path.join('heatmap', str(t)))
        # cast x and y to integer
        csv['x'] = csv['x'].astype(int)
        csv['y'] = csv['y'].astype(int)
        # get specific category
        ants = csv.loc[(csv == 'ant').any(axis=1)]
        chemical = csv.loc[(csv == 'chemical').any(axis=1)]
        mask = csv.loc[(csv == 'chemical').any(axis=1)]['amount'] > 1
        chemical = chemical.loc[mask]
        food = csv.loc[(csv == 'food').any(axis=1)]
        plot_jointplot(ants, chemical, food, t.removesuffix('.csv'))
    plt.show()
