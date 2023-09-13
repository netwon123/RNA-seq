library(WGCNA)
library(reshape2)
library(stringr)
setwd('G:/')
enableWGCNAThreads(nThreads = 0.75*parallel::detectCores())
combat_edata_l=read.csv('df_rm.csv',header = T,row.names = 1,quote="", comment="", check.names=F)
m.vars=apply(combat_edata_l,1,var)
expro.upper=combat_edata_l[which(m.vars>quantile(m.vars, probs = seq(0, 1, 0.25))[2]),]

dim(expro.upper)
datExpr0=as.data.frame(t(expro.upper))
gsg = goodSamplesGenes(datExpr0, verbose = 3);
gsg$allOK


if (!gsg$allOK)
{
  # Optionally, print the gene and sample names that were removed:
  if (sum(!gsg$goodGenes)>0)
    printFlush(paste("Removing genes:", paste(names(datExpr0)[!
                                                                gsg$goodGenes], collapse = ", ")));
  if (sum(!gsg$goodSamples)>0)
    printFlush(paste("Removing samples:", paste(rownames(datExpr0)[!
                                                                     gsg$goodSamples], collapse = ", ")));
  # Remove the offending genes and samples from the data:
  datExpr0 = datExpr0[gsg$goodSamples, gsg$goodGenes]
}
dim(datExpr0)
datExpr=datExpr0


datTraits = read.csv('trait.csv',sep = ',',row.names=1,header=T)

load(file = "G-02-network.Rdata")
nGenes = ncol(datExpr);#定义基因和样本的数量量
nSamples = nrow(datExpr)


if(T){
  datTraits$group <- as.factor(datTraits$group)
  design <- model.matrix(~0+datTraits$group)
  colnames(design) <- levels(datTraits$group) #get the group
  MES0 <- moduleEigengenes(datExpr,moduleColors)$eigengenes  #Calculate module eigengenes.
  MEs <- orderMEs(MES0)  #Put close eigenvectors next to each other
  moduleTraitCor <- cor(MEs,design,use = "p")
  moduleTraitPvalue <- corPvalueStudent(moduleTraitCor,nSamples)
  textMatrix <- paste0(signif(moduleTraitCor,2),"\n(",
                       signif(moduleTraitPvalue,1),")")
  dim(textMatrix) <- dim(moduleTraitCor)
  
  pdf("step4_Module-trait-relationship_heatmap.pdf",
      width = 2*length(colnames(design)),
      height = 0.6*length(names(MEs)) )
  par(mar=c(5, 9, 3, 3)) #留白：下、左、上、右
  labeledHeatmap(Matrix = moduleTraitCor,
                 xLabels = colnames(design),
                 yLabels = names(MEs),
                 ySymbols = names(MEs),
                 colorLabels = F,
                 colors = blueWhiteRed(50),
                 textMatrix = textMatrix,
                 setStdMargins = F,
                 cex.text = 0.5,
                 zlim = c(-1,1),
                 main = "Module-trait relationships")
  dev.off()
  save(design, file = "step4_design.Rdata")
}
if(T){
  mes_group <- merge(MEs,datTraits,by='row.names')
  library(gplots)
  library(ggpubr)
  library(grid)
  library(gridExtra)
  draw_ggboxplot <- function(data,Module="Module",group="group"){
    ggboxplot(data,x=group, y=Module,
              ylab = paste0(Module),
              xlab = group,
              fill = group,
              palette = "jco",
              #add="jitter",
              legend = "") +stat_compare_means( label.x = 1.5)
  }
  # 批量画boxplot
  colorNames <- names(MEs)
  pdf("step4_Module-trait-relationship_boxplot.pdf", width = 7.5,height = 1.6*ncol(MEs))
  p <- lapply(colorNames,function(x) {draw_ggboxplot(mes_group, Module = x, group = "group")})
  do.call(grid.arrange,c(p,ncol=2)) #排布为每行2个
  dev.off()
}
#-----------------------------
levels(datTraits$group)
choose_group <- "Y1"  


