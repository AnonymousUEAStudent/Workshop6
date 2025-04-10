# Student Number: 100499009

# This script runs through the workshop 6 exercises for the bioinformatics module, demonstrating genome wide association studies (GWAS).
# It includes both commentary on the commands used, and their output.
# It answers the questions posed in the workshop, and provides the code used to do so.
# For this to be fully reproducible, it requires access to the files provided at the following location on blackboard:
# https://learn.uea.ac.uk/bbcswebdav/pid-5018682-dt-content-rid-35042969_1/xid-35042969_1
# These files should be located in the relative file path of "./GWAS_data/GWAS_data/"
# The .txt extension should be omitted to run the R script in R Studio.
# For full reproducibility the following public github repository is available: 
# https://github.com/AnonymousUEAStudent/Workshop6



# Associating genotypes with phenotypes
  
# Setup, load library for tidyverse and import the tab separated data as dataframes
library('tidyverse')
genotypes <- read_tsv("GWAS_data/GWAS_data/Chr12_Genotypes.tsv")
map <- read_tsv("GWAS_data/GWAS_data/Chr12_Map.tsv")
phenotypes <- read_tsv("GWAS_data/GWAS_data/Phenotype_Height.tsv")


# The following provides an overview of the data loaded:
colnames(genotypes)
# Shows all the column names, which are all the sample IDs
nrow(genotypes)
# The number of rows is 1280
ncol(genotypes)
# The number of columns is 504
head(genotypes)
# Shows the first 6 rows of the data
# A list of genotypes 0/2 for each sample ID. Columns are samples, rows are the genotype


colnames(phenotypes)
# Shows all the column names, in this case just Sample_Name and Height
nrow(phenotypes)
# The number of rows is 504
ncol(phenotypes)
# The number of columns is 2
head(phenotypes)
# Shows the first 6 rows of the data
# A list of phenotypes of height, each row contains a sample ID and height.


colnames(map)
#Shows all the column names: "Chromosome", "Position", "Allele0", and "Allele2"
nrow(map)
# The number of rows is 1280
ncol(map)
# The number of columns is 4
head(map)
# Shows the first 6 rows of the data
# A map of chromosome (12), which states which chromosome, the position on the chromosome, and the base at allele 0/2



# Creating a histogram of the phenotype wheat height for all of the samples
# The following makes a simple histogram plot of the positions seen in the dataset

ggplot(map, aes(x=Position)) +
  geom_histogram()
# This shows the sites are not evenly distributed across chromosome 12, with higher frequencies and the start and end positions.


# Pick a locus: What is the allele frequency?
# Select all columns for locus 2: chr12:474102
locus_2 <- genotypes[2,]
# This makes a table of the allele frequencies for locus 2
one_geno <- as.numeric(locus_2)
# We then convert it to a vector of numeric values

# Get the allele frequency for one loci
mean_locus_2 <- mean(one_geno, na.rm=TRUE)
# This gives a value of 1.56, which shows there are more 2 alleles than 0 alleles.
table(one_geno)
# The above line confirms this showing: 0 with 103 instances and 2 with 358 instances.

# Now we can get the allele_frequencies for all loci, by applying one function across the entire genotype dataframe
# In this case we are applying this to the genotype dataframe, to the rows (1), using the mean function, and using the argument na.rm=TRUE
allele_frequencies <- apply(genotypes, 1, mean, na.rm=TRUE)/2

# Make a table of the frequencies
plot_data <- tibble(allele_frequencies)


# We now make a histogram of allele frequencies, altering binwidth to give a more granular view
ggplot(plot_data, aes(x=allele_frequencies)) +
  geom_histogram(binwidth = 0.02)

# Add a new column to the phenotypes column, which adds the locus genotype for each sample
phenotypes$locus_2 <- as.numeric(one_geno)

# Using the addition of the locus data, we can now make a scatter plot of the height of crops, showing the difference between the allele type.
ggplot(data = phenotypes, aes(x = locus_2, y = Height)) +
  geom_jitter(width = 0.2) +
  geom_smooth(method = 'lm')
# Note that we have added geom_jitter specifically for width.
# This allows visibility of the multiple points that would otherwise overlap at either 0 or 2 on the x-axis.  
# In this particular locus, there is no noticeable difference between the two groups.

# Getting an the p-value for one locus(2) of the chromosome
corTestResult  <-  cor.test(phenotypes$Height, phenotypes$locus_2)
corTestResult$p.value
# This gives us a value of 0.520511: confirming the difference is not statistically significant as the p-value is greater than 0.05.


# We can expand our exploration by performing the same testing for all loci

# First we make a function that will get the p-value for a single row
association_test <- function(geno, pheno){
  one_geno <- as.numeric(geno)
  corTestResult  <-  cor.test(pheno, one_geno)
  corTestResult$p.value
}

