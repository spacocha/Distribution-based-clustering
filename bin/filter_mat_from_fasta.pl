#! /usr/bin/perl -w

die "Usage: mat fasta > Redicted\n" unless (@ARGV);
($mat, $new) = (@ARGV);
chomp ($new);
chomp ($mat);

$/=">";

open (IN, "<$new" ) or die "Can't open $new\n";
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    ($info, @seqs) = split ("\n", $line);
#    if ($info=~/^.+\_[0-9]+$/){
#	($OTU)=$info=~/^(.+)\_[0-9]+$/;
#    } elsif ($info=~/^.+\/ab=[0-9]+\//){
#	($OTU)=$info=~/^(.+)\/ab=[0-9]+\//;
#    } else {
#	$OTU=$info;
#    }
    $hash{$info}++;
} 
close (IN);

$/="\n";
$first=1;
open (IN, "<$mat" ) or die "Can't open $mat\n";
while ($line =<IN>){
    chomp ($line);
    if ($line=~/\# QIIME/){
	print "$line\n";
    } else {
	next unless ($line);
	($OTU, @pieces)=split ("\t", $line);
	if ($first){
	    #print out headers
	    print "$OTU";
	    foreach $piece (@pieces){
		print "\t$piece";
	    }
	    print "\n";
	    $first=0;
	} else {
	    if ($hash{$OTU}){
		print "$OTU";
		foreach $piece (@pieces){
		    print "\t$piece";
		}
		print "\n";
	    }
	}
    }
}
close(IN);
