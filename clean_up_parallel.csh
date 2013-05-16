#! /bin/sh
#$ -S /bin/bash
# -cwd

#path to file where all of the data is
#load in the variables from the second command line input
. ./$1

#mothur is required
source /etc/profile.d/modules.sh
module load mothur

#combined all error files into one
cat ${BEFORE}*${AFTER}.err > ${UNIQUE}.all_err.txt
perl ${BIN}/err2list3.pl ${UNIQUE}.all_err.txt > ${UNIQUE}.all_err.list
perl ${BIN}/list2mat.pl ${UNIQUE}.f0.mat ${UNIQUE}.all_err.list eco > ${UNIQUE}.all_err.list.mat
perl ${BIN}/fasta2filter_from_mat.pl  ${UNIQUE}.all_err.list.mat ${UNIQUE}.fa > ${UNIQUE}.all_err.list.mat.fa

mv ${UNIQUE}.all_err.list.mat ${UNIQUE}.final.mat
mv ${UNIQUE}.all_err.list.mat.fa ${UNIQUE}.final.fa
mv ${UNIQUE}.all_err.list ${UNIQUE}.final.list