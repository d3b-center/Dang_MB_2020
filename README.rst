.. |date| date::

*************************
Mai Dang Medullo Analyses
*************************

Immune Deconvolution
====================

Description:
------------

* code/immune-deconv.R : Immune deconvolution using xCell, CIBERSORT (abs. mode), MCP-Counter.
* code/summary.R: Heatmap of average immune scores per cell type grouped by medullo subtypes.

Analysis:
---------

Run the full analysis using:

.. code-block:: bash

    bash run_immune-deconv.sh

Estimation of micoglia and monocyte relative cell proportion
=====================================================================

### Description:
We used [BRETIGEA](https://github.com/andymckenzie/BRETIGEA ) to find surrogate proportion variables (SPV) of brain cells astrocytes (ast), endothelial cells (end) , microglia (mic) , neurons (neu) , oligodendrocytes (oli) , and oligodendrocyte precursor cells (opc) , derived from each of human, mice, and combination human/mouse data sets.

In addition to that, we added monocyte marker genes from (PMID:30764877) “F10", "EMILIN2", "F5", "C3", "GDA", "MKI67", "SELL", "HP","FN1","ANXA2","CD24","S100A6","MGST1","SLPI" and monocyte marker genes from xCell (PMID: 29141660) to identify surrogate proportion variables that could be compared across samples. This is an *preliminary/hypothesis-generating* analysis and further tests on true cell proportions are needed for validation.

We ran function findCells() using SVD method to calculate SPVs and all 1000 marker genes for brain cell types provided in BRETIGEA package along with 317 genes for monocyte. All cell type SPVs were then plotted for each sample as stacked bar plots

`medullo_micro_mono.R`: runs BRETIGEA cell proportion estimation for all subtypes then plots for distribution of relative cell proportion of mococytes and microglia in each medulloblastoma subgroup

### Run
    bash run_bretigea.sh

### Plots
[Dropbox](https://www.dropbox.com/sh/hmycsb64ymcc3xm/AAC2PljTFXPTs2Z0GTr_bB-4a?dl=0)
