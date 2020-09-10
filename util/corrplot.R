# plot a correlation heatmap between xCell and the second specified method
# only take common cell types between both methods

plot.corrplot <- function(methods, deconv.out.format, outputDir, width, height){
  
  # common cell types between both methods
  methods <- unlist(methods)
  res <- deconv.out.format %>%
    filter(method %in% methods) %>%
    select(c(cell_type, sample, fraction, method, molecular_subtype)) %>%
    spread(method, fraction)  %>%
    filter(complete.cases(.))
  
  # Overall correlation: 0.12
  cor_test <- cor.test(res[,methods[1]], res[,methods[2]], method = "pearson")
  avg.cor <- round(as.numeric(cor_test$estimate), 2)
  p.value <- format(cor_test$p.value, digits = 2, scientific = T)
  print(paste("Overall Pearson Correlation: ", avg.cor, "\n",
              "P-value: ", p.value))
  
  # labels
  total.labels <- res %>%
    select(molecular_subtype, sample) %>%
    unique() %>%
    group_by(molecular_subtype) %>%
    dplyr::summarise(label = n()) %>%
    mutate(label = paste0(molecular_subtype,' (',label,')'))
  
  # add labels to actual data
  total <- merge(res, total.labels, by = 'molecular_subtype')
  
  # calculate correlation per cell type per histology
  total <- total %>% 
    group_by(cell_type, label) %>%
    dplyr::summarise(corr = cor(!!sym(methods[1]), !!sym(methods[2]))) %>%
    spread(key = label, value = corr) %>% 
    column_to_rownames('cell_type') %>%
    replace(is.na(.), 0)
  
  # create correlation heatmap
  output <- file.path(outputDir, paste0(methods[1], "_", methods[2], "_corrplot", ".pdf"))
  win.asp = 0.5
  width = 13
  height = 8
  tl.cex = 0.8
  pdf(file = output, width = width, height = height)
  corrplot(t(total), method = "circle", type = 'full', win.asp = win.asp, 
           addCoef.col = "black", number.cex = .5,
           # is.corr = FALSE, 
           tl.cex = tl.cex, mar = c(0, 0, 0, 5), 
           title = paste0("\n\n\n\nCorrelation matrix (", 
                          methods[1], " vs ", methods[2], ")\n",
                          "Overall Pearson Correlation: ", avg.cor, "\n",
                          "P-value: ", p.value))
  dev.off()
}
