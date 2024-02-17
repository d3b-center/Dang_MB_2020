.. |date| date::

*************************
Macrophages in SHH subgroup medulloblastoma display dynamic heterogeneity that varies with treatment modality
*************************
Mai T Dang, Michael V Gonzalez, Krutika S Gaonkar, Komal S Rathi, Patricia Young, Sherjeel Arif, Li Zhai, Zahidul Alam, Samir Devalaraja, Tsun Ki Jerrick To, Ian W Folkert, Pichai Raman, Jo Lynne Rokita, Daniel Martinez, Jaclyn N Taroni, Joshua A Shapiro, Casey S Greene, Candace Savonen, Fernanda Mafra, Hakon Hakonarson, Tom Curran, Malay Haldar

This study is now published in [Cell Reports](https://pubmed.ncbi.nlm.nih.gov/33789113/).

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

Description:
------------

We used BRETIGEA https://github.com/andymckenzie/BRETIGEA to find surrogate proportion variables (SPV) of brain cells (derived from each of human, mice, and combination human/mouse data sets)
- astrocytes (ast)
- endothelial cells (end)
- microglia (mic)
- neurons (neu)
- oligodendrocytes (oli)
- and oligodendrocyte precursor cells (opc) 

In addition to that, we added monocyte marker genes from (PMID:30764877) “F10", "EMILIN2", "F5", "C3", "GDA", "MKI67", "SELL", "HP","FN1","ANXA2","CD24","S100A6","MGST1","SLPI" and monocyte marker genes from xCell (PMID: 29141660) to identify surrogate proportion variables that could be compared across samples. This is an *preliminary/hypothesis-generating* analysis and further tests on true cell proportions are needed for validation.

We ran function findCells() using SVD method to calculate SPVs and all 1000 marker genes for brain cell types provided in BRETIGEA package along with 317 genes for monocyte. All cell type SPVs were then plotted for each sample as stacked bar plots

`medullo_micro_mono.R`: runs BRETIGEA cell proportion estimation for all subtypes then plots for distribution of relative cell proportion of mococytes and microglia in each medulloblastoma subgroup

Analysis:
---------

Run the full analysis using:

.. code-block:: bash

    bash run_bretigea.sh

Plots:
-----
https://www.dropbox.com/sh/hmycsb64ymcc3xm/AAC2PljTFXPTs2Z0GTr_bB-4a?dl=0
