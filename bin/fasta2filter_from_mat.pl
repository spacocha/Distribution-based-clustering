#! /usr/bin/perl -w

die "Usage: mat fasta > Redicted\n" unless (@ARGV);
($mat, $new) = (@ARGV);
chomp ($new);
chomp ($mat);

open (IN, "<$mat" ) or die "Can't open $mat\n";
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    ($OTU, @pieces)=split ("\t", $line);
    $hash{$OTU}++;
}
close(IN);

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
	$OTU=$info;
#    }
    if ($hash{$OTU}){
	$seq=join ("", @seqs);
	print ">$OTU\n$seq\n";
    }
} 
close (IN);

