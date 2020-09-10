# function to create heatmap of average immune scores per histology per cell type
create.heatmap <- function(deconv.method, deconv.out.format, outputDir) {
  
  # subset to deconv.method
  res <- deconv.out.format %>%
    filter(method %in% deconv.method) 
  
  # create labels: count of samples per histology
  annot <- res %>%
    select(molecular_subtype, sample) %>%
    unique() %>%
    group_by(molecular_subtype) %>%
    summarise(label = n()) %>%
    mutate(label = paste0(molecular_subtype,' (',label,')'))
  
  # add labels to actual data
  res <- merge(res, annot, by = 'molecular_subtype')
  
  # calculate average scores per cell type per histology
  res <- res %>% 
    filter(!cell_type %in% c("microenvironment score", "stroma score", "immune score")) %>%
    group_by(cell_type, label) %>%
    summarise(mean = mean(fraction)) %>%
    # convert into matrix of cell type vs histology
    spread(key = label, value = mean) %>% 
    column_to_rownames('cell_type')
  
  # remove rows with all zeros (not allowed because we are scaling by row)
  res <- res[apply(res, 1, function(x) !all(x==0)),]
  
  # plot heatmap
  title <- paste0(deconv.method,"\nAverage immune scores normalized by rows")
  output <- file.path(outputDir, paste0(deconv.method, "_heatmap", ".pdf"))
  pdf(file = output, width = 13, height = 8)
  pheatmap(mat = t(res), fontsize = 10, 
           scale = "column", angle_col = 45,
           main = title, annotation_legend = T, cellwidth = 15, cellheight = 15)
  dev.off()
}