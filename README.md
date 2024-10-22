Distribution-based-clustering
=============================
Created by Sarah Pacocha Preheim

UPDATE:
This implementation of Distribution-based clustering has been replaced with a more efficient program (dbotu3). The latest implementation of Distribution-based clustering ( https://github.com/almlab/dbotu3) relies on the same underlying principles, but is coded to be faster and more efficient.

To use Distribution-based clustering please visit the following website:
 https://github.com/almlab/dbotu3


This has also been made into a QIIME plug-in:
https://github.com/cduvallet/q2-dbotu




THIS IS ARCHIVED INFORMATION FOR THE OUT-DATED PROGRAM CODE-

OUTLINE:

This README.md is divided into three different sections as follows:
I. Introduction to the method
II. Running Distribution-based clustering in parallel
III. Running Distribution-based clustering without parallelization



I. Introduction to the method

DESCRIPTION:

Extremely accurate algorithm used to group DNA sequences from microbial communities into operational taxonomic units (proxy for species) for ecological or biomedical research. This algorithm uses the information contained in the distribution of DNA sequences across samples along with sequence similarity to cluster sequences more accurately than other methods that are currently available. Developed for Illumina next-generation sequencing libraries, but applicable to any sequencing platform with sufficient number of counts per sample to infer distribution patterns. 

WHEN TO USE THIS PROGRAM:

This program should be used with the scripts provided or in conjunction with other sequence analysis packages (i.e. mothur, Qiime) to obtain the operational taxonomic units (OTUs) that most accurately reflect the ecology of the input sequences they represent. This method does not cluster by distance alone, but instead using a combination to distance and distribution to inform the clustering. Thus, it is different from other methods in that it does not attempt to cluster by trying to use the rule-of-thumb genetic cut-off of 97% to estimate total species.

REQUIREMENTS:

perl (v5.8.8, other versions unverified)

R (2.12.1, others unverified)

PIPELINE DEPENDENCIES, although other similar programs can be used which accomplish the same thing:

QIIME (1.3.0, others unverified) or mothur (v.1.31.1, others unverified) for pre-processing raw fastq data

USEARCH (6.0.307, others unverified) for Progressive clustering for parallel processing

mothur (v.1.31.1, others unverified) for alignments

FastTree (2.1.3, others unverified) for distances

uchime (1.23.1, others unverified) for cleaning up chimeras

PRE_PROCESSING SEQUENCE DATA FROM RAW FASTQ:

Raw sequencing data can be generated in various ways. This will outline our method using qiime and mothur to process raw fastq data from Illumina for used with distribution-based clustering.

You can use our pipeline to process fastq data (if it helps), or just make a fasta file in any manner you see fit from raw data. Our steps include quality filtering, removing primer sequences and trimming sequences to the same length. These steps may not all be necessary for your specific data. It also doesn't include overlapping or paired end reads.

II. Running Distribution-based clustering in parallel

Use the following outline as a guide to running data through distribution-based clustering in parallel. For any typical Illumina dataset, you will need to use a method that divides up the process of making OTUs with distribution-based clustering. The memory requirements would be too large to run a typical dataset through distribution-based clustering as a whole. So the following steps outline how the dataset can be divided with very little loss of accuracy to be processed faster and with less memory demand.

Many of the shell scripts (*.csh) are collections of commands calling other programs (such as mothur or FastTree etc) and can be altered to suit the needs of the user. The shell scripts are provided as guides to help identify all of the steps necessary to process Illumina data with distribution-based culstering. It is divided into two sections, PARALLEL PRE-PROCESSING STEPS which include many shell scripts and steps that are used to process the data for use with distribution-based clustering, and RUNNING DISTRIBUTION-BASED CLUSTERING IN PARALLEL, which actually runs the algorithm to make OTUs.

PARALLEL PRE-PROCESSING STEPS-

1.) Create a trimmed, quality filtered file, formatted in the QIIME split_libraries_fastq.py format. The library name is the first entry in the header field, followed by "_" and a unique number (e.g. lib1_1 ) followed by a space with the header name from the fastq file (e.g. ">lib1_1 MISEQ578:1:1101:15644:2126#AATGTCAA/1 orig_bc=TTGACATT new_bc=TTGACATT bc_diffs=0"). Library names can not have any spaces, and as a general rule, it is safe to only include "." as the only non-alpha numeric characters. We generate these files with the following commands from a fastq file in the format ./test_data/raw_data.fastq. From within the downloaded folder (Distribution-based-clustering-master), make an output folder so all of the result will be found in the same place. This corresponds to the field UNIQUE=./output_dir/unique in ./all_variables
For example, this can be done with:

    mkdir output_dir

