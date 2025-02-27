#! /usr/bin/perl -w
#
#	Use this program to make tab files for FileMaker
#

	die "Use this program to truncate sequences starting from the beginning spanning the input length
Usage: input_file size output_prefix

Example:
perl truncate_fasta.pl file.fa 76 file.trunc

The order is important, no flags needed
Input must be a fasta file
e.g.
>Seq1
AGTCGATCGATCG
>Seq2
ACTTGACTGATCG

\n" unless (@ARGV);
	

($file, $size, $output) = (@ARGV);
chomp ($file);
chomp ($size);
chomp ($output);
$faoutput="${output}.${size}.fa";
$logoutput="${output}.${size}.log";
if (-e ${faoutput}){
    die "Please provide unique name for prefix. ${output}.${size}.fa exists.\n";
} else {
    open (FA, ">${output}.${size}.fa") or die "Can't open output file ${output}.${size}.fa\n";
}

if  (-e ${logoutput}){
    die "Please provide unique name for prefix. ${output}.${size}.log exists\n";
} else {
    open (LOG, ">${output}.${size}.log") or die "Can't open output file ${output}.${size}.log\n";
    print LOG "The following sequences were removed due to short length\n";
}
    $/ = ">";
open (IN, "<$file") or die "Can't open file for processing: $file\n";
while ($line1 = <IN>){	
    chomp ($line1);
    next unless ($line1);
    $sequence = ();
    (@pieces) = split ("\n", $line1);
    ($info) = shift (@pieces);
    
    ($sequence) = join ("", @pieces);
    $sequence =~tr/\n//d;
    ($new) = $sequence=~/^(.{$size})/;
    if ($new){
	print FA">$info\n$new\n";
    } else {
	print  LOG "Discarded, not long enough: $sequence\n";
    }
    
}

close (IN);

	
