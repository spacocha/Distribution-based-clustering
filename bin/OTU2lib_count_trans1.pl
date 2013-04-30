#! /usr/bin/perl -w
#
#

	die "Use this program to take the qiime split_libraries_astq.py fasta and make a matrix
Usage: trans cutoff > Redirect\n" unless (@ARGV);
	($file1, $cutoff) = (@ARGV);
	die "Please follow command line args\n" unless ($file1);
chomp ($file1);
chomp ($cutoff);

open (IN, "<${file1}") or die "Can't open ${file1}\n";
while ($line=<IN>){
    chomp ($line);
    next unless ($line);
    #remove if it was removed at any step of the process
    next if ($line=~/remove/);
    ($name, $OTU)=split ("\t", $line);
    if ($name=~/^.+_[0-9]+ /){
	($lib)=$name=~/^(.+?)_[0-9]+ /;
	$alllib{$lib}++;
	$OTUhash{$OTU}{$lib}++;
	$cutoffhash{$OTU}++;
    } else {
	die "Don't recognize the lib in the name $name\n";
    }
}
close (IN);

foreach $OTU (sort keys%OTUhash){
    print "OTU";
    foreach $lib (sort keys %alllib){
	print "\t$lib";
    }
    print "\n";
    last;
}

foreach $OTU (sort keys %OTUhash){
    next unless ($cutoffhash{$OTU}>=$cutoff);
    print "$OTU";
    foreach $lib (sort keys %alllib){
	if ($OTUhash{$OTU}{$lib}){
	    print "\t$OTUhash{$OTU}{$lib}";
	} else {
	    print "\t0";
	}
    }
    print "\n";
}
