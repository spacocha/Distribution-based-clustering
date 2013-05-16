#! /bin/sh
#$ -S /bin/bash
# -cwd

#path to file where all of the data is
#load in the variables from the second command line input
. ./$1

source /etc/profile.d/modules.sh
module load qiime-default
module load R/2.12.1
module load mothur

#process number is the first command line variable
UNIQUE2=${UNIQUE}.${SGE_TASK_ID}.${AFTER}


#Align the sequences with mothur
mothur "#align.seqs(template=${FALIGN},candidate=${UNIQUE2}.fa)"

if [[ -s ${UNIQUE2}.align ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE2}.align is empty; stopped program after mothur:align.seqs" ;
exit;
fi ;

#make the distance matrix from the aligned sequences
FastTree -nt -makematrix ${UNIQUE2}.align > ${UNIQUE2}.dst

if [[ -s ${UNIQUE2}.dst ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE2}.dst is empty; stopped program after FastTree" ;
exit;
fi ;

FastTree -nt -makematrix ${UNIQUE2}.fa > ${UNIQUE2}.unaligned.dst

if [[ -s ${UNIQUE2}.unaligned.dst ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE2}.unaligned.dst is empty; stopped program after FastTree" ;
exit;
fi ;

perl ${BIN}/${ERRORPROGRAM} -d ${UNIQUE2}.dst,${UNIQUE2}.unaligned.dst -m ${UNIQUE2}.mat -out ${UNIQUE2} -dist ${CUTOFF} ${VARSTRING}

if [[ -s ${UNIQUE2}.err ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE2}.err is empty; stopped program after ${ERRORPROGRAM}" ;
exit;
fi ;

rm ${UNIQUE2}.R_file.chi
rm ${UNIQUE2}.R_file.chisim
rm ${UNIQUE2}.R_file.err
rm ${UNIQUE2}.R_file.fis
rm ${UNIQUE2}.R_file.fisp
rm ${UNIQUE2}.R_file.in
rm ${UNIQUE2}.R_file.lic
if [[ $CLEAN ]] ; then
    rm ${UNIQUE2}.dst
    rm ${UNIQUE2}.align
    rm ${UNIQUE2}.align.report
    rm ${UNIQUE2}.unaligned.dst
    rm ${UNIQUE2}.mat
    rm ${UNIQUE2}.fa
fi ;