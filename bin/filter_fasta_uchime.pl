#! /usr/bin/perl -w

die "Usage: uchime fa > redirect\n" unless (@ARGV);
($uchime, $fasta) = (@ARGV);
chomp ($uchime);
chomp ($fasta);

open (IN, "<$uchime" ) or die "Can't open $uchime\n";
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    next if ($line=~/Y$/);
    ($number, $OTUplus, @pieces)=split ("\t", $line);
    ($OTU)=$OTUplus=~/^(.+)\/ab=/;
    $hash{$OTU}++;
}
close (IN);

$/=">";
open (IN, "<$fasta" ) or die "Can't open $fasta\n";
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    ($OTUplus, @pieces)=split ("\n", $line);
    if ($OTUplus=~/^(.+)\/ab=/){
	($OTU)=$OTUplus=~/^(.+)\/ab=/;
    } else {
	($OTU)=$OTUplus;
    }
    if ($hash{$OTU}){
	($sequence)=join("", @pieces);
	print ">${OTU}\n$sequence\n";
    }
}
close (IN);

