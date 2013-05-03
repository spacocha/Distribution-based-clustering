#! /usr/bin/perl
#
#

	die "Usage: <ab.fa> <list> > redirect\n" unless (@ARGV);
	($file1, $file2) = (@ARGV);

	die "Please follow command line args\n" unless ($file2);
chomp ($file1);
chomp ($file2);

$/=">";
open (IN1, "<$file1") or die "Can't open $file1\n";
while ($line1=<IN1>){
    chomp ($line1);
    next unless ($line1);
    ($longname, @seqs)=split("\n", $line1);
    ($sequence)=join ("", @seqs);
    if ($longname=~/^.+\/ab=[0-9]+\/$/){
	($shortname, $abund)=$longname=~/^(.+)\/ab=([0-9]+)\/$/;
	$hash{$shortname}=$abund;
	$seqhash{$shortname}=$sequence;
    } else {
	die "Must have abundance in the title abundance (e.g. /ab=934/) $longname\n";
    }
}
close (IN1);

$/="\n";
$first=1;
open (IN1, "<$file2") or die "Can't open $file2\n";
while ($line1=<IN1>){
    chomp ($line1);
    next unless ($line1);
    if ($type=~/[Qq]/){
	($parent, @rest)=split("\t", $line1);
    } else {
	(@rest)=split("\t", $line1);
    }
    #find the most abundant 
    $mostabund=0;
    $rep=();
    foreach $iso (@rest){
	if ($hash{$iso}){
	    if ($hash{$iso} >=$mostabund){
		$rep=$iso;
	    }
	}
    }
    if ($type=~/[Qq]/){
	print ">$parent\n$seqhash{$rep}\n";
    } else {
	print ">$rest[0]\n$seqhash{$rep}\n";
    }
}
close (IN1);
