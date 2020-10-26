library(corrplot)
library(reshape2)

# quantitative traits
TRAIT_CATEGORY1 = c(
  'Anthropometric', 'Metabolic', 'Protein', 'Kidney-related', 'Electrolyte',
  'Liver-related', 'Other biochemical', 'Hematological', 'Blood pressure', 'Echocardiographic'
)

# diseases
TRAIT_CATEGORY2 = c(
  'Metabolic disease', 'Cardiovascular disease', 'Allergic disease', 'Autoimmune disease', 'Infectious disease',
  'Hematologic disease', 'Psychiatric disease', 'Musculoskeletal disease', 'Tumor', 'Other'
)

################################################################################
args = commandArgs(trailingOnly=T)
if (identical(args, character(0))) {
  args = paste0("./input_example/", c("input_rg.txt", "traitlist.txt"))
}
rg_fname = args[1]
traitlist_fname = args[2]


################################################################################
# load data
rg = read.table(rg_fname, T, sep='\t', as.is = T)
trait_all = read.table(traitlist_fname, T, sep = '\t', as.is = T, quote = '', fileEncoding='utf-8', comment.char="")

traitlist1 = subset(trait_all, CATEGORY %in% TRAIT_CATEGORY1)
traitlist2 = subset(trait_all, CATEGORY %in% TRAIT_CATEGORY2)

# duplicate lines
tmp = rg
tmp$p1 = rg$p2
tmp$p2 = rg$p1
tmp$p1_category = rg$p2_category
tmp$p2_category = rg$p1_category
rg = rbind(rg, tmp)

################################################################################

corrplot_nsquare = function(rg, trait1, trait2, traits_use = NULL, order = "original", landscape=FALSE) {
  if (landscape & length(trait1) > length(trait2)) {
    tmp = trait1
    trait1 = trait2
    trait2 = tmp
  }
  if (!is.null(traits_use)) {
    rg = subset(rg, p1 %in% traits_use & p2 %in% traits_use)
  }
  x2 = dcast(rg, p1 ~ p2, value.var = "rg")
  mat2 = as.matrix(x2[, 2:ncol(x2)])
  rownames(mat2) = x2$p1

  mat2[mat2 > 1] = 1
  mat2[mat2 < -1] = -1
  mat2[is.na(mat2)] = 0

  x2 = dcast(rg, p1 ~ p2, value.var = "q")
  qmat2 = as.matrix(x2[, 2:ncol(x2)])
  rownames(qmat2) = x2$p1
  qmat2[is.na(qmat2)] = 1

  if (nrow(mat2) == ncol(mat2)) {
    diag(mat2) = 1
    diag(qmat2) = -1
  }

  trait1 = match(trait1, rownames(mat2))
  trait2 = match(trait2, colnames(mat2))
  mat2 = mat2[trait1, trait2]
  qmat2 = qmat2[trait1, trait2]

  corrplot(mat2, method = "psquare", order = order,
           p.mat = qmat2, sig.level = 0.05, sig = "pch",
           pch = "*", pch.cex = 1.5, full_col=FALSE,
           na.label = "square", na.label.col = "grey30")
  # return(list(mat = mat2, qmat = qmat2))
}


cairo_pdf("./output/corrplot_rg_disease.pdf", width = 16, height = 9, family = "Helvetica")
  corrplot_nsquare(rg, traitlist1$TRAIT, traitlist2$TRAIT, landscape=TRUE)
dev.off()

png("./output/corrplot_rg_disease.png", width = 16, height = 9, units = 'in', res = 300, family = "Helvetica")
  corrplot_nsquare(rg, traitlist1$TRAIT, traitlist2$TRAIT, landscape=TRUE)
dev.off()


warnings()
