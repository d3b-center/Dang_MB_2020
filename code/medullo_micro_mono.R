#install.packages("BRETIGEA")
library(BRETIGEA)
library(knitr) #only for visualization
library(readr)
library(dplyr)
library(reshape2)
library(tidyr)
library(ggplot2)
library(ggpubr)
library(tidyverse)
library(forcats)
library(RColorBrewer)

theme_Publication <- function(base_size=16, base_family="Helvetica") {
  library(grid)
  library(ggthemes)
  (theme_foundation(base_size=base_size, base_family=base_family)
    + theme(plot.title = element_text(face = "bold",
                                      size = rel(1.2), hjust = 0.5),
            text = element_text(family="Helvetica"),
            panel.background = element_rect(colour = NA),
            plot.background = element_rect(colour = NA),
            panel.border = element_rect(colour = NA),
            axis.title = element_text(face = "bold",size = rel(0.95)),
            axis.title.y = element_text(angle=90,vjust =2,size=rel(0.95)),
            axis.title.x = element_text(vjust = -0.2,size=rel(0.95)),
            axis.text = element_text(size=12,color="black",face="bold"), 
            axis.line = element_line(colour="black",size=0.7),
            axis.ticks = element_line(),
            panel.grid.major = element_line(colour="#f0f0f0"),
            panel.grid.minor = element_blank(),
            legend.key = element_rect(colour = NA),
            legend.position = "right",
            legend.direction = "vertical",
            legend.key.size= unit(0.8, "cm"),
            legend.margin = unit(0.9, "cm"),
            legend.title = element_text(face="italic"),
            plot.margin=unit(c(10,5,5,5),"mm"),
            strip.background=element_rect(colour="#f0f0f0",fill="#f0f0f0"),
            strip.text = element_text(face="bold")
    ))
  
}

# assumes to be in R folder of the Dang_MB_2020 repo

#expression v13 
exp_stranded<-readRDS("data/raw/pbta-gene-expression-rsem-fpkm-collapsed.stranded.rds")
exp_polya<-readRDS("data/raw/pbta-gene-expression-rsem-fpkm-collapsed.polya.rds")
# overlapping genes
overlapgenes<-rownames(exp_stranded[which(rownames(exp_stranded) %in% rownames(exp_polya)),])
exp<-cbind(exp_stranded[overlapgenes,],exp_polya[overlapgenes,])

#clinical v13
clinical_medullo <- read_tsv("data/raw/pbta_mb_subtypes.tsv")
# xcell monoctype marker cells
gene_marker<-read_tsv("data/raw/13059_2017_1349_MOESM3_ESM.txt") 
monocyte_marker<-gene_marker[grep("Monocyte",gene_marker$Celltype_Source_ID),] %>% dplyr::select(-c(`# of genes`,Celltype_Source_ID)) %>% as.data.frame() %>% t() 
monocyte_marker<-melt(monocyte_marker)
monocyte_marker<-unique(monocyte_marker$value)
monocyte_marker<-monocyte_marker[!is.na(monocyte_marker)]


#%>% filter(experimental_strategy=="RNA-Seq" & disease_type_new=="Medulloblastoma")
exp<-exp[,which(colnames(exp) %in% clinical_medullo$Kids_First_Biospecimen_ID)]

# add monocyte/macrophage marker genes https://actaneurocomms.biomedcentral.com/articles/10.1186/s40478-019-0665-y
# plus marker genes for monocyte from xcell https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5688663/bin/13059_2017_1349_MOESM3_ESM.xlsx
# markers_df_brain<-rbind(markers_df_brain,data.frame("markers"=c("F10", "EMILIN2", "F5", "C3", "GDA", "MKI67", "SELL", "HP","FN1","ANXA2","CD24","S100A6","MGST1","SLPI"),"cell"=rep("mon",14)))

markers_df_brain<-rbind(markers_df_brain,data.frame("markers"=c("F10", "EMILIN2", "F5", "C3", "GDA", "MKI67", "SELL", "HP","FN1","ANXA2","CD24","S100A6","MGST1","SLPI",monocyte_marker),"cell"=rep("mon",317)))


# cell type proportions use all 1000 marker genes from mic and 317 from monocyte
cell_type_proportions = findCells(exp,markers = markers_df_brain, nMarker = 1000,method = "SVD")
cell_type_proportions<-melt(cell_type_proportions)

# add subtypes
cell_type_proportions<-cell_type_proportions %>% left_join(clinical_medullo ,by=c("Var1"="Kids_First_Biospecimen_ID"))
write.table(cell_type_proportions,"data/analyzed/cell_proportions.tsv",sep="\t",quote = FALSE,row.names = FALSE)

