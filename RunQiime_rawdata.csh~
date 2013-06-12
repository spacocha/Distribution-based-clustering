#! /bin/sh
#$ -S /bin/bash
# -cwd

source /etc/profile.d/modules.sh
module load qiime-default
module load mothur

#you should include the variables file after the RunQiime_rawdata.csh command, which is included here
. ./$1

if [[ -s ${SOLFILEF} ]] ; then
NULLVAR=0
else
echo "PipeStop error:${SOLFILEF} doesn't exist. Please include a real fastq file" ;
exit;
fi ;

#Make a fake barcode read from the header file to use with split_libraries_fastq.py
perl ${BIN}/fastq2Qiime_barcode.pl ${SOLFILEF} > ${UNIQUE}_bar.txt

if [[ -s ${UNIQUE}_bar.txt ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE}_bar.txt is empty; stopped program after ${BIN}/fastq2Qiime_barcode.pl" ;
exit;
fi ;

#Split your fastq file with qiime
split_libraries_fastq.py -i ${SOLFILEF} -b ${UNIQUE}_bar.txt -o ${UNIQUE}_output -m ${MAPFILE} --barcode_type ${BARLEN} --min_per_read_length ${MINLEN} --last_bad_quality_char ${QUAL} --max_barcode_errors 0 --max_bad_run_length ${BADRUN} ${SLV}

if [[ -s ${UNIQUE}_output/seqs.fna ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE}_output/seqs.fna is empty; stopped program after split_libraries_fastq.py" ;
exit;
fi ;

#Trim the sequences with mothur
mothur "#trim.seqs(fasta=${UNIQUE}_output/seqs.fna, oligos=${OLIGO})"

if [[ -s ${UNIQUE}_output/seqs.trim.fasta ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE}_output/seqs.trim.fasta is empty; stopped program after trim.seqs" ;
exit;
fi ;

#revert the names from mothur to qiime names
perl ${BIN}/revert_names_mothur3.pl ${UNIQUE}_output/seqs.fna ${UNIQUE}_output/seqs.trim.fasta > ${UNIQUE}_output/seqs.trim.names.fasta

if [[ -s ${UNIQUE}_output/seqs.trim.names.fasta ]] ; then
NULLVAR=0
else
echo "PipeStop error:${UNIQUE}_output/seqs.trim.names.fasta is empty; stopped program after ${BIN}/revert_names_mothur3.pl" ;
exit;
fi ;


perl ${BIN}/truncate_fasta2.pl ${UNIQUE}_output/seqs.trim.names.fasta ${TRIM} ${UNIQUE}_output/seqs.trim.names.${TRIM}