if(T){
  modNames <- substring(names(MEs), 3)
  
  ### 计算模块与基因的相关性矩阵
  ## Module Membership: 模块内基因表达与模块特征值的相关性
  geneModuleMembership <- as.data.frame(cor(datExpr, MEs, use = "p"))
  MMPvalue <- as.data.frame(corPvalueStudent(as.matrix(geneModuleMembership), nSamples))
  names(geneModuleMembership) <- paste0("MM", modNames)
  names(MMPvalue) <- paste0("p.MM", modNames)
  
  ###  计算性状与基因的相关性矩阵
  ## Gene significance，GS：比较样本某个基因与对应表型的相关性
  ## 连续型性状
  # trait <- datTraits$groupNo  
  ## 非连续型性状，需转为0-1矩阵, 已存于design中
  trait <- as.data.frame(design[,choose_group])
  geneTraitSignificance <- as.data.frame(cor(datExpr,trait,use = "p"))
  GSPvalue <- as.data.frame(corPvalueStudent(as.matrix(geneTraitSignificance),nSamples))
  names(geneTraitSignificance) <- paste0("GS")
  names(GSPvalue) <- paste0("GS")
  
  ### 可视化基因与模块、表型的相关性.
  #selectModule<-c("blue","green","purple","grey")  ##可以选择自己想要的模块
  selectModule <- modNames  ## 全部模块批量作图
  pdf("step4_gene-Module-trait-significance-Y1.pdf",width=7, height=1.5*ncol(MEs))
  par(mfrow=c(ceiling(length(selectModule)/2),2)) #批量作图开始
  for(module in selectModule){
    column <- match(module,selectModule)
    print(module)
    moduleGenes <- moduleColors==module
    verboseScatterplot(abs(geneModuleMembership[moduleGenes, column]),
                       abs(geneTraitSignificance[moduleGenes, 1]),
                       xlab = paste("Module Membership in", module, "module"),
                       ylab = "Gene significance for trait",
                       main = paste("Module membership vs. gene significance\n"),
                       cex.main = 1.2, cex.lab = 1.2, cex.axis = 1.2, col = module)
  }
  dev.off()
}


#---------------------------------------------
### 模块相关性展示 Eigengene-adjacency-heatmap
if(T){
  MEs = moduleEigengenes(datExpr,moduleColors)$eigengenes
  MET = orderMEs(MEs)
  # 若添加表型数据
  if(T){
    ## 连续型性状
    MET = orderMEs(cbind(MEs,datTraits$groupN))
    ## 非连续型性状，需将是否属于这个表型进行0,1数值化，已存于design中
    design
    primed = as.data.frame(design[,6])
    names(primed) = "Y1"
    # Add the weight to existing module eigengenes
    MET = orderMEs(cbind(MEs, primed))
  }
  pdf("step5_module_cor_Eigengene-dendrogram-Y1.pdf",width = 8,height = 10)
  plotEigengeneNetworks(MET, setLabels="",
                        marDendro = c(0,4,1,4),  # 留白：下右上左
                        marHeatmap = c(5,5,1,2), # 留白：下右上左
                        cex.lab = 0.8,
                        xLabelsAngle = 90)
  dev.off()
}
#-----------------------------
module = "floralwhite"
if(T){
  dat=datExpr[,moduleColors==module]
  library(pheatmap)
  n=t(scale(dat)) #对基因做scale，并转置表达矩阵为行为基因、列为样本形式
  # n[n>2]=2
  # n[n< -2]= -2
  # n[1:4,1:4]
  
  group_list=datTraits$group
  ac=data.frame(g=group_list)
  rownames(ac)=colnames(n)
  
  pheatmap::pheatmap(n,
                     fontsize = 8,
                     show_colnames =T,
                     show_rownames = F,
                     cluster_cols = T,
                     annotation_col =ac,
                     width = 8,
                     height = 6,
                     angle_col=45,
                     main = paste0("module_",module,"-gene heatmap"),
                     filename = paste0("step7_module_",module,"_Gene-heatmap.pdf"))
  
}




#--------------------------------------------------------------------------------------
module = "blue"
if(T){
  ### 提取感兴趣模块基因名
  gene <- colnames(datExpr)
  inModule <- moduleColors==module
  modgene <- gene[inModule]
  
  ### 模块对应的基因关系矩阵
  TOM <- TOMsimilarityFromExpr(datExpr,power=16)
  modTOM <- TOM[inModule,inModule]
  dimnames(modTOM) <- list(modgene,modgene)
  
  ### 筛选连接度最大的top100基因
  nTop = 100
  IMConn = softConnectivity(datExpr[, modgene]) #计算连接度
  top = (rank(-IMConn) <= nTop) #选取连接度最大的top100
  filter_modTOM <- modTOM[top, top]
  


  # for cytoscape
  cyt <- exportNetworkToCytoscape(filter_modTOM,
                                  edgeFile = paste("step8_CytoscapeInput-edges-", paste(module, collapse="-"), ".txt", sep=""),
                                  nodeFile = paste("step8_CytoscapeInput-nodes-", paste(module, collapse="-"), ".txt", sep=""),
                                  weighted = TRUE,
                                  threshold = 0.15,  #weighted权重筛选阈值，可调整
                                  nodeNames = modgene[top],
                                  nodeAttr = moduleColors[inModule][top])
}
