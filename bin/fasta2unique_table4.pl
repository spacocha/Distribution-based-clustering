 #! /usr/bin/perl -w
#
#	Use this program to make tab files for FileMaker
#

	die "Usage: <input_files sep by comma> output_prefix\n" unless (@ARGV);
	
($files, $output) = (@ARGV);
die "Please follow command line args\n" unless ($output);
chomp ($files);
chomp ($output);
$/ = ">";
open (TRANS, ">${output}.trans") or die "Can't open ${output}.trans\n";
open (FA, ">${output}.fa") or die "Can't open ${output}.fa\n";

(@filearray)=split (",", $files);
foreach $file (@filearray){
    open (IN, "<$file") or die "Can't open $file\n";
    $OTUc=1;
    while ($line1 = <IN>){	
	chomp ($line1);
	next unless ($line1);
	$sequence = ();
	(@pieces) = split ("\n", $line1);
	($info) = shift (@pieces);
	($sequence) = join ("", @pieces);
	$sequence =~tr/\n//d;
	$sequence =~tr/U/T/d;
	if ($hash{$sequence}){
	    #it already exists, so just output to table
	    #check which lib
	    print TRANS "$info\t$hash{$sequence}\n";
	} else {
	    (@piecesc) = split ("", $OTUc);
	    $these = @piecesc;
	    $zerono = 7 - $these;
	    $zerolet = "0";
	    $zeros = $zerolet x $zerono;
	    $OTUn="ID${zeros}${OTUc}M";
	    $OTUc++;
	    $hash{$sequence}=$OTUn;
	    print TRANS "${info}\t$hash{$sequence}\n";
	    print FA ">$hash{$sequence}\n$sequence\n";
	}
	
    }
    
    close (IN);
}

close (FA);
close (TRANS);
