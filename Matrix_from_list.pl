#! /usr/bin/perl -w

die "Use this to  make a matrix from an OTU list
Usage: matfile_with_all_seqeunces otulist > redirect_output\n" unless (@ARGV);

($mat, $otulist)=(@ARGV);
chomp ($mat);
chomp ($otulist);

die "Please follow command line arg\n" unless ($otulist);

open (IN, "<$mat" ) or die "Can't open $mat\n";
$first=1;
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    ($oldOTU, @p)=split ("\t", $line);
    if ($oldOTU=~/^(ID.+M)/){
	($OTU)=$oldOTU=~/^(ID.+M)/;
    } else {
	$OTU=$oldOTU;
    }
    if ($first){
        (@headers)=(@p);
        $first=();
    } else {
        $i=0;
        $j=@p;
        until ($i >=$j){
            $mathash{$OTU}{$headers[$i]}=$p[$i];
	    $mathashgot{$OTU}{$headers[$i]}++;
            $i++;
        }
    }
}
close (IN);

open (IN, "<$otulist" ) or die "Can't open $otulist\n";
$first=1;
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    (@groups)=split ("\t", $line);
    ($OTUname)=$groups[0];
    foreach $name (@groups){
	#now get the overall distribution from the mathash
	foreach $head (@headers){
	    if ($mathashgot{$name}{$head}){
		$finalhash{$OTUname}{$head}+=$mathash{$name}{$head};
	    } else {
		die "Missing $name from mathash\n";
	    }
	}
    }
}
close (IN);

print "OTU";
foreach $head (@headers){
    print "\t$head";
}
print "\n";

foreach $OTU (sort keys %finalhash){
    print "$OTU";
    foreach $head (@headers){
	print "\t$finalhash{$OTU}{$head}";
    }
    print "\n";
}
