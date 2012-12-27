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

USAGE:

Requires the addition of the R module prior to running (i.e. module add R/2.12.1)

{} indicates required input (order unimportant)
[] indicates optional input (order unimportant)

This program is designed to identify sequencing errors and sequences that can not be distinguished from sequencing error in Illumina data.
It identifies sequencing error by looking for a parent for each sequence, starting with the most abundant across libraries in your matrx file.
Parents are sequences that satisfies the following:
1.) The parental abundance is above the defined the abundance threshold
2.) It is within a specific distance cut-off
3.) The parental distribution is not statistically significantly different from the child distribution as determined by fisher (when possible), or chi-sq test above the pvalue threshold

A child is assigned to the most similar (smallest distance) parental sequence that fulfills the above criteria.
Once assigned as a child, a sequence will not be considered as a parent.

Example usage:
perl find_seq_errors29.pl -d file.dst -m file.mat -R R_file -out output.err -log file.log

Options:

-d distance_file          A distance file, or list of distance files (i.e. aligned and unaligned) separated by commas

-m matrix_file            The distribition of this sequence (a.k.a. 100% identity cluster) across your libraries

-R R_output_prefix        The output prefix used for the R_files (requires R/2.12.1, make sure to add this module before running this program)

-out output.err           The output file name containing the a list of errors and to be parsed into a typical OTU file format by err2list.pl

-log LOGFILE              Name of the log file where some information will be logged

-old old_err_files        Old stats file or list of old stats files separates by commas. The program will resume where it left off from previous runs.

-dist DIST_CUTOFF         The distance cutoff that you would consider merging sequences to (default is 0.1)

-abund ABUND_CUTOFF       The abundance cutoff that a parent has to satisfy to be considered. 0 if you want to merge uninformative sequence diversity but take longer, 10 increases speed but detects many methodological errors (sequencing, PCR)

-pval PVALUE_CUTOFF       P-value cutoff above which OTUs will be merged. Default=0.0005 (do not go below 9.999E-05 or simulated pvalues will not work) Lower pvalues create fewer OTUs, higher pvalues create more OTUs.

-JS JS_CUTOFF             Use the Jensen-Shannon diistance to determine whether to merge values (default=off), especially when ABUND_CUTOFF = 0. Good JS_CUTOFF value around 0.2 (best to use when abundance thresh = 0). Will be applied after failing chi-sq test cut-off.

-verbose                  Print out verbose information about progress to log file. Useful in debugging.