Now, processes the raw fastq with qiime using the shell:

    ./RunQiime_rawdata.csh ./all_variables

This will create a folder ./output_dir/unique_output with the results. Specifically, the file seqs.trim.names.76.fa will be used for further analysis. Again, this type of file can be created in other ways, although the next program will not work unless the fasta is formatted with the library name as the first part of the header like this:
\>lib2_0 HWI-EAS413_0071_FC:2:1:2111:1182#GTACGTT/1 orig_bc=GTACGTT new_bc=GTACGTT bc_diffs=0
TACGTAGGGTGCGAGCGTTAATCGGAATTACTGGGCGTAAAGCGTGCGCAGGCGGTTTTGTAAGTCAGATGTGAAA

The ./RunQiime_rawdata.csh is a shell script that runs the following commands for you. If you can not get the shell script to work, try to modify it to run each of the following commands individually

A. First, use QIIME to divide your fastq file. You may need to change this for different versions of QIIME. I am including the variables (${VARIABLE}) which are taken from the ./all_variables file in the script, but you will need to replace them with the actual value if you run this on the commands line. So you would type ./test_data/raw_data.fastq instead of ${SOLFILEF} and so on.

    split_libraries_fastq.py -i ${SOLFILEF} -b ${BARFILE} -o ${UNIQUE}_output -m ${MAPFILE} --barcode_type ${BARLEN} --min_per_read_length ${MINLEN} --last_bad_
quality_char ${QUAL} --max_barcode_errors 0 --max_bad_run_length ${BADRUN} ${SLV}

B. Next remove oligos (if necessary) from the sequence. This could also be done with QIIME if they have the option to remove the oligo in future version (our working version does not). Again, ${VARIABLE} will have to be replaced by the actual value from all_variables file in order to run it.

   mothur "#trim.seqs(fasta=${UNIQUE}_output/seqs.fna, oligos=${OLIGO})"

C. Return the names to the QIIME formatted names

   perl ${BIN}/revert_names_mothur3.pl ${UNIQUE}_output/seqs.fna ${UNIQUE}_output/seqs.trim.fasta > ${UNIQUE}_output/seqs.trim.names.fasta

D. Trim all of the sequences to the same length. If you don't trim sequences to the same length, shorter reads can be added to different OTUs than longer reads, even if they are the same sequence.

   perl ${BIN}/truncate_fasta2.pl ${UNIQUE}_output/seqs.trim.names.fasta ${TRIM} ${UNIQUE}_output/seqs.trim.names.${TRIM}


2.) Progressively cluster sequences with USEARCH into 90% identity clusters. The results of this will be a list of sequences within 90% identity clusters, and the full fasta and sequence by library matrix used for downstream analysis.

    ./ProgressiveClustering_USEARCH.csh ./all_variables

(Alternatively, you can use UCLUST instead of USEARCH with ./ProgressiveClustering.csh). The results of this is a list of sequences clustered by sequence similarity. Each line is a group (in this case 90% OTUs) which will be clustered with ditribution-based-clustering.pl independently from seqeunces on different lines. Each group (i.e. line) contains the names of the seqeunces (de-replicated so only one instance of the same sequence is represented) tab delimited. In this example, there is only one group, and there are 9 different unique sequences to be clustered.

This runs the progressive clustering with a shell script, but you can also either cluster just cluster to 90% with USEARCH or do it progressively as follows:

A. Transform the sequences into 100% clusters (keep only unique sequences or dereplicate them). There are many ways of doing this, but I like to use my own script. fastafile_in_QIIME_format is the fasta file that was made by QIIME from the previous section. It must be in QIIME format with the library name and unique number after the lib name. unique_prefix is a unique prefix attached to all of the files

   perl ./bin/fasta2unique_table5.pl fastafile_in_QIIME_format unique_prefix

B. Then make the 100% clusters OTU by library matrix. unique_prefix.trans was made in the previous step. 0 is the number to be filtered to (i.e. remove any 100% OTUs with less than 0 counts across all libraries). To get rid of singletons, use 2.

   perl ./bin/OTU2lib_count_trans1.pl unique_prefix.trans 0 > unique_prefix.f0.mat

