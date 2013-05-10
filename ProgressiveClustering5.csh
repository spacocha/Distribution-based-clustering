#! /bin/sh
#$ -S /bin/bash
# -cwd

source /etc/profile.d/modules.sh
module load qiime-default
. $1

echo "${QIIMEFILE}\n";
#reduce sequences by only using 
perl ${BIN}/fasta2unique_table4.pl ${QIIMEFILE} ${UNIQUE}

#make a first pass OTU table (100% identity OTUs) with filter
perl ${BIN}/OTU2lib_count_trans1.pl ${UNIQUE}.trans ${FNUMBER} > ${UNIQUE}.f${FNUMBER}.mat

#prepare the file for uclust
perl ${BIN}/fasta2uchime_2.pl ${UNIQUE}.f${FNUMBER}.mat ${UNIQUE}.fa > ${UNIQUE}.ab.fa

#progressively cluster the first value
uclust --input ${UNIQUE}.ab.fa --id 0.${UPPER} --uc ${UNIQUE}.${UPPER}.uc --maxrejects 500 --maxaccepts 20

uclust --input ${UNIQUE}.ab.fa --uc2fasta ${UNIQUE}.${UPPER}.uc  --output ${UNIQUE}.${UPPER}.fa --types S

perl ${BIN}/fasta_remove_seed.pl ${UNIQUE}.${UPPER}.fa > ${UNIQUE}.${UPPER}.fa2

perl ${BIN}/UC2list2.pl ${UNIQUE}.${UPPER}.uc > ${UNIQUE}.${UPPER}.uc.list
#repeat for the rest of the range

UPPERM1=`expr ${UPPER} - 1`

for ((i=${UPPERM1}; i >= ${LOWER} ; i--))
do
before=`expr $i + 1`
uclust --input ${UNIQUE}.${before}.fa2 --id 0.${i} --uc ${UNIQUE}.${i}.uc --maxrejects 500 --maxaccepts 20

uclust --input ${UNIQUE}.${before}.fa2 --uc2fasta ${UNIQUE}.${i}.uc  --output ${UNIQUE}.${i}.fa --types S

perl ${BIN}/fasta_remove_seed.pl ${UNIQUE}.${i}.fa > ${UNIQUE}.${i}.fa2

perl ${BIN}/UC2list2.pl ${UNIQUE}.${i}.uc > ${UNIQUE}.${i}.uc.list

done

perl ${BIN}/merge_progressive_clustering.pl ${UNIQUE}*.uc.list > ${UNIQUE}.PC.final.list


