library(xlsx)

panel_bed=snakemake@params[["panel_intervals"]]
canonical_bed=snakemake@params[["canonical_intervals"]]
input_panel=snakemake@input[["panel"]]
input_canonical=snakemake@input[["canonical"]]
output_panel=snakemake@output[["panel"]]
output_canonical=snakemake@output[["canonical"]]
output_file_xlsx=snakemake@output[["xlsx"]]

######## LOAD BED FILES
panel_bed=read.table(panel_bed, sep = "\t")
exons_bed=read.table(canonical_bed, sep = "\t")
names(panel_bed)= c("chr","start","end","region_id")
names(exons_bed)= c("chr","start","end","gene_name","exon_number")

######## PANEL
panel_results=read.table(input_panel, sep = "\t", header = T, comment.char = "^")
names(panel_results)[names(panel_results) == 'X.chrom'] <- "chr"

merged=merge(panel_results, panel_bed, by=c("chr","start","end"))
names(merged)=c("chr","start","end","length","sample_name","gc_percent","min_coverage","max_coverage",
                "average_coverage","median_coverage","bases_with_no_coverage","percent_covered","region_id")

######## CANONICAL
canonical_results=read.table(input_canonical, sep = "\t", header = T, comment.char = "^")
names(canonical_results)[names(canonical_results) == 'X.chrom'] <- "chr"

canonical_merged=merge(canonical_results, exons_bed, by=c("chr","start","end"))
names(canonical_merged)=c("chr","start","end","length","sample_name","gc_percent","min_coverage","max_coverage",
                "average_coverage","median_coverage","bases_with_no_coverage","percent_covered","gene_name","exon_number")
canonical_merged=canonical_merged[,c(1,2,3,13,14,4,5,6,7,8,9,10,11,12)]


####### WRITE OUTPUT
write.table(merged,output_panel, quote = F, sep = "\t",row.names = F)
write.table(canonical_merged,output_canonical, quote = F, sep = "\t",row.names = F)

###
wb = createWorkbook()
sheet = createSheet(wb, "Panel_coverage")
cs3 <- CellStyle(wb) + Font(wb, isBold=TRUE) #+ Border()
addDataFrame(merged, sheet=sheet, startColumn=1, row.names=FALSE, colnamesStyle = cs3)
sheet = createSheet(wb, "Exons_coverage")
addDataFrame(canonical_merged, sheet=sheet, startColumn=1, row.names=FALSE, colnamesStyle = cs3)
saveWorkbook(wb, output_file_xlsx)
