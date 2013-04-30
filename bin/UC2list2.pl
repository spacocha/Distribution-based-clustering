#! /usr/bin/perl -w
#
#


die "Usage: UC_file > output\n" unless (@ARGV);
	($file1) = (@ARGV);

	die "Please follow command line args\n" unless ($file1);
chomp ($file1);

open (IN, "<$file1") or die "Can't open $file1\n";
$seedcount=0;
while ($line=<IN>){
    chomp ($line);
    next unless ($line);
    next if ($line=~/^\#/);
    ($type, $seed, $len, $one, $two, $three, $four, $five, $name, $seedname)=split ("\t", $line);
    if ($name=~/\/ab=/){
	($newname)=$name=~/^(.+)\/ab=/;
	$name=$newname;
    }
    if ($seedname=~/\/ab=/){
	($newseedname)=$seedname=~/^(.+)\/ab=/;
	$seedname=$newseedname;
    }
    if ($type eq "H"){
	push (@{$uchash{$seedname}}, $name);
    } elsif ($type eq "S"){
	$seedname=$name;
	push (@{$uchash{$seedname}}, $name);
    }
}
close (IN);

foreach $seedname (sort keys %uchash){
    print "$seedname";
    foreach $name (@{$uchash{$seedname}}){
	next if ($name eq $seedname);
	print "\t$name";
    }
    print "\n";
}
