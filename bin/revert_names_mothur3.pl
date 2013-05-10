#! /usr/bin/perl -w

die "Usage: seqs.fna trimmed_file > redirect\n" unless (@ARGV);
$programname="revert_names_mothur3.pl";

($fasta2, $fasta1) = (@ARGV);
chomp ($fasta1);
chomp ($fasta2);
$/=">";
open (IN1, "<$fasta1" ) or die "Can't open $fasta1\n";
open (IN2, "<$fasta2") or die "Can't open $fasta2\n";
while ($line1 =<IN1>){
    ($line2=<IN2>);
    chomp ($line1);
    chomp ($line2);
    next unless ($line1 || $line2);
    ($OTU1, @pieces1)=split ("\n", $line1);
    ($trimseq)=join ("", @pieces1);
    ($OTU2, @pieces2) =split ("\n", $line2);
    ($shrtOTU2)=$OTU2=~/^(.+?) /;
    if ($OTU1 eq $shrtOTU2){
	print ">$OTU2\n$trimseq\n";
    } else {
	$found=0;
	until ($found){
	    ($line2=<IN2>);
	    chomp ($line2);
	    die "$programname failure:
Something is wrong with $OTU1, no line2 $line2\n" unless ($line2);
	    ($OTU2, @pieces2) =split ("\n", $line2);
	    ($shrtOTU2)=$OTU2=~/^(.+?) /;
	    if ($OTU1 eq $shrtOTU2){
		$found=1;
		print ">$OTU2\n$trimseq\n";
	    }
	}
    }
}

close (IN1);
close (IN2);
