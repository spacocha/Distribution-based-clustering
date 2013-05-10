Distribution-based-clustering
=============================
Created by Sarah Pacocha Preheim

DESCRIPTION:

Extremely accurate algorithm used to group DNA sequences from microbial communities into operational taxonomic units (proxy for species) for ecological or biomedical research. This algorithm uses the information contained in the distribution of DNA sequences across samples along with sequence similarity to cluster sequences more accurately than other methods that are currently available. Developed for Illumina next-generation sequencing libraries, but applicable to any sequencing platform with sufficient number of counts per sample to infer distribution patterns. 

WHEN TO USE THIS PROGRAM:

This program should be used with the scripts provided or in conjunction with other sequence analysis packages (i.e. mothur, Qiime) to obtain the operational taxonomic units (OTUs) that most accurately reflect the ecology of the input sequences they represent. This method does not cluster by distance alone, but instead using a combination to distance and distribution to inform the clustering. Thus, it is different from other methods in that it does not attempt to cluster by trying to use the rule-of-thumb genetic cut-off of 97% to estimate total species.


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

RUNNING DISTRIBUTION-BASED CLUSTERING IN PARALLEL:

Commonly, this program will be run in parallel on datasets that are fairly large. This section provides a quick-start guide to help you accomplish parallel clustering beginning from data that is de-replicated and has an associated sequence by library count matrix associated with it. For further information about how to get to this point, see "PRE_PROCESSING SEQUENCE DATA FROM RAW FASTQ" below.

1.) Progressively cluster data using ProgressiveClustering.csh. variables_file contains many of the variables needed by various programs. The comments are meant walk you through what you need to input. Check the test_data for examples of each file.

    ProgressiveClustering5.csh ./variables_file

2.) Create the files for processing in parallel using the output of the ProgressiveClustering.csh

    perl create_parallel_files.pl unique_final.list unique.fa unique.f0.mat parallel_output

This will create one fasta and one sequence by library matrix file for each line of the unique_final.list. These can be used in parallel to process the data

3.) [Parallel] Align sequences to a reference and create the distance matrix. Then use these as input to the distribution_clustering.pl. This is contained in eOTU_parallel.csh.

    mothur "#align.seqs(fasta=parallel_output.1.fa, reference=new_silva_short_unique_1_151.fa)"
    
    FastTree -nt -makematrix parallel_output.1.align > parallel_output.1.align.dst

    FastTree -nt -makematrix parallel_output.1.fa > parallel_output.1.unalign.dst

    perl distribution_clustering.pl -m parallel_output.1.mat -d parallel_output.1.align.dst,parallel_output.1.unalign.dst -out parallel_output.1.process

4.) Evaluate whether all parallel processes completed.

    perl evaluate_parallel_results.pl ./variables_file eval_output

5.) Re-run failed jobs by using the -old flag in distribution_clustering.pl for each failed process. This will continue where the program left off.

6.) Make the final files. This involves creating a list from error files, a mat file from the list, and a fasta from the mat. (You can use clean_up_parallel_ultra.csh to remove OTUs that do not match the full length of the 16S region and chimeric sequences or do this seperately)

    clean_up_parallel.csh ./variables_file


MAIN PROGRAM:

distribution_clustering.pl

- This is the main program creating the distribution-based OTUs. To use this requires that R is accessible by calling R through the system command. If not, it will not run.

- To use type "perl distribution_clustering.pl" to get a complete list of requirements and options

REQUIRED ACCESSORY PROGRAMS:

Evaluate_parallel_results.pl

- Use this program when running the data in parallel

Merge_parent_child.pl

- Use this file to create a list (similar to the output of various clustering algorithms) where each line is one OTU with the unique ids of each non-redundant seqeunce identifier listed. The parent sequence is the first entry, with children (if applicable) list in tab delimited manner following the parent on each line. The input of this program is the output of the distribution_clustering.pl program.

Matrix_from_list.pl

- Use this file to create a community-by-OTU matrix from the OTU list file and a sequence by library matrix (i.e. one of the input files for distribution_clustering.pl)

fasta2filter_from_mat.pl

- Use this file to filter a full fasta file to only the representative sequences.


TEST DATA:

Files presented in the "test_data" directory can be used either as test data to ensure the programs are functioning properly, or as a template for appropriate input requirements.

- raw_data.fastq is the raw data, a common starting point for most users. The raw data is a subset of Illumina generated sequence data from a known input community. Only four input sequences were kept, along with a few errors generated during sequencing.

