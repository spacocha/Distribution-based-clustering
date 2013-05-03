#! /usr/bin/perl -w
#
#	Use this program to make tab files for FileMaker
#

	die "Usage: mat fasta > redirect\n" unless (@ARGV);
	
	chomp (@ARGV);
	($mat, $file) = (@ARGV);
chomp ($mat);
chomp ($file);
$first=1;
open (IN, "<$mat") or die "Can't open $mat\n";
while ($line1 = <IN>){
    chomp ($line1);
    next unless ($line1);
    ($newinfo, @pieces) = split ("\t", $line1);
    if ($first){
	@headers=@pieces;
	$first=();
    } else {
	$j = @pieces;
	$i=0;
	until ($i>=$j){
	    if ($pieces[$i]=~/^[0-9]+$/){
		$mathash{$newinfo}+=$pieces[$i];
	    } else {
#		print "$headers[$i] was not used for $newinfo\n";
	    }
	    $i++;
	}
    }
}
close (IN);
$/ = ">";
open (IN, "<$file") or die "Can't open $file\n";
while ($line1 = <IN>){	
    chomp ($line1);
    next unless ($line1);
    (@pieces) = split ("\n", $line1);
    ($newinfo) = shift (@pieces);
    ($sequence)=join ("", @pieces);
    $seqhash{$newinfo}=$sequence;
}
	
close (IN);
	
foreach $newinfo (sort {$mathash{$b} <=> $mathash{$a}} keys %mathash){
    print ">${newinfo}/ab=$mathash{$newinfo}/\n$seqhash{$newinfo}\n" if ($seqhash{$newinfo});
}
