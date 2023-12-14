# RNA-seq
首先识别数据是否为链特异性测序，从而选择不同的参数（STAR除外，软件可以自动识别）
1.文章里是否提及
2.rseqc工具判断

# 安装
conda install -c bioconda rseqc  
#singularity pull docker://clinicalgenomics/rseqc:4.0.0
# 运行
infer_experiment.py -r genome.bed -i input.bam
#singularity run ~/rseqc_4.0.0.sif infer_experiment.py -r genome.bed -i input.bam
# 结果判断
## 1. 反向链特异性测序 fr-firststrand 【理解为 reverse forward 】

This is PairEnd Data
Fraction of reads failed to determine: 0.0176
Fraction of reads explained by "1++,1--,2+-,2-+": 0.0727
Fraction of reads explained by "1+-,1-+,2++,2--": 0.9097

## 2. 正向链特异性测序 fr-secondstrand 【理解为 forward reverse】 

This is PairEnd Data
Fraction of reads failed to determine: 0.0276
Fraction of reads explained by "1++,1--,2+-,2-+": 0.9611
Fraction of reads explained by "1+-,1-+,2++,2--": 0.0113
fr-secondstrand。"1++,1--,2+-,2-+"，意思就是read1在+链，相对的gene也同样在+链上，而read2在+链，相对的gene在-链上。

fr-firststrand。“1+-，1-+，2++，2--”这种，也就是read1在+链，相对的gene其实是在-链（reverse）。这种就是“fr-firststrand”，

1++: 这表示第一读序（read 1）的方向与参考基因组的正链方向相同。

1--: 这表示第一读序（read 1）的方向与参考基因组的负链方向相同。

2+-: 这表示第二读序（read 2）的方向与参考基因组的正链方向相反。

2-+: 这表示第二读序（read 2）的方向与参考基因组的负链方向相反

# 链特异性数据 软件参数设置
hisat2 链特异性参数
hisat2 
--rna-strandness FR  # 正向数据 fr-secondstrand  Ligation

--rna-strandness RF  # 反向数据 fr-firststrand dUTP
stringtie 链特异性参数
stringtie

--rf  # 反向数据 fr-firststrand dUTP
--fr  # 正向数据 fr-secondstrand Ligation


FeatureCounts
FeatureCounts

-s 2  # 反向数据 fr-firststrand dUTP
-s 1  # 正向数据 fr-secondstrand Ligation

HT-seq
--stranded reverse  # 反向数据 fr-firststrand dUTP
--stranded yes      # 正向数据 fr-secondstrand Ligation

TopHat
--library-type fr-firststrand  # 反向数据 fr-firststrand dUTP
--library-type fr-secondstrand # 正向数据 fr-secondstrand Ligation

STAR
自动检测，不需要

Kalisto quant
--rf-stranded  # 反向数据 fr-firststrand dUTP
--fr-stranded  # 正向数据 fr-secondstrand Ligation

RSEM
--forwar-prob 0 # 反向数据 fr-firststrand dUTP
--forwar-prob 1 # 正向数据 fr-secondstrand Ligation

Salmon
--libType ISR # 反向数据 fr-firststrand dUTP
--libType ISF # 正向数据 fr-secondstrand Ligation

Trinity
--SS_lib_type RF  # 反向数据 fr-firststrand dUTP
--SS_lib_type FR # 正向数据 fr-secondstrand Ligation
