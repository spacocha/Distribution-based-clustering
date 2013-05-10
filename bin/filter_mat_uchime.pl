#! /usr/bin/perl -w

die "Usage: uchime mat > redirect\n" unless (@ARGV);
($uchime, $mat) = (@ARGV);
chomp ($mat);
chomp ($uchime);

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

open (IN, "<$mat" ) or die "Can't open $mat\n";
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    ($OTU, @pieces)=split ("\t", $line);
    if (@headers){
	if ($hash{$OTU}){
	    print "$OTU";
	    foreach $piece(@pieces){
		print "\t$piece";
	    }
	    print "\n";
	}
    } else {
	(@headers)=@pieces;
	print "OTU";
	foreach $head (@pieces){
	    print "\t$head";
	}
	print "\n";
    }
}
close (IN);