C. Prepare the unique fasta sequences (100% clusters) for USEARCH clustering. This counts up the number of times each sequence is observed and orders it by decreasing abundance.

   perl ./bin/fasta2uchime_2.pl unique_prefix.f0.mat unique_prefix.fa > unique_prefix.ab.fa

D. Cluster at 99% with USEARCH. This gathers sequences that are very similar to make sure that these relationships are preserved in the final dataset.

    usearch -cluster_fast unique_prefix.ab.fa -id 0.99 -centroids unique_prefix.99.fa2 -uc unique_prefix.99.uc

E. Make the output into a list of OTUs to be used later.

    perl ./bin/UC2list2.pl unique_prefix.99.uc > unique_prefix.99.uc.list

F. Repeat D and E for 98%, 97%, 96% ... to 90% identity.

G. Fianlly gather all the data into one file where unique_prefix*.uc.list is a wildcard that inputs all of the list files that were previously generated in the preeceeding steps.

   perl ./bin/merge_progressive_clustering.pl unique_prefix*.uc.list > unique_prefix.PC.final.list   

RUNNING DISTRIBUTION-BASED CLUSTERING IN PARALLEL:

Commonly, this program will be run in parallel on datasets that are fairly large. This section describes how to process sequences in parallel, beginning from data that is de-replicated and has an associated sequence by library count matrix associated with it. You can run the following for each line of the unique_prefix.PC.final.list.

	  eOTU_parallel.csh ./all_variables

Alternatively, since this shell might not work for you, run the following (1 and 2) where you do 1 once, and 2 for the number of lines in unique_prefix.PC.final.list.

1.) Create the files for processing in parallel using the output of the ProgressiveClustering_USEARCH.csh (Don't need to run this if you are using eOTU_parallel.csh)

    perl create_parallel_files.pl ./output_dir/unique.PC.final.list ./output_dir/unique.fa ./output_dir/unique.f0.mat ./output_dir/unique process.f0

This will create one fasta and one sequence by library matrix file for each line of the unique_final.list. These can be used in parallel to process the data. In the example, there is only one group (i.e. one line in the list) so there is only one set of files (unique.1.process.f0.fa and unique.1.process.f0.mat).

2.) [Parallel] Align sequences to a reference and create the distance matrix. Then use these as input to the distribution_clustering.pl. For the parallel process, replace /output_dir/unique.1.process.f0.fa with /output_dir/unique.{JOB_NO}.process.* for all commands below:

    mothur "#align.seqs(fasta=./output_dir/unique.1.process.f0.fa, reference=./accessory_files/new_silva_short_unique_1_149.fa)"
    
    FastTree -nt -makematrix ./output_dir/unique.1.process.f0.align > ./output_dir/unique.1.process.f0.align.dst

    FastTree -nt -makematrix ./output_dir/unique.1.process.f0.fa > ./output_dir/unique.1.process.f0.unalign.dst

    perl distribution_clustering.pl -m ./output_dir/unique.1.process.f0.mat -d ./output_dir/unique.1.process.f0.align.dst,./output_dir/unique.1.process.f0.unalign.dst -out output_dir/unique.1.process.f0

The results of this will be ./output_dir/unique.1.process.f0.err which is the results of the clustering output and ./output_dir/unique.1.process.f0.log. It is important that the last line of ./output_dir/unique.1.process.f0.err says "Finished distribution based clustering" and that there are no warnings (will be uppercase "WARNING:" followed by the specific problem) in the ./output_dir/unique.1.process.f0.log file (the "Warning message: In chisq.test(x) :Chi-squared approximation may be incorrect" is ok). That can be checked automatically with the program below.

3.) Evaluate whether all parallel processes completed. This will check for all completed processes and look for the WARNINGs stateed above.

    perl evaluate_parallel_results.pl ./all_variables eval_output

The results will be in ./eval_output.log. This should say all files were created and all files were finished. If it does not indicate that all of the error files are complete, continue with step 4. If they say there are WARNINGs, this typically means the program is not calling R correctly. Check to make sure that you can call the program R by typing R on the command line, and check whether the version of R is correct. Otherwise, you will need to make adjustments. Email spacocha@mit.edu if there is a problem calling R at this step.