# select mic mon
cell_type_proportions_micro_mono<-cell_type_proportions[which(cell_type_proportions$Var2 %in% c("mic","mon")),]
# rename "Recurrence","Progressive" to Recurrence/Progressive
cell_type_proportions_micro_mono$tumor_descriptor[which(cell_type_proportions_micro_mono$tumor_descriptor %in% c("Recurrence","Progressive"))]<-"Progressive/Recurrence"
# remove Unavailable
cell_type_proportions_micro_mono<-cell_type_proportions_micro_mono[-which(cell_type_proportions_micro_mono$tumor_descriptor=="Unavailable"),]

# count
count<-table(cell_type_proportions_micro_mono[,c("molecular_subtype","tumor_descriptor")]) %>% as.data.frame()
count<-count[which(count$Freq>=6),]

# keep only types which have more than 6 counts
cell_type_proportions_micro_mono_prog<-cell_type_proportions_micro_mono %>%
  filter(tumor_descriptor =="Progressive/Recurrence" &
           molecular_subtype %in% count[which(count$Freq>=6 & count$tumor_descriptor=="Progressive/Recurrence"),"molecular_subtype"])

cell_type_proportions_micro_mono_init<-cell_type_proportions_micro_mono %>%
  filter(tumor_descriptor =="Initial CNS Tumor" &
           molecular_subtype %in% count[which(count$Freq>=6 & count$tumor_descriptor=="Initial CNS Tumor"),"molecular_subtype"])

cell_type_proportions_micro_mono<-rbind(cell_type_proportions_micro_mono_init,cell_type_proportions_micro_mono_prog)

# microglia and monocyte cell proportions in initial tumor CNS
pdf("plots/medullo_micro_mono_init_cells.pdf",width = 12,height = 10)
ggplot(cell_type_proportions_micro_mono_init,aes(x=Var2,y=value))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+geom_point(aes(color=tumor_descriptor,shape=tumor_descriptor), size=1,position = position_jitterdodge())+ylim(-0.5,0.5)+ scale_fill_brewer(palette = "Set2")
dev.off()

tiff("plots/medullo_micro_mono_init_cells.tiff",width = 2000,height = 1600,res=150)
ggplot(cell_type_proportions_micro_mono_init,aes(x=Var2,y=value))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+geom_point(aes(color=tumor_descriptor,shape=tumor_descriptor), size=1,position = position_jitterdodge())+ylim(-0.5,0.5)+ scale_fill_brewer(palette = "Set2")
dev.off()

# black and white
pdf("plots/medullo_micro_mono_init_cells_bw.pdf",width = 12,height = 10)
ggplot(cell_type_proportions_micro_mono_init,aes(x=Var2,y=value))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+scale_fill_grey()+geom_point(aes(shape=tumor_descriptor),size=1 ,position = position_jitterdodge())+ylim(-0.5,0.5)
dev.off()

tiff("plots/medullo_micro_mono_init_cells_bw.tiff",width = 2000,height = 1600,res=150)
ggplot(cell_type_proportions_micro_mono_init,aes(x=Var2,y=value))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+scale_fill_grey()+geom_point(aes(shape=tumor_descriptor),size=1 ,position = position_jitterdodge())+ylim(-0.5,0.5)
dev.off()

# microglia and monocyte cell proportions in subtypes with enough recurrent/progressive and initial tumor CNS
subtypes_with_prog<-unique(cell_type_proportions_micro_mono_prog$molecular_subtype)

# merge init and prog samples from molecular_subtypes in subtypes_with_prog
cell_type_proportions_micro_mono_prog<-rbind(cell_type_proportions_micro_mono_prog,cell_type_proportions_micro_mono_init %>% filter(molecular_subtype %in% subtypes_with_prog))

pdf("plots/medullo_micro_mono_init_prog_cells.pdf",width = 20,height = 24)
ggplot(cell_type_proportions_micro_mono_prog,aes(x=Var2,y=value,shape=tumor_descriptor))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype,ncol = 1)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS and  (>=6) progressive CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+geom_point(aes(color=tumor_descriptor),size=3 ,position = position_jitterdodge())+ylim(-0.5,0.5)+theme(legend.position = "bottom")
dev.off()

tiff("plots/medullo_micro_mono_init_prog_cells.tiff",width = 3000,height = 3000,res=200)
ggplot(cell_type_proportions_micro_mono_prog,aes(x=Var2,y=value,shape=tumor_descriptor))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype,ncol = 1)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS and  (>=6) progressive CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+geom_point(aes(color=tumor_descriptor),size=3 ,position = position_jitterdodge())+ylim(-0.5,0.5)
dev.off()

# black and white
pdf("plots/medullo_micro_mono_init_prog_cells_bw.pdf",width = 20,height = 24)
ggplot(cell_type_proportions_micro_mono_prog,aes(x=Var2,y=value,shape=tumor_descriptor))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype,ncol = 1)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS and  (>=6) progressive CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+scale_fill_grey()+geom_point( size=3,position = position_jitterdodge(),color="black")+ylim(-0.5,0.5)+theme(legend.position = "bottom")
dev.off()

