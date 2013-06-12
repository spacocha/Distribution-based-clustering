#! /usr/bin/perl -w
#
#	Use this program as part of the eOTU pipeline
#

$programname="create_parallel_files.pl";

	die "Input the following:
full_list- file name of the complete OTU list
fasta- full fasta file with sequences and names that match those in the list
output_prefix- what the output files will begin with

Usage: full_list full_fasta full_mat UNIQUE AFTER\n" unless (@ARGV);
	
	chomp (@ARGV);
	($full_list,  $fullfasta, $fullmat, $UNIQUE, $AFTER) = (@ARGV);
die "$programname: Please follow the command line arguments\n" unless ($AFTER);

chomp ($full_list);
chomp ($fullfasta);
chomp ($fullmat);
chomp ($UNIQUE);
chomp ($AFTER);

#read in the list file and capture the OTU on the right line according to the lineno
$curline=0;
open (IN, "<${full_list}") or die "Can't open ${full_list}\n";
while ($line1 = <IN>){
    chomp ($line1);
    $curline++;
    $allotunum{$curline}++;
    $checkmatfile="${UNIQUE}.${curline}.${AFTER}.mat";
    die "Please provide a unique name. ${checkmatfile} exists\n" if (-e ${checkmatfile});
    $checkfafile="${UNIQUE}.${curline}.${AFTER}.fa";
    die "Please provide a unique name. ${checkfafile} exists\n" if (-e ${checkfafile});

    (@pieces) = split ("\t", $line1);
    foreach $piece (@pieces){
	$otuhash{$piece}=$curline;
    }
}
close (IN);

die "list_through_filter_from_mat.pl:Missing OTUhash\n" unless (%otuhash);
#reminder info: %otuhash contains all of the OTUs that we want to evaluate
#nothing else should be retained

#change the line breaks to > for fasta format
$/ = ">";

#read in the full fasta file
open (IN, "<$fullfasta") or die "Can't open $fullfasta\n";
while ($line1 = <IN>){	
    chomp ($line1);
    next unless ($line1);
    $sequence = ();
    (@pieces) = split ("\n", $line1);
    ($info) = shift (@pieces);
    #filter out all of the other entries
    #merge the sequences from different lines
    ($sequence) = join ("", @pieces);
    #makes ure they don't contain the line breaks
    $sequence =~tr/\n//d;
    #store sequence infor for later processing
    if ($otuhash{$info}){
	($otunum)=$otuhash{$info};
	open (FA, ">>${UNIQUE}.${otunum}.${AFTER}.fa") or die "Can't open ${UNIQUE}.${otunum}.${AFTER}.fa";
	print FA ">$info\n$sequence\n";
	close (FA);
    }
}

close (IN);


#change back the line breaks
$/="\n";

open (IN, "<${fullmat}") or die "Can't open ${fullmat}\n";
while ($line=<IN>){
    chomp ($line);
    next unless ($line);
    ($first, @pieces)=split ("\t", $line);
    if (@headers){
	#print the data to the filehandle associated with each on
	($num)=$otuhash{$first};
	if ($num){
	    open (MAT, ">>${UNIQUE}.${num}.${AFTER}.mat") or die "Can't open ${UNIQUE}.${num}.${AFTER}.mat\n";
	    print MAT "$first";
	    foreach $piece (@pieces){
		print MAT "\t$piece";
	    }
	    print MAT "\n";
	    close (MAT);
	}
    } else {
	foreach $num (keys %allotunum){
	    open (MAT, ">>${UNIQUE}.${num}.${AFTER}.mat") or die "Can't open ${UNIQUE}.${num}.${AFTER}.mat\n";
	    print MAT "$first";
	    foreach $piece (@pieces){
		print MAT "\t$piece";
	    }
	    print MAT"\n";
	    close (MAT);
	}
	(@headers)=@pieces;
    }
}
close (IN);