4.) Re-run failed jobs by using the -old flag in distribution_clustering.pl for each failed process. This will continue where the program left off.

    perl distribution_clustering.pl -m ./output_dir/unique.1.process.f0.mat -d ./output_dir/unique.1.process.f0.align.dst,./output_dir/unique.1.process.f0.unalign.dst -out output_dir/unique.1.process.f0 -old

Re-do step 3 after this to make sure the problem was fixed

5.) Make the final files. This involves creating a list from error files, a mat file from the list, and a fasta from the mat. (You can use clean_up_parallel_ultra.csh to remove OTUs that do not match the full length of the 16S region and chimeric sequences or do this seperately)

    ./clean_up_parallel_ultra.csh ./all_variables

clean_up_parallel_untra.csh is a shell that does the following:

A. Combined all of the error files

   cat unique_prefix*.f0.err > unqiue_prefix.all_err.txt

B. Translate the error files into a list of sequences in an OTU where the first column are the OTU representative sequences and the other columns are other sequences in the OTU

   perl ./bin/err2list3.pl unique_prefix.all_err.txt > unique_prefix.all_err.list

C. Make the new OTU by library matrix including all of the sequences in each OTU

   perl ./bin/list2mat.pl unique_prefix.f0.mat unique_sequences.all_err.list eco > unique_prefix.all_err.list.mat

D. Get just the representative sequences for each OTU

   perl ./bin/fasta2filter_from_mat.pl unique_prefix.all_err.list.mat unique_prefix.fa > unique_prefix.all_err.list.mat.fa

E. Now check that each sequences is actually what you are looking for. You can do this by getting a representative alignment (like silva reference alignment for 16S) and aligning the representatives, then filtering out any sequences that do not span the entire sequenced region.

   mothur "#align.seqs(fasta=unique_prefix.all_err.list.mat.fa, reference=new_silva_short_unique_1_149.fa)"
   mothur "#(fasta=unique_prefix.all_err.list.mat.align, start=1, end=149)"

F. Remove any non-16S sequences from the matrix and the representativel fasta file

   perl ./bin/filter_mat_from_fasta.pl unique_prefix.all_err.list.mat unique_prefix.all_err.list.mat.good.align > unique_prefix.all_err.list.mat.good
   perl ./bin/fasta2filter_from_mat.pl unique_prefix.all_err.list.mat unique_prefix.all_err.list.mat.good.align > unique_prefix.all_err.list.mat.good.fa

G. Now prepare the representative sequences for chimera checking with uchime by adding their abundance to the data

   perl ./bin/fasta2uchime_mat.pl unique_prefix.all_err.list.mat.good unique_prefix.all_err.list.mat.good.fa > unique_prefix.all_err.list.mat.good.ab.fa

H. Run uchime to check for chimeras.

   uchime --input unique_prefix.all_err.list.mat.good.ab.fa --uchimeout unique_prefix.all_err.list.mat.good.ab.res --minchunk 20 --abskew 10

I. Remove chimeras from the final dataset

   perl ./bin/filter_mat_uchime.pl unique_prefix.all_err.list.mat.good.ab.res unique_prefix.all_err.list.mat.good > unique_prefix.all_err.list.mat.good.uchime
   perl ./bin/filter_fasta_uchime.pl unique_prefix.all_err.list.mat.good.ab.res unique_prefix.all_err.list.mat.good.fa > unique_prefix.all_err.list.mat.good.uchime.fa

J. Rename the files to have short final names

   mv unique_prefix.all_err.list.mat.good.uchime unique_prefix.final.mat
   mv unique_prefix.all_err.list.mat.good.uchime.fa unique_prefix.final.fa

The final clustered results will be in the files
fasta of OTU representatives- ./output_dir/unique.final.fa
OTU_table in tab form- ./output_dir/unique.final.mat

The above lists our pipeline for processing raw fastq data. However, many of the steps can be replaced with different equivelent programs and our pipeline isn't required to run the clustering algorithm. Below outlines just the information needed to run the clustering algorithm with different types of inputs


III. Running Distribution-based clustering without parallelization

This section describes in more detail how to run one instance of distribution-based clustering. Typical datasets will not work running in this manner because of the size of the dataset and the memory required to process all of the sequences. However, it is an alternative method for very small dataset, including a way to use mothur to pre-process the samples for clustering. This is not a continuation of the steps above. It includes another desciption of what is required as input for the distribution-based clustering program and also includes a processing pipeline with mothur.

