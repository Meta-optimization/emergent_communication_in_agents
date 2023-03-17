import matplotlib.pyplot as plt
import os
import pandas as pd
import seaborn as sns

sns.set_context('talk')
sns.set_theme(style="white")

def clean_csv(csv):
    csv = csv[6:]
    header = ['Index', 'Seed', 'Ticks', 'Food eaten']
    csv.rename = header
    return csv.astype(int)

if __name__ == '__main__':
    csv1 = pd.read_csv(os.path.join('performance_comparison', 'ant_colony_20cns.csv'))
    csv2 = pd.read_csv(os.path.join('performance_comparison', 'ant_colony_rulebased.csv'))
    csv3 = pd.read_csv(os.path.join('performance_comparison', 'ant_colony_10cns.csv'))
    csv4 = pd.read_csv(os.path.join('performance_comparison', 'ant_colony_20cns_nophero.csv'))
    csv5 = pd.read_csv(os.path.join('performance_comparison', 'ant_colony_20cns_visual.csv'))
    # clean header
    csv1 = clean_csv(csv1)
    csv2 = clean_csv(csv2)
    csv3 = clean_csv(csv3)
    csv4 = clean_csv(csv4)
    csv5 = clean_csv(csv5)
    # merge csvs with only type as column
    ns20 = 'SNN model 1'
    ns10 = '10 Neurons'
    rule = 'Rule Based'
    ns_np = 'SNN model 1 \n impaired \n pheromone'
    visual = 'SNN model 2'
    fontsize=15
    d = {rule: csv2.values[:, -1], ns20: csv1.values[:, -1],
         ns_np: csv4.values[:, -1], visual: csv5.values[:, -1]}
    # ns10: csv3.values[:,-1]}
    df = pd.DataFrame(d)
    g = sns.catplot(data=df, kind='bar', errorbar="sd", palette="rocket", alpha=.8, height=6, aspect=1.3)
    g.set_axis_labels("", r"Food returned in $2000$ steps", size=fontsize)
    g.set_yticklabels(size=fontsize)
    g.set_xticklabels(size=fontsize)
    g.set(ylim=(0))
    g.savefig('performance_food.pdf', bbox_inches='tight', pad_inches=0.1)
    # plt.show()
    print(f'Rule Based: mean: {df[rule].mean()}, std: {df[rule].std()}, median: {df[rule].median()}')
    print(f'20 neurons: mean: {df[ns20].mean()}, std: {df[ns20].std()}, median: {df[ns20].median()}')
    # print(f'20 neurons wo phero: mean: {df[ns_np].mean()}, std: {df[ns_np].std()}, median: {df[ns_np].median()}')
    # print(f'10 neurons: mean: {df[ns10].mean()}, std: {df[ns10].std()}, median: {df[ns10].median()}')
    print(f'Visual: mean: {df[visual].mean()}, std: {df[visual].std()}, median: {df[visual].median()}')
