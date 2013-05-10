#! /bin/sh
#$ -S /bin/bash
# -cwd

source /etc/profile.d/modules.sh
module load qiime-default
. $1

echo "${QIIMEFILE}\n";
#reduce sequences by only using 
perl ${BIN}/fasta2unique_table5.pl ${QIIMEFILE} ${UNIQUE}

#make a first pass OTU table (100% identity OTUs) with filter
perl ${BIN}/OTU2lib_count_trans1.pl ${UNIQUE}.trans ${FNUMBER} > ${UNIQUE}.f${FNUMBER}.mat

#prepare the file for uclust
perl ${BIN}/fasta2uchime_2.pl ${UNIQUE}.f${FNUMBER}.mat ${UNIQUE}.fa > ${UNIQUE}.ab.fa

#progressively cluster, but 0.99 doesn't do anything,  so start with 0.98
uclust --input ${UNIQUE}.ab.fa --id 0.98 --uc ${UNIQUE}.98.uc --maxrejects 500 --maxaccepts 20

uclust --input ${UNIQUE}.ab.fa --uc2fasta ${UNIQUE}.98.uc  --output ${UNIQUE}.98.fa --types S

perl ${BIN}/fasta_remove_seed.pl ${UNIQUE}.98.fa > ${UNIQUE}.98.fa2

perl ${BIN}/UC2list2.pl ${UNIQUE}.98.uc > ${UNIQUE}.98.uc.list
#repeat for 97-90

for i in 97 96 95 94 93 92 91 90
do
before=`expr $i + 1`
uclust --input ${UNIQUE}.${before}.fa2 --id 0.${i} --uc ${UNIQUE}.${i}.uc --maxrejects 500 --maxaccepts 20

uclust --input ${UNIQUE}.${before}.fa2 --uc2fasta ${UNIQUE}.${i}.uc  --output ${UNIQUE}.${i}.fa --types S

perl ${BIN}/fasta_remove_seed.pl ${UNIQUE}.${i}.fa > ${UNIQUE}.${i}.fa2

perl ${BIN}/UC2list2.pl ${UNIQUE}.${i}.uc > ${UNIQUE}.${i}.uc.list

done

perl ${BIN}/merge_progressive_clustering.pl ${UNIQUE}*.uc.list > ${PCLUSTOUTPUT}