DISTRIBUTION-BASED CLUSTERING ALGORITHM-

REQUIRED INPUTS:

This program requires that raw sequencing data is pre-processed into two files

1.) Distance file of unique seqeunces

- The raw data must be combined into unique (non-redundant) sequences, which works very well when all sequences are processed to the same length.

- A pairwise distance matrix must be created for all unique sequences and presented as a .dst file.

- Also, both aligned and unaligned distances can be entered use as inputs, reducing the error from misalignment.

2.) Community-by-sequence matrix

- This is a file containing a unique name for each non-redundant sequence and the number of counts for that seqeunce in each sampled community

- Communities are columns and OTUs are rows

- Lines beginning with "# " (hash followed by a space) are ignored

MAIN PROGRAM:

distribution_clustering.pl

- This is the main program creating the distribution-based OTUs. To use this requires that R is accessible by calling R through the system command. If not, it will not run.

- To use type "perl distribution_clustering.pl" to get a complete list of requirements and options

REQUIRED ACCESSORY PROGRAMS:

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

- ./accessory_files/oligos.tab is required for filtering out primer/adapters from sequencing construct if not using mothur to de-multiples

- ./accessory_files/new_silva_short_unique_1_149.fa is a reference alignment trimmed to the size of the construct. 


1. MOTHUR PRE-PROCESSING STEPS

You can use mothur to process the files. Do not attempt this non-parallel method with more than 1 million reads or so (although the exact read count is based on the number of non-redundant sequence). First make the output directory mothur_dir and move ./test_data/raw_data.fastq there.

mothur commands as follows from within the mothur_dir:

    mothur > fastq.info(fastq=raw_data.fastq)

     - This will generate raw_data.fasta and raw_data.qual

    mothur > trim.seqs(fasta=raw_data.fasta, oligos=../accessory_files/oligos.tab, qfile=raw_data.qual, qthreshold=48, minlength=76, maxhomop=10)

     - This will generate raw_data.trim.fasta, with low quality sequences filtered out. All sequences will be the same length

    mothur > unique.seqs(fasta=raw_data.trim.fasta)

     - This will reduce redundant sequences and represent them as one "unique" sequences in raw_data.trim.unique.fasta

    mothur > align.seqs(fasta=raw_data.trim.unique.fasta, reference=../accessory_files/new_silva_short_unique_1_149.fa)

     - align sequences to a referece alignment

    mothur > dist.seqs(fasta=raw_data.trim.unique.align, cutoff=0.10, output=square)

     - creates the phylip formatted distance matrix (raw_data.trim.unique.square.dist), used in distribution_clustering.pl

    mothur > count.seqs(name=raw_data.trim.names, group=../test_data/raw_data.group)

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

    perl ../matrix_from_list.pl  raw_data.trim.seq.count seq_error_only.err.list eco > seq_error_only.err.list.mat

Repeat for the microdiversity.err files. These files can be used with other programs (mothur, Qiime) for commonly performed community analysis.

RESULTS:

raw_data.trim.seq.count shows there are four unique sequences with more than 1000 counts across all libraries. These are the true input sequences. Unique sequences with less than 100 counts are errors generated during sequencing. There are two options. First, only sequencing error can be merged using the default parameters of the distribution based clustering. Alternatively, two of the true input sequences that are distributed in all three libraries equally could be merged, as these are closely related sequences (only differing by 1 bp). However, the other two true sequences are also only 1 bp different, but do not have the same distribution. This could be important information which should be retained. To cluster microdiveristy, use the alternative parameters presented above.
 
In seq_error_only.err.list.mat, there are four resulting OTUs, representing the four true input sequences. Unique sequences with less than 100 counts were merged with the parent sequences. In microdiversity.err.list.mat, there are three resulting OTUs. This represents two distinct unique sequences (HWI-EAS413_0071_FC:2:1:14612:9620#AGTAGAT/1 and HWI-EAS413_0071_FC:2:1:7014:1558#AGTAGAT/1) and one OTU with two merged true sequences because they are found in all libraries in a similar manner (HWI-EAS413_0071_FC:2:1:2111:1182#GTACGTT/1 and HWI-EAS413_0071_FC:2:1:7250:2720#GTACGTT/1). All sequencing error sequences were also grouped with the appropriate parents.

