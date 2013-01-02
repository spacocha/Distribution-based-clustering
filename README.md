Distribution-based-clustering
=============================
Created by Sarah Pacocha Preheim

DESCRIPTION:

Extremely accurate algorithm used to group DNA sequences from microbial communities into operational taxonomic units (proxy for species) for ecological or biomedical research. This algorithm uses the information contained in the distribution of DNA sequences across samples along with sequence similarity to cluster sequences more accurately than other methods that are currently available. Developed for Illumina next-generation sequencing libraries, but applicable to any sequencing platform with sufficient number of counts per sample to infer distribution patterns. 

WHEN TO USE THIS PROGRAM:

This program should be used in conjunction with other sequence analysis packages (i.e. mothur, Qiime) to obtain the most accurate operational taxonomic units (OTUs) based on all of the information available in both the genetic and the distribution data.


REQUIREMENTS:

perl (v5.8.8, other versions unverified)

R (2.12.1, others unverified)

REQUIRED INPUTS:

This program requires that raw sequencing data is pre-processed into two files

1.) Distance file of unique seqeunces

- The raw data must be combined into unique (non-redundant) sequences, which works very well when all sequences are processed to the same length.

- A pairwise distance matrix must be created for all unique sequences and presented as a .dst file.

- For large sequence files, such as those from Illumina or 454 pyrosequencing, FastTree is recommended.

- Also, both aligned and unaligned distances can be entered use as inputs, reducing the error from misalignment.

2.) Community-by-sequence matrix

- This is a file containing a unique name for each non-redundant sequence and the number of counts for that seqeunce in each sampled community

- Communities are columns and OTUs are rows

- Lines beginning with "# " (hash followed by a space) are ignored


MAIN PROGRAM:

distribution_clustering.pl

- This is the main program creating the distribution-based OTUs. To use this requires that R is accessible by calling R through the system command. If not, it will not run.

- To use type "perl distribution_clustering.pl" to get a complete list of requirements and options

ACCESSORY PROGRAMS:

Merge_parent_child.pl

- Use this file to create a list (similar to the output of various clustering algorithms) where each line is one OTU with the unique ids of each non-redundant seqeunce identifier listed. The parent sequence is the first entry, with children (if applicable) list in tab delimited manner following the parent on each line.

Matrix_from_list.pl

- Use this file to create a community-by-OTU matrix from the OTU list file

TEST DATA:

Files presented in the "test_data" directory can be used either as test data to ensure the programs are functioning properly, or as a template for appropriate input requirements.

- Raw data (raw_data.fastq and raw_data.group) are the inputs for the mothur "pre-processing" pipeline. Also required are the oligos.tab, required for filtering out primer/adapters from sequencing construct, and new_silva_short_unique_1_151.fa, a reference alignment trimmed to the size of the construct. The raw data is a subset of Illumina generated sequence data from a known input community. Only four input sequences were kept, along with a few errors generated during sequencing.

- Inputs for the distribution-based clustering program are raw_data.trim.unique.square.dist, a phylip formatted distance matrix of the unique sequences, and raw_data.trim.seq.count, a community-by-sequence matrix.

- The final file after processing the raw data with pre-processing (i.e. mothur), distribution-based clustering and post-processing is the community-by-OTU matrix, seq_error_only.err.list.mat or microdiversity.err.list.mat, depending on which parameters are used during clustering.

PRE_PROCESSING SEQUENCE DATA FROM RAW FASTQ:

Raw sequencing data can be generated in various ways. This will outline a simple method using mothur to process raw fastq data from Illumina for used with distribution-based clustering.

mothur commands as follows:

mothur > fastq.info(fastq=raw_data.fastq)
- This will generate raw_data.fasta and raw_data.qual

mothur > trim.seqs(fasta=raw_data.fasta, oligos=oligos.tab, qfile=raw_data.qual, qthreshold=48, minlength=76, maxhomop=10)
- This will generate raw_data.trim.fasta, with low quality sequences filtered out. All sequences will be the same length

mothur > unique.seqs(fasta=raw_data.trim.fasta)
- This will reduce redundant sequences and represent them as one "unique" sequences in raw_data.trim.unique.fasta

mothur > align.seqs(fasta=raw_data.trim.unique.fasta, reference=new_silva_short_unique_1_151.fa)
- align sequences to a referece alignment

mothur > dist.seqs(fasta=raw_data.trim.unique.align, cutoff=0.10, output=square)
- creates the phylip formatted distance matrix (raw_data.trim.unique.square.dist), used in distribution_clustering.pl

mothur > count.seqs(name=raw_data.trim.names, group=raw_data.group)
- creates a community-by-sequence count matrix (raw_data.trim.seq.count) to be used as input to distribution-clustering.pl


THE DISTRIBUTION-BASED CLUSTERING PROGRAM:

The pre-processing steps outlined above should provide all of the files needed as input for the distribution-based clustering program.

The four most abundant sequences are true input sequences. To clustering only seqeunces that represent errors use the following parameters:

perl ../distribution-clustering.pl -d raw_data.trim.unique.square.dist -m raw_data.trim.seq.count -R R_file_error -out seq_error_only.err -log LOG_error

Two of the true input sequences are distributed across samples in a similar manner (representing microdiversity). To clustering sequencing error and microdiversity, use the following paramenters:

perl ../distribution-clustering.pl -d raw_data.trim.unique.square.dist -m raw_data.trim.seq.count -R R_file_micro -out microdiversity.err -log LOG_micro -abund 0 -JS 0.02

POST-PROCESSING:

In order to make the error files into either a list or a community-by-OTU matrix, use the following perl programs on the output of the distribution-based clustering algorithm.

perl ../merge_parent_child.pl seq_error_only.err > seq_error_only.err.list

perl ../matrix_from_list.pl  raw_data.trim.seq.count seq_error_only.err.list > seq_error_only.err.list.mat

These files can be used with other programs (mothur, Qiime) for commonly performed community analysis.

RESULTS:

raw_data.trim.seq.count shows there are four unique sequences with more than 1000 counts across all libraries. These are the true input sequences. Unique sequences with less than 100 counts are errors generated during sequencing. There are two options. First, only sequencing error can be merged using the default parameters of the distribution based clustering. Alternatively, two of the true input sequences that are distributed in all three libraries equally could be merged, as these are closely related sequences (only differing by 1 bp). However, the other two true sequences are also only 1 bp different, but do not have the same distribution. This could be important information which should be retained. To cluster microdiveristy, use the alternative parameters presented above.
 
In seq_error_only.err.list.mat, there are four resulting OTUs, representing the four true input sequences. Unique sequences with less than 100 counts were merged with the parent sequences. In microdiversity.err.list.mat, there are three resulting OTUs. This represents two distinct unique sequences (HWI-EAS413_0071_FC:2:1:14612:9620#AGTAGAT/1 and HWI-EAS413_0071_FC:2:1:7014:1558#AGTAGAT/1) and one OTU with two merged true sequences because they are found in all libraries in a similar manner (HWI-EAS413_0071_FC:2:1:2111:1182#GTACGTT/1 and HWI-EAS413_0071_FC:2:1:7250:2720#GTACGTT/1). All sequencing error sequences were also grouped with the appropriate parents.