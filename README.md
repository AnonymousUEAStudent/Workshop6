# Workshop6
This script runs through the workshop 6 exercises for the bioinformatics module, demonstrating genome wide association studies (GWAS). It includes both commentary on the commands used, and their output. It answers the questions posed in the workshop, and provides the code used to do so.

## Using the script:
First clone the repo in your chosen destination:
```
git clone https://github.com/AnonymousUEAStudent/Workshop6.git
``` 

The WS6.R script should then be opened in RStudio.

The repository includes all the required files in the correct locations for the script to be run without alteration if you have set your working directory to the Workshop6 directory in RStudio.
```
setwd("PathToWorkshop6Directory")
```
Once you have run the above to ensure your location is correct, the script can then be run sequentially.

## Expected output
The script will give answers to the questions posed in the workshop in addition to several ggplot2 graphs, in the plot window.
These plots have been saved and included in this repo. Though random permutation sampling is used in the script, a seed has been set to ensure that the graphs produced when re-run, should be identical, to avoid confusion in potential differences in analysis.
