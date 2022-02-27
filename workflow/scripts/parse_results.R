library(xlsx)

input_bed=snakemake@params[["intervals"]]
input_file=snakemake@input[["tsv"]]
output_file=snakemake@output[["tsv"]]
output_file_xlsx=snakemake@output[["xlsx"]]


exons_bed=read.table(input_bed, sep = "\t")
names(exons_bed)= c("chr","start","end","transcript_id","gene_name","exon_number")

read_results=read.table(input_file, sep = "\t", header = T, comment.char = "^")
names(read_results)[names(read_results) == 'X.chrom'] <- "chr"

merged=merge(read_results, exons_bed, by=c("row.names","chr","start","end"))
rownames(merged)=merged$Row.names

sorted=merged[ order(as.numeric(row.names(merged))), ]
merged=sorted[,-c(1)]
names(merged)
names(merged)=c("chr","start","end","length","sample_name","gc_percent","min_coverage","max_coverage","average_coverage","median_coverage","bases_with_no_coverage","percent_covered","transcript_id","gene_name","exon_number")

write.table(merged,output_file, quote = F, sep = "\t",row.names = F)
write.xlsx2(merged,file = output_file_xlsx, sheetName = "coverage",row.names = F, col.names = T)