tiff("plots/medullo_micro_mono_init_prog_cells_bw.tiff",width = 3000,height = 3000,res=200)
ggplot(cell_type_proportions_micro_mono_prog,aes(x=Var2,y=value,shape=tumor_descriptor))+geom_violin(alpha=0.65)+stat_compare_means(size=6)+facet_wrap(~molecular_subtype,ncol = 1)+xlab("cell type")+ylab("Surrogate proportion variables (SPV)")+theme_Publication()+ggtitle("Cell proportion of microglia and monocyte in initial tumor CNS and  (>=6) progressive CNS")+ scale_x_discrete(labels= c("Microglia","Monocytes"))+scale_fill_grey()+geom_point( size=3,position = position_jitterdodge(),color="black")+ylim(-0.5,0.5)
dev.off()




# all brain cells in BRETIGA compared for all subtypes
# group by mb_classifier_prediction and arrange by value
cell_type_proportions<-cell_type_proportions %>% group_by(molecular_subtype) %>% arrange(desc(value))
cell_type_proportions$tumor_descriptor[which(cell_type_proportions$tumor_descriptor %in% c("Recurrence","Progressive"))]<-"Progressive/Recurrence"

cell_type_proportions_init<-cell_type_proportions %>% filter(tumor_descriptor =="Initial CNS Tumor")
cell_type_proportions_prog<-cell_type_proportions %>% filter(tumor_descriptor =="Progressive/Recurrence")  
  

Group3 <- ggplot(cell_type_proportions
                 [which(cell_type_proportions$molecular_subtype=="Group3"),],
                 aes(x=Var1,y=value,fill=fct_reorder(Var2,value,.desc=TRUE)))+
  geom_bar(stat = "identity")+xlab("Sample")+
  ylab("Surrogate proportion variables (SPV)")+theme_Publication()+
  theme(axis.text.x = element_text(size=12,color="black",face="bold",angle = 90))+
  guides(fill=guide_legend(title="cell types"))+ scale_fill_brewer(palette = "Set2")+
  scale_y_continuous(limits = c(-0.4,1)) +
  facet_wrap(~molecular_subtype)

Group4 <- ggplot(cell_type_proportions
                 [which(cell_type_proportions$molecular_subtype=="Group4"),],
                 aes(x=Var1,y=value,fill=fct_reorder(Var2,value,.desc=TRUE)))+
  geom_bar(stat = "identity")+xlab("Sample")+
  ylab("Surrogate proportion variables (SPV)")+theme_Publication()+
  theme(axis.text.x = element_text(size=12,color="black",face="bold",angle = 90))+
  guides(fill=guide_legend(title="cell types"))+ scale_fill_brewer(palette = "Set2")+
  scale_y_continuous(limits = c(-0.4,1)) +
  facet_wrap(~molecular_subtype)

SHH <- ggplot(cell_type_proportions
              [which(cell_type_proportions$molecular_subtype=="SHH"),],
              aes(x=Var1,y=value,fill=fct_reorder(Var2,value,.desc=TRUE)))+
  geom_bar(stat = "identity")+xlab("Sample")+
  ylab("Surrogate proportion variables (SPV)")+theme_Publication()+
  theme(axis.text.x = element_text(size=12,color="black",face="bold",angle = 90))+
  guides(fill=guide_legend(title="cell types"))+ scale_fill_brewer(palette = "Set2")+
  scale_y_continuous(limits = c(-0.4,1)) +
  facet_wrap(~molecular_subtype)

WNT <- ggplot(cell_type_proportions
              [which(cell_type_proportions$molecular_subtype=="WNT"),],
              aes(x=Var1,y=value,fill=fct_reorder(Var2,value,.desc=TRUE)))+
  geom_bar(stat = "identity")+xlab("Sample")+
  ylab("Surrogate proportion variables (SPV)")+theme_Publication()+
  theme(axis.text.x = element_text(size=12,color="black",face="bold",angle = 90))+
  guides(fill=guide_legend(title="cell types"))+ scale_fill_brewer(palette = "Set2")+
  scale_y_continuous(limits = c(-0.4,1))+
  facet_wrap(~molecular_subtype)
  
ggarrange(Group3,Group4,SHH,WNT,nrow = 1,widths = c(1,2,1.25,0.6),common.legend = TRUE,legend = "left") +ggsave("plots/medullo_all_brain_cells.pdf",width = 25,height = 10,units = "in")

ggarrange(Group3,Group4,SHH,WNT,nrow = 1,widths = c(1,2,1.25,0.6),common.legend = TRUE,legend = "left") +ggsave("plots/medullo_all_brain_cells.tiff",width = 25,height = 10,units = "in")


write.table(markers_df_brain,"data/analyzed/marker_df_brain.tsv",sep="\t",quote = FALSE,row.names = FALSE)

