#! /bin/sh
#$ -S /bin/bash
# -cwd

. $1

echo "${QIIMEFILE}\n";
#reduce sequences by only using 
perl ${BIN}/fasta2unique_table4.pl ${QIIMEFILE} ${UNIQUE}

#make a first pass OTU table (100% identity OTUs) with filter
perl ${BIN}/OTU2lib_count_trans1.pl ${UNIQUE}.trans ${FNUMBER} > ${UNIQUE}.f${FNUMBER}.mat

#prepare the file for uclust
perl ${BIN}/fasta2uchime_2.pl ${UNIQUE}.f${FNUMBER}.mat ${UNIQUE}.fa > ${UNIQUE}.ab.fa

#progressively cluster the first value
usearch -cluster_fast ${UNIQUE}.ab.fa -id 0.${UPPER} -centroids ${UNIQUE}.${UPPER}.fa2 -uc ${UNIQUE}.${UPPER}.uc

perl ${BIN}/UC2list2.pl ${UNIQUE}.${UPPER}.uc > ${UNIQUE}.${UPPER}.uc.list
#repeat for the rest of the range

UPPERM1=`expr ${UPPER} - 1`

for ((i=${UPPERM1}; i >= ${LOWER} ; i--))
do
before=`expr $i + 1`
usearch -cluster_fast ${UNIQUE}.${before}.fa2 --id 0.${i} -centroids ${UNIQUE}.${i}.fa2 -uc ${UNIQUE}.${i}.uc

perl ${BIN}/UC2list2.pl ${UNIQUE}.${i}.uc > ${UNIQUE}.${i}.uc.list

done

perl ${BIN}/merge_progressive_clustering.pl ${UNIQUE}*.uc.list > ${UNIQUE}.PC.final.list


