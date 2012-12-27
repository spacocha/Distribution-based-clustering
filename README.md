Distribution-based-clustering
=============================
Created by Sarah Pacocha Preheim

Last modified: 12/27/2012

DESCRIPTION:

Extremely accurate algorithm used to group DNA sequences from microbial communities into operational taxonomic units (proxy for species) for ecological or biomedical research. This algorithm uses the information contained in the distribution of DNA sequences across samples along with sequence similarity to cluster sequences more accurately than other methods that are currently available. Developed for Illumina next-generation sequencing libraries, but applicable to any sequencing platform with sufficient number of counts per sample to infer distribution patterns. 

WHEN TO USE THIS PROGRAM:

This program should be used in conjunction with other sequence analysis packages (i.e. mothur, Qiime) to obtain the most accurate OTUs based on all of the information available in both the genetic and the distribution data.


REQUIREMENTS:

perl v5.8.8

R/2.12.1

REQUIRED INPUTS:

This program requires that raw sequencing data is pre-processed into two files

1.) Distance file of unique seqeunces

-The raw data must be combined into unique (non-redundant) sequences

-The distance must be calculated for all unique sequences and presented as a .dst file

-For large sequence files, such as those from Illumina or 454 pyrosequencing, FastTree is recommended

-Also, both aligned and unaligned distances can be entered use as inputs, reducing the error from misalignment.

2.) Community-by-sequence matrix

-This is a file containing a unique name for each non-redundant sequence and the number of counts for that seqeunce in each sampled community

-Communities are columns and OTUs are rows

-Lines beginning with "# " (hash followed by a space) are ignored


MAIN PROGRAM:

distribution_clustering.pl-
-This is the main program creating the distribution-based OTUs. To use this requires that R is accessible by calling R through the system command. If not, it will not run.
-To use type "perl distribution_clustering.pl" to get a complete list of requirements and options

ACCESSORY PROGRAMS:

Merge_parent_child.pl-
-Use this file to create a list (similar to the output of various clustering algorithms) where each line is one OTU with the unique ids of each non-redundant seqeunce identifier listed. The parent sequence is the first entry, with children (if applicable) list in tab delimited manner following the parent on each line.





