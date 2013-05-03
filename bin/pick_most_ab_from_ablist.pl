#! /usr/bin/perl
#
#

	die "Usage: ablist fasta > redirect\n" unless (@ARGV);
	($file1, $file2) = (@ARGV);

	die "Please follow command line args\n" unless ($file1);
chomp ($file1);
chomp ($file2);

$/=">";
open (IN1, "<$file2") or die "Can't open $file2\n";
while ($line1=<IN1>){
    chomp ($line1);
    next unless ($line1);
    ($id, @seqs)=split ("\n", $line1);
    ($sequence)=join ("", @seqs);
    $hash{$id}=$sequence;
}
close (IN);

$/="\n";
open (IN1, "<$file1") or die "Can't open $file1\n";
while ($line1=<IN1>){
    chomp ($line1);
    next unless ($line1);
    ($id, @seqs)=split ("\t", $line1);
    $highval=();
    $highseq=();
    foreach $piece (@seqs){
	($unique, $ab)=$piece=~/^(.+)\/ab=([0-9]+)\//;
	if ($ab>$highval){
	    $highval=$ab;
	    $highseq=$unique;
	}
    }
    if ($hash{$highseq}){
	print ">$id\n$hash{$highseq}\n";
    } else {
	die "Missing $highseq\n";
    }
}
close (IN1);
