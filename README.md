Distribution-based-clustering
=============================
Created by Sarah Pacocha Preheim

OUTLINE:

This README.md is divided into three different sections as follows:
I. Introduction to the method
II. Running Distribution-based clustering
III. Running Distribution-based clustering in parallel
IV. Clean up sequence data

I. Introduction to the method

DESCRIPTION:

Extremely accurate algorithm used to group DNA sequences from microbial communities into operational taxonomic units (proxy for species) for ecological or biomedical research. This algorithm uses the information contained in the distribution of DNA sequences across samples along with sequence similarity to cluster sequences more accurately than other methods that are currently available. Developed for Illumina next-generation sequencing libraries, but applicable to any sequencing platform with sufficient number of counts per sample to infer distribution patterns. 

WHEN TO USE THIS PROGRAM:

This program should be used with the scripts provided or in conjunction with other sequence analysis packages (i.e. mothur, Qiime) to obtain the operational taxonomic units (OTUs) that most accurately reflect the ecology of the input sequences they represent. This method does not cluster by distance alone, but instead using a combination to distance and distribution to inform the clustering. Thus, it is different from other methods in that it does not attempt to cluster by trying to use the rule-of-thumb genetic cut-off of 97% to estimate total species.

REQUIREMENTS (these verisons work, others unverified):

python (v2.7.3)
atlas (v3.8.3)
suitesparse (v20110224)
numpy (v1.5.1)
scipy (v0.11.0)
biopython
r (v2.15.3)
rpy2 (v2.3.6)

PIPELINE DEPENDENCIES, although other similar programs can be used which accomplish the same thing:

USEARCH (6.0.307, others unverified) for pre-processing steps

mothur (v.1.31.1, others unverified) for alignments

uchime (1.23.1, others unverified) for cleaning up chimeras

PRE_PROCESSING SEQUENCE DATA FROM RAW FASTQ:

Raw sequencing data can be generated in various ways. This will outline our method using qiime and mothur to process raw fastq data from Illumina for used with distribution-based clustering.

Follow the outline for SmileTrain, a set of python scripts and wrappers for USEARCH (https://github.com/almlab/SmileTrain).

II. Running Distribution-based clustering

The inputs to distribution-based clustering are alignment file(s) and an OTU by library matrix of 100% (dereplicated) sequence clusters. These can be generared with any alignment program, but for large datasets, aligning to a reference is preferred because it will be too time intensive to do a pair-wise alignment. Use typically use mothur and the Needleman-Wurch method. Follow these steps after processing with SmileTrain to get to dereplicated, fasta and OTU by library matrix.

A. Trim all of the sequences to the same length. If you don't trim sequences to the same length, shorter reads can be added to different OTUs than longer reads, even if they are the same sequence.

   perl ${BIN}/truncate_fasta2.pl ${UNIQUE}_output/seqs.trim.names.fasta ${TRIM} ${UNIQUE}_output/seqs.trim.names.${TRIM}

The trick is often to figure out what length to trim to. There are a few reccommendations that will make a more informed length choice. 1.) Trim to a conserved position. This will help improve the quality of the alignment (although including an unaligned dataset as well to DBC will clean up some alignment errors). 2.) Use a positive control to know whether too many sequences are lost when trimming. Shorter sequences than the required length are discarded and it can be useful to use a positive control to decide whether too many sequences are lost during any step. Follow the reccommendations in Preheim, et al 2013 Methods in Enzymology, Chapter 18, Fig. 18.2 to determine whether any filtering criteria is too stringent. 3.) Make a histogram of the length distribution and truncate to a length which captures about 85% of the total amount. This is a general rule of thumb, but it's a safe estimate.

B. Make an alignment. Typically we use align.seqs with mothur and the silva.bacteria.fasta database (http://www.mothur.org/wiki/Align.seqs). This default is the needleman-needleman alignment method and kmer searching.

    mothur "#align.seqs(fasta=./output_dir/unique.1.process.f0.fa, reference=./accessory_files/new_silva_short_unique_1_149.fa)"

This, along with the truncated alignment file can be used to create the input to DBC

C. Run DBC.

Import these modules:
       module add python/2.7.3
       module add atlas/3.8.3
       module add suitesparse/20110224
       module add numpy/1.5.1
       module add scipy/0.11.0
       module add biopython
       module add r/2.15.3
       module add rpy2/2.3.6

Then run DBC:

     python new_DBC2.py eOTU_combined_complete.1.process.f0.mat eOTU_combined_complete.1.process.f0.align > eOTU_combined_complete.1.process.newDBC.err

The output is the error file, containing information about which sequences are merged and which are parents. This can be parsed into a list file with

    perl ~/bin/err2list.pl eOTU_combined_complete.1.process.newDBC.err eOTU_combined_complete.1.process.f0.mat > eOTU_combined_complete.1.process.newDBC.err.list

III. Running Distribution-based clustering in parallel

Use the following outline as a guide to running data through distribution-based clustering in parallel. For any typical Illumina dataset, you will need to use a method that divides up the process of making OTUs with distribution-based clustering. The following steps outline how the dataset can be divided with very little loss of accuracy.

PARALLEL PRE-PROCESSING STEPS-

1.) Progressively cluster sequences with USEARCH into 90% identity clusters. The results of this will be a list of sequences within 90% identity clusters, and the full fasta and sequence by library matrix used for downstream analysis.

    ./ProgressiveClustering_USEARCH.csh ./all_variables

