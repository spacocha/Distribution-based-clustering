#! /usr/bin/perl
#
#

	die "Usage: list mockhit trans > redirect\n" unless (@ARGV);
	($list, $file1, $trans) = (@ARGV);

	die "Please follow command line args\n" unless ($file1);
chomp ($file1);
chomp ($list);
chomp ($trans);
$verbose=();
open (IN1, "<$trans") or die "Can't open $trans\n";
while ($line1=<IN1>){
    chomp ($line1);
    next unless ($line1);
    ($name, $unique)=split ("\t", $line1);
    $allids{$unique}++;
    $abhash{$unique}++;
    ($shortname)=$name=~/^(.+_[0-9]+) /;
    $uniquehash{$shortname}=$unique;
    print "unique $file1: unique ${unique}\tshrt ${shortname}\tuniquehash $uniquehash{$shortname}\n" if ($verbose);
}
close (IN1);

open (IN1, "<$file1") or die "Can't open $file1\n";
while ($line1=<IN1>){
    chomp ($line);
    next unless ($line1);
    ($unique, $mocks, $dist)=split ("\t", $line1);
    (@mockarray)=split (",", $mocks);
    foreach $mock (@mockarray){
	$besthash{$unique}{$mock}++;
	print "$file1: $unique\t$mock\n" if ($verbose);
    }
}
close (IN1);


open (IN, "<$list") or die "Can't open $list\n";
while ($line=<IN>){
    chomp ($line);
    next unless ($line);
    (@pieces)=split ("\t",$line);
    $id=$pieces[0];
    foreach $seq (@pieces){
	if ($uniquehash{$seq}){
	    $trans=$uniquehash{$seq};
	    if ($otuhash{$trans}){
		#this seq present in this hash already
		unless ($otuhash{$trans} eq $id){
		    die "Same seq in different OTUs seq $seq id $id hash $otuhash{$trans} trans $trans\n";
		}
	    } else {
		$otuhash{$trans}=$id;
	    }
	    print "otuhash\t$seq\t$id\t$trans\n" if ($verbose);
	} else {
	    die "Missing unique $seq $uniquehash{$seq}\n";
	}
    }
}
close (IN);

foreach $id (sort keys %allids){
    foreach $oid (sort keys %allids){
	next if ($id eq $oid);
	next if ($done{$id}{$oid});
	$done{$id}{$oid}++;
	$done{$oid}{$id}++;
	$addval=$abhash{$id}*$abhash{$oid};
	if (%{$besthash{$id}} && %{$besthash{$oid}}){
	    #both have best blast hit, so consider in the analysis
	    if ($otuhash{$id} && $otuhash{$oid}){
		#both have otu info so consider in analysis
		if ($otuhash{$id} eq $otuhash{$oid}){
		    #they are in the same otu
		    $gotaTP=();
		    foreach $mock (keys %{$besthash{$id}}){
			if ($besthash{$oid}{$mock}){
			    unless ($gotaTP){
				print "I'm a TP $id $oid\n" if ($verbose);
				$TP+=$addval;
				$gotaTP++;
			    }
			}
		    }
		    unless ($gotaTP){
			print "I'm a FP $id\t$oid\n" if ($verbose);
			#it is a true positive
			#it's a false positive
			$FP+=$addval;
		    }
		} else {
		    $gotaFN=();
                    foreach $mock (keys %{$besthash{$id}}){
			if ($besthash{$oid}{$mock}){
                            unless ($gotaFN){
				print "I'm a FN $id $oid\n" if ($verbose);
                                $FN+=$addval;
                                $gotaFN++;
                            }
                        }
                    }
		    unless ($gotaFN){
			#they are in the same OTU but are different mock
			#false positive
			print "I'm a TN $id\t$oid\n" if ($verbose);
			$TN+=$addval;
		    }
		}
	    } else {
		$FN+=$addval;
	    }
	}
    }
}

print "TP\t$TP
FP\t$FP
TN\t$TN
FN\t$FN\n";
