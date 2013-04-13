#! /usr/bin/perl
#
#

die dieHelp () unless (@ARGV); 

$j=@ARGV;
$i=0;

until ($i >= $j){
    $k=$i+1;
    if ($ARGV[$i] eq "-f"){
	$file1=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-q"){
	$file2=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-out"){
	$output=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-len"){
	$barlen=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-change"){
	$change=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-m"){
	$input=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-fq"){
	$fq=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-h" || $ARGV[$i] eq "--help" || $ARGV[$i] eq "-help"){
	exit dieHelp ();
    }
    $i++;
}

	die dieHelp () unless ($output && $file1 && $file2 && $input);
chomp ($file1);
chomp ($file2);
chomp ($input);
chomp ($output);
chomp ($barlen);
chomp ($change);
chomp ($fq) if ($fq);
$barlen=8 unless ($barlen);
$change="n" unless ($change);
$fq=60 unless ($fq);

open (IN, "<${input}") or die "Can't open $input\n";
while ($line=<IN>){
    next unless ($line=~/^barcode/);
    ($type, $barseq, $outname) = split ("\t", $line);
    #make a check of the forward barcode seq
    if ($change=~/[Yy]/){
	($rc_seq)=$barseq;
	($rev)=revcomp($rc_seq);
	$hash{$rev}=$barseq;
    } else {
	$hash{$barseq}=$barseq;
    }
}
close (IN);
#make fake barcode seq
$i=0;
$fakestring=();
until ($i >=$barlen){
    if ($fakestring){
	$fakestring="$fakestring"."N";
	$fakequal="$fakequal"." $fq";
    } else {
	$fakestring="N";
	$fakequal="$fq";
    }
    $i++;
}

$/=">";

open (IN1, "<${file1}") or die "Can't open $file1\n";
open (FA, ">${output}.fasta") or die "Can't open ${output}.fasta\n";
while ($line1=<IN1>){
    chomp ($line1);
    next unless ($line1);
    ($header1, @seqs)=split("\n", $line1);
    ($sequence)=join ("", @seqs);
    ($barseq)=$header1=~/\#([A-z]{$barlen})/;
    if ($hash{$barseq}){
	print FA ">$header1\n${hash{$barseq}}${sequence}\n";
    } else {
	print FA ">$header1\n${fakestring}${sequence}\n";
    }
}
close (IN1);
close (FA);

open (IN1, "<${file2}") or die "Can't open $file2\n";
open (QUAL, ">${output}.qual") or die "Can't open ${output}.qual\n";
while ($line1=<IN1>){
    chomp ($line1);
    next unless ($line1);
    ($header1, @seqs)=split("\n", $line1);
    print QUAL ">$header1\n$fakequal ";
    foreach $thing (@seqs){
	print QUAL "${thing}\n";
    }

}
close (IN1);
close (QUAL);

sub revcomp{
    (@pieces) = split ("", ${rc_seq});
    #make reverse complement
    $j = @pieces;
    $j-=1;
    $seq = ();
    until ($j < 0){
	if ($pieces[$j]){
	    if ($pieces[$j] eq "A"){
		$seq = "$seq"."T";
	    } elsif ($pieces[$j] eq "T"){
		$seq = "$seq"."A";
	    } elsif ($pieces[$j] eq "C"){
		$seq = "$seq"."G";
	    } elsif ($pieces[$j] eq "G"){
		$seq = "$seq"."C";
	    } elsif ($pieces[$j] eq "N"){
		$seq = "$seq"."N";
	    } else {
		die "What is this (reverse complement): $pieces[$j] $rc_seq $j\n";
	    }
	} else {
	    die "NO j $j\n";
	}
	$j-=1;
    }
    return ($seq);
}

sub dieHelp {
    $programname="adjust_fasta_mothur.pl";
    die "Usage: perl $programname -f fasta.file -q qual.file -out output_prefix -m oligo_file -len 8 -change y

Order unimportant

Synopsis: Use this program to adjust a fasta and qual file from Illumina with the indexing sequence in the file name for use in mothur SOP
Options:
    -f fasta_file          A fasta file to be changed (required)
    -q qual_file           A qual file corresponding to the fasta file to be changed (required)
    -out                   The output prefix which will be used to generate the .fa and .qual files (required)
    -m oligo_file          The oligo file used by mothur for indexing (required)
    -len number            Number of bases in the indexing sequence in the header after \# (regex expression \#{number}) (optional default=8)
    -change y/n            Change the orientation of the barcode to reverse complement (optional default=y)
    -fq number             The fake quality score to be given to the indexing bases (optional default=60)
\n";
}
