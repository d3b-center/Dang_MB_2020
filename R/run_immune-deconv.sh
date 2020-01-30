# run mcp-counter 
Rscript R/immune-deconv.R -p data/pbta-gene-expression-rsem-fpkm-collapsed.polya.rds -s data/pbta-gene-expression-rsem-fpkm-collapsed.stranded.rds -c data/pbta-histologies.tsv -m mcp_counter -b NA -g NA -o results/deconv-output-mcpcounter.RData
Rscript R/summary.R -i results/deconv-output-mcpcounter.RData -o results/deconv-summary-mcpcounter.pdf

# run cibersort
Rscript R/immune-deconv.R -p data/pbta-gene-expression-rsem-fpkm-collapsed.polya.rds -s data/pbta-gene-expression-rsem-fpkm-collapsed.stranded.rds -c data/pbta-histologies.tsv -m cibersort_abs -b ~/Projects/OpenPBTA-analysis/analyses/immune-deconv/CIBERSORT.R -g ~/Projects/OpenPBTA-analysis/analyses/immune-deconv/LM22.txt -o results/deconv-output-cibersort.RData
Rscript R/summary.R -i results/deconv-output-cibersort.RData -o results/deconv-summary-cibersort.pdf