# Then apply the function for every row of the genotype dataframe. Adding the values to the map dataframe
map$p_values <- apply(genotypes, 1, association_test , pheno=phenotypes$Height)


# Now make a plot of minus logged p-value versus position on the chromosome
# Include a line to show p-value threshold for statistically significant points
# This will be -log10 of 0.05 for this plot, as the p value is the -log10(p-value)
ggplot(map, aes(x=Position, y=-log10(p_values))) +
  geom_point() +
  geom_hline(aes(yintercept=-log10(0.05)), colour="red")
# At this point, this plot starts to identify which positions show significant changes in height based on the allele present.
# However, because there are so many locations, simply using a flat p-value of 0.05 is not sufficient. 

# To correct for potential false positives, across the large number of loci evaluated on the chromosome. We will do a Bonferroni correction.
# Get the number of tests performed:
m <- nrow(genotypes)

# Corrected Bonferroni threshold:
bonferroni_threshold <- 0.05/m

# Replot the p-values with Bonferroni threshold added:
ggplot(map, aes(x=Position, y=-log10(p_values))) +
  geom_point() +
  geom_hline(aes(yintercept=-log10(0.05)), colour="red") +
  geom_hline(aes(yintercept=-log10(bonferroni_threshold)), colour="blue")
# This second plot now shows a second much more stringent threshold for significant loci, in blue.

# Alternatively, instead of performing a Bonferroni correction, we can perform permutation tests to find the top 5% most extreme values.
# This can then be used as a threshold for significance.

# Setting up permutation testing to randomise the association between genotype and phenotype and assess if there are any significant results
get_p_values<-function(genos, pheno){
  apply(genos, 1, association_test, pheno)
}

# As permutations use random sampling, we can set a seed to make this reproducible. The same sampling should therefore occur.
# This should give consistent graphs between my output and any subsequent runs.
set.seed(42)

# Get our height samples
heights_perm <- sample(phenotypes$Height)

pvalue_perm1 <- get_p_values(genotypes, heights_perm)
map$pvalue_perm1 <- pvalue_perm1


# Example plot for a random permutation test giving p-values for random genotype/phenotype associations
ggplot(map, aes(x=Position, y=-log10(pvalue_perm1))) +
  geom_point() +
  geom_hline(aes(yintercept=-log10(0.05)), colour="red") +
  geom_hline(aes(yintercept=-log10(bonferroni_threshold)), colour="blue")

# Shows that many points exceed the p-value threshold, but not the Bonferroni adjusted p-value 

# Set up 100 permutation tests: 100 random reordering of the phenotype heights
perms <- replicate(100, sample(phenotypes$Height))


# Run the permutations 100 times to get 100 p-values for each loci
p_values_perms <- apply(perms, 2, get_p_values, genos=genotypes)
min_values <- apply(p_values_perms, 2, min)

# Sort the minimum values and find the 5% threshold (5th lowest value for 100 perms)
sorted_min_values <- sort(min_values)
# Lowest 5% of values
lowest_5 <- sorted_min_values[5]
# This gives the following value as a threshold: 9.495892e-05
# Repeating lines 153-181 should give the same value as the seed has been set.

# Plotting our real data with all three thresholds shown. Both the Bonferroni and permutation thresholds are relatively similar.

ggplot(map, aes(x=Position, y=-log10(p_values))) +
  geom_point() +
  geom_hline(aes(yintercept=-log10(0.05)), colour="red") +
  geom_hline(aes(yintercept=-log10(bonferroni_threshold)), colour="blue") +
  geom_hline(aes(yintercept=-log10(lowest_5)), colour="green", linetype= "dashed")


# The gene at the highest point is a dwarfism gene for wheat. 
# As recombination is more likely to occur with the closest loci, the nearby loci also have associations with height dwarfism in wheat.
# This explains the high peak at one loci, with many statistically significant heights shown in the surrounding loci also.


# For reproducibility as stated in the description there is a repository on github, the readme for which is included below:
# Available at https://github.com/AnonymousUEAStudent/Workshop6


## Using the script:
# First clone the repo in your chosen destination:
#   ```
# git clone https://github.com/AnonymousUEAStudent/Workshop6.git
# ``` 
# 
# The WS6.R script should then be opened in RStudio.
# 
# The repository includes all the required files in the correct locations for the script to be run without alteration if you have set your working directory to the Workshop6 directory in RStudio.
# ```
# setwd("PathToWorkshop6Directory")
# ```
# Once you have run the above to ensure your location is correct, the script can then be run sequentially.
# 
# ## Expected output
# The script will give answers to the questions posed in the workshop in addition to several ggplot2 graphs, in the plot window.
# These plots have been saved and included in this repo. Though random permutation sampling is used in the script, a seed has been set to ensure that the graphs produced when re-run, should be identical, to avoid confusion in potential differences in analysis.


