#! /usr/bin/perl -w
#
#	Use this program to make tab files for FileMaker
#

	die "Use this program to truncate sequences starting from the beginning spanning the input length
Usage: <input_file> <size> <output_prefix>\n" unless (@ARGV);
	

	($file, $size, $output) = (@ARGV);
chomp ($file);
chomp ($size);
chomp ($output);

	$/ = ">";
open (IN, "<$file") or die "Can't open $file\n";
open (OUT, ">${output}.fa") or die "Can't open ${output}.fa\n";
open (FAIL, ">${output}.fail") or die "Can't open ${output}.fail\n";
while ($line1 = <IN>){	
    chomp ($line1);
    next unless ($line1);
    $sequence = ();
    (@pieces) = split ("\n", $line1);
    ($info) = shift (@pieces);

    ($sequence) = join ("", @pieces);
    $sequence =~tr/\n//d;
    ($new) = $sequence=~/^(.{$size})/;
    if ($new){
	print OUT ">$info\n$new\n";
    } else {
	(@bases)=split("", $sequence);
	$len=@bases;
	print FAIL "$info\tDid not have sufficient length $len\n";
    }
    
}

close (IN);

	
