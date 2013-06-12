#! /bin/sh
#$ -S /bin/bash
# -cwd

#path to file where all of the data is
#load in the variables from the second command line input
. ./$1

#mothur is required

#combined all error files into one
cat ${UNIQUE}*f${FNUMBER}.err > ${UNIQUE}.all_err.txt
perl ${BIN}/err2list3.pl ${UNIQUE}.all_err.txt > ${UNIQUE}.all_err.list
perl ${BIN}/list2mat.pl ${UNIQUE}.f0.mat ${UNIQUE}.all_err.list eco > ${UNIQUE}.all_err.list.mat
perl ${BIN}/fasta2filter_from_mat.pl  ${UNIQUE}.all_err.list.mat ${UNIQUE}.fa > ${UNIQUE}.all_err.list.mat.fa
mothur "#align.seqs(fasta=${UNIQUE}.all_err.list.mat.fa, reference=${FALIGN})"
mothur "#screen.seqs(fasta=${UNIQUE}.all_err.list.mat.align, start=${ALIGNSTART}, end=${ALIGNEND})"
perl ${BIN}/filter_mat_from_fasta.pl ${UNIQUE}.all_err.list.mat ${UNIQUE}.all_err.list.mat.good.align > ${UNIQUE}.all_err.list.mat.good
perl ${BIN}/fasta2filter_from_mat.pl ${UNIQUE}.all_err.list.mat.good ${UNIQUE}.all_err.list.mat.fa > ${UNIQUE}.all_err.list.mat.good.fa
perl ${BIN}/fasta2uchime_mat.pl ${UNIQUE}.all_err.list.mat.good ${UNIQUE}.all_err.list.mat.good.fa > ${UNIQUE}.all_err.list.mat.good.ab.fa
uchime --input ${UNIQUE}.all_err.list.mat.good.ab.fa --uchimeout ${UNIQUE}.all_err.list.mat.good.ab.res ${UCHIMEPARAM}
perl ${BIN}/filter_mat_uchime.pl ${UNIQUE}.all_err.list.mat.good.ab.res ${UNIQUE}.all_err.list.mat.good > ${UNIQUE}.all_err.list.mat.good.uchime
perl ${BIN}/filter_fasta_uchime.pl ${UNIQUE}.all_err.list.mat.good.ab.res ${UNIQUE}.all_err.list.mat.good.fa > ${UNIQUE}.all_err.list.mat.good.uchime.fa

mv ${UNIQUE}.all_err.list.mat.good.uchime ${UNIQUE}.final.mat
mv ${UNIQUE}.all_err.list.mat.good.uchime.fa ${UNIQUE}.final.fa