(Alternatively, you can use UCLUST instead of USEARCH with ./ProgressiveClustering.csh). The results of this is a list of sequences clustered by sequence similarity. Each line is a group (in this case 90% OTUs) which will be clustered with ditribution-based-clustering.pl independently from seqeunces on different lines. Each group (i.e. line) contains the names of the seqeunces (de-replicated so only one instance of the same sequence is represented) tab delimited. In this example, there is only one group, and there are 9 different unique sequences to be clustered.

This runs the progressive clustering with a shell script, but you can also either cluster just cluster to 90% with USEARCH or do it progressively as follows:


A. Prepare the unique fasta sequences (100% clusters) for USEARCH clustering. This counts up the number of times each sequence is observed and orders it by decreasing abundance, although any method will do.

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

2.) Create the files for processing in parallel using the output of the ProgressiveClustering_USEARCH.csh (Don't need to run this if you are using eOTU_parallel.csh)

    perl create_parallel_files.pl ./output_dir/unique.PC.final.list ./output_dir/unique.fa ./output_dir/unique.f0.mat ./output_dir/unique process.f0

This will create one fasta and one sequence by library matrix file for each line of the unique_final.list. These can be used in parallel to process the data. In the example, there is only one group (i.e. one line in the list) so there is only one set of files (unique.1.process.f0.fa and unique.1.process.f0.mat).

2.) [Parallel] Align sequences to a reference and create the distance matrix. Then use these as input to the distribution_clustering.pl. For the parallel process, replace /output_dir/unique.1.process.f0.fa with /output_dir/unique.{JOB_NO}.process.* for all commands below:

    mothur "#align.seqs(fasta=./output_dir/unique.1.process.f0.fa, reference=./accessory_files/new_silva_short_unique_1_149.fa)"
    
    python new_DBC2.py ./output_dir/unique.1.process.f0.mat ./output_dir/unique.1.process.f0.align > ./output_dir/unique.1.process.f0.err

The results of this will be ./output_dir/unique.1.process.f0.err which is the results of the clustering output and ./output_dir/unique.1.process.f0.log. It is important that the last line of ./output_dir/unique.1.process.f0.err says "Finished distribution based clustering" and that there are no warnings (will be uppercase "WARNING:" followed by the specific problem) in the ./output_dir/unique.1.process.f0.log file (the "Warning message: In chisq.test(x) :Chi-squared approximation may be incorrect" is ok). That can be checked automatically with the program below.

3.) Evaluate whether all parallel processes completed. This will check for all completed processes and look for the WARNINGs stateed above.

    perl evaluate_parallel_results.pl ./all_variables eval_output

The results will be in ./eval_output.log. This should say all files were created and all files were finished. If it does not indicate that all of the error files are complete, continue with step 4. If they say there are WARNINGs, this typically means the program is not calling R correctly. Check to make sure that you can call the program R by typing R on the command line, and check whether the version of R is correct. Otherwise, you will need to make adjustments. Email spacocha@mit.edu if there is a problem calling R at this step.

Re-do step 3 after this to make sure the problem was fixed

4.) Make the final files. This involves creating a list from error files, a mat file from the list, and a fasta from the mat. (You can use clean_up_parallel_ultra.csh to remove OTUs that do not match the full length of the 16S region and chimeric sequences or do this seperately)

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

IV. Clean up sequence data

1. Now check that each sequences is actually what you are looking for. You can do this by getting a representative alignment (like silva reference alignment for 16S) and aligning the representatives, then filtering out any sequences that do not span the entire sequenced region.

   mothur "#align.seqs(fasta=unique_prefix.all_err.list.mat.fa, reference=new_silva_short_unique_1_149.fa)"
   mothur "#(fasta=unique_prefix.all_err.list.mat.align, start=1, end=149)"

2. Remove any non-16S sequences from the matrix and the representativel fasta file

   perl ./bin/filter_mat_from_fasta.pl unique_prefix.all_err.list.mat unique_prefix.all_err.list.mat.good.align > unique_prefix.all_err.list.mat.good
   perl ./bin/fasta2filter_from_mat.pl unique_prefix.all_err.list.mat unique_prefix.all_err.list.mat.good.align > unique_prefix.all_err.list.mat.good.fa

3. Now prepare the representative sequences for chimera checking with uchime by adding their abundance to the data

   perl ./bin/fasta2uchime_mat.pl unique_prefix.all_err.list.mat.good unique_prefix.all_err.list.mat.good.fa > unique_prefix.all_err.list.mat.good.ab.fa

4. Run uchime to check for chimeras.

   uchime --input unique_prefix.all_err.list.mat.good.ab.fa --uchimeout unique_prefix.all_err.list.mat.good.ab.res --minchunk 20 --abskew 10

5. Remove chimeras from the final dataset

   perl ./bin/filter_mat_uchime.pl unique_prefix.all_err.list.mat.good.ab.res unique_prefix.all_err.list.mat.good > unique_prefix.all_err.list.mat.good.uchime
   perl ./bin/filter_fasta_uchime.pl unique_prefix.all_err.list.mat.good.ab.res unique_prefix.all_err.list.mat.good.fa > unique_prefix.all_err.list.mat.good.uchime.fa

6. Rename the files to have short final names

   mv unique_prefix.all_err.list.mat.good.uchime unique_prefix.final.mat
   mv unique_prefix.all_err.list.mat.good.uchime.fa unique_prefix.final.fa

The final clustered results will be in the files
fasta of OTU representatives- ./output_dir/unique.final.fa
OTU_table in tab form- ./output_dir/unique.final.mat

The above lists our pipeline for processing raw fastq data. However, many of the steps can be replaced with different equivelent programs and our pipeline isn't required to run the clustering algorithm. Below outlines just the information needed to run the clustering algorithm with different types of inputs


