#! /usr/bin/perl -w

die "Usage: error_file > redirect\n" unless (@ARGV);
($error) = (@ARGV);
chomp ($error);
#make the pvalue hash to use later

#read in the error first with suggestions on which to merge
open (IN, "<$error" ) or die "Can't open $error\n";
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    if ($line=~/^Changefrom,.+,.+,Changeto,/){
	($child, $parent) =$line=~/^Changefrom,(.+?),(.+?),Changeto,/;
	if ($done{$parent}{$child}){
	    die "There's a problem with this $parent $child\n$line";
	}
	$done{$child}{$parent}++;
	die "It's a child and a parent $parent\n" if ($childhash{$parent});
	$hash{$parent}{$child}++;
	$childhash{$child}++;
    }
    if ($line=~/Done testing as child/){
	($ID)=$line=~/^(.+): Done testing as child/;
	$allhash{$ID}++;
    }
}
close (IN);

foreach $OTU (sort keys %allhash){
    next if ($childhash{$OTU});
    print "$OTU";
    if (%{$hash{$parent}}){
	foreach $otherOTU (sort keys %{$hash{$OTU}}){
	    print "\t$otherOTU";
	}
    }
    print "\n";
}