- test_data.mapping is the mapping file for QIIME or test_data.mothur.mapping for mothur

- oligos.tab is required for filtering out primer/adapters from sequencing construct if not using mothur to de-multiples

- new_silva_short_unique_1_151.fa is a reference alignment trimmed to the size of the construct. 

PRE_PROCESSING SEQUENCE DATA FROM RAW FASTQ:

Raw sequencing data can be generated in various ways. This will outline a simple method using mothur to process raw fastq data from Illumina for used with distribution-based clustering.

OUR PIPELINE

You can use our pipeline to process fastq data. 

    1.) Create a trimmed, quality filtered file, formatted in the QIIME split_libraries_fastq.py format. The library name is the first entry in the header field, followed by "__ and a unique id (e.g. lib1_1 ) followed by a space with the header name from the fastq file (e.g. ">lib1_1 MISEQ578:1:1101:15644:2126#AATGTCAA/1 orig_bc=TTGACATT new_bc=TTGACATT bc_diffs=0"). Library names can not have any spaces, and as a general rule, it is safe to only include "." as the only non-alpha numeric characters. We generate these files with the following commands from a fastq file in the format ./test_data/raw_data.fastq

    RunQiime_rawdata.csh ./all_variables
    
    2.) Progressively cluster sequences with UCLUST into 90% identity clusters. The results of this will be a list of sequences within 90% identity clusters, and the full fasta and sequence by library matrix used for downstream analysis.

    ProgressiveClustering5.csh ./all_varables
    

    3.) Create the files to run in parallel

    create_parallel_files.pl unique.PC.final.list unique.fa unique.f0.mat unique process.f0

    4.) Run all of the processes in parallel. This is an example of how it would be run on SGE

    qsub -cwd -t 1-100 eOTU_parallel.csh ./all_variables

    5.) Evaluate the process

    perl evaluate_parallel_results.pl ./all_variables eval_output

    6.) If all processes finished, clean them up

    clean_up_parallel_ultra.csh ./all_variables


MOTHUR-COMPLETE (not parallel)
You can use method to process the files, but this will likely have to be one round.
Do not attempt with more than 10 million reads (likely needs fewer)
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

    perl ../distribution_clustering.pl -d raw_data.trim.unique.square.dist -m raw_data.trim.seq.count -out seq_error_only

Two of the true input sequences are distributed across samples in a similar manner (representing microdiversity). To clustering sequencing error and microdiversity, use the following paramenters:

    perl ../distribution_clustering.pl -d raw_data.trim.unique.square.dist -m raw_data.trim.seq.count -out microdiversity -abund 0 -JS 0.02

POST-PROCESSING:

In order to make the error files into either a list or a community-by-OTU matrix, use the following perl programs on the output of the distribution-based clustering algorithm.

    perl ../merge_parent_child.pl seq_error_only.err > seq_error_only.err.list

    perl ../matrix_from_list.pl  raw_data.trim.seq.count seq_error_only.err.list > seq_error_only.err.list.mat

These files can be used with other programs (mothur, Qiime) for commonly performed community analysis.

RESULTS:

raw_data.trim.seq.count shows there are four unique sequences with more than 1000 counts across all libraries. These are the true input sequences. Unique sequences with less than 100 counts are errors generated during sequencing. There are two options. First, only sequencing error can be merged using the default parameters of the distribution based clustering. Alternatively, two of the true input sequences that are distributed in all three libraries equally could be merged, as these are closely related sequences (only differing by 1 bp). However, the other two true sequences are also only 1 bp different, but do not have the same distribution. This could be important information which should be retained. To cluster microdiveristy, use the alternative parameters presented above.
 
In seq_error_only.err.list.mat, there are four resulting OTUs, representing the four true input sequences. Unique sequences with less than 100 counts were merged with the parent sequences. In microdiversity.err.list.mat, there are three resulting OTUs. This represents two distinct unique sequences (HWI-EAS413_0071_FC:2:1:14612:9620#AGTAGAT/1 and HWI-EAS413_0071_FC:2:1:7014:1558#AGTAGAT/1) and one OTU with two merged true sequences because they are found in all libraries in a similar manner (HWI-EAS413_0071_FC:2:1:2111:1182#GTACGTT/1 and HWI-EAS413_0071_FC:2:1:7250:2720#GTACGTT/1). All sequencing error sequences were also grouped with the appropriate parents.

