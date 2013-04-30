#! /usr/bin/perl -w
#
#	Use this program to make tab files for FileMaker
#

	die "Use this program to truncate sequences starting from the beginning spanning the input length
Usage: <input_file> <size> > Redirect output\n" unless (@ARGV);
	

	($file, $size) = (@ARGV);
chomp ($file);
chomp ($size);

	$/ = ">";
	open (IN, "<$file") or die "Can't open $file\n";
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
		    print ">$info\n$new\n";
		} else {
		    die "SEQ $sequence NEW $new\n";
		}

	}
	
	close (IN);

	
