#! /usr/bin/perl -w

die "Use this program to evaulate the find_seq_errors.pl 
Be in a folder where you ran make_it_go

Usage: vars_files output_prefix\n" unless (@ARGV);
($vars, $output)=(@ARGV);
chomp ($vars);
chomp ($output);
die "Please follow command line options\n" unless ($output);

open (LOG, ">${output}.log") or die "Can't open ${output}.log\n";
open (RESUB, ">${output}.resubmit") or die "Can't open ${output}.resubmit\n";
open (MISS, ">${output}.missing") or die "Can't open ${output}.missing\n";


open (IN, "<$vars" ) or die "Can't open $vars\n";
while ($line=<IN>){
    chomp ($line);
    #get the PCLUSTOUTPUT name so you can check to see how many there are supposed to be
    if ($line=~/UNIQUE=/){
	($UNIQUE)=$line=~/UNIQUE=(.+)$/;
	print LOG "UNIQUE $UNIQUE\n";
    }
    if ($line=~/FNUMBER=/){
	($FNUMBER)=$line=~/FNUMBER=(.+)$/;
	print LOG "FNUMBER $FNUMBER\n";
    }
    if ($line=~/EOTUFILE=/){
	($EOTUFILE)=$line=~/EOTUFILE=(.+)$/;
	print LOG "EOTUFILE $EOTUFILE\n";
    }
    if ($line=~/AFTER=/){
        ($AFTER)=$line=~/AFTER=(.+)$/;
        print LOG "AFTER $AFTER\n";
    }
}

close (IN);

${PCLUSTOUTPUT}="${UNIQUE}.PC.final.list";
#look for the number of lines in the PCLUSTOUTPUT

if (-e $PCLUSTOUTPUT){
    $totlines=`cat $PCLUSTOUTPUT | wc -l`;
    chomp ($totlines);
    print LOG "Looking for $totlines of each file type\n";
} else {
    die "EVAL WARNING: Did not generate the PCLUSTOUTPUT $PCLUSTOUTPUT
EVAL ACTION: Start from the ProgressiveClustering program to generate this file\n";
}
#Looking for the error files
@errfiles = `ls ${UNIQUE}.*.${AFTER}.err`;
chomp (@errfiles);
$numbererrs = @errfiles;
chomp ($numbererrs);
if ($numbererrs == $totlines){
    print LOG "All of the $totlines of error files (${UNIQUE}.*.${AFTER}.err) were created\n";
} else {
    print LOG "EVAL WARNING: Missing some error files: $numbererrs out of $totlines were created
EVAL ACTION: Rerun distribution with the following lines:\n";
    $filetype = "error files";
    ($result) = printmissingno ($totlines, $filetype);
}
print LOG "Evaluating how many of the $numbererrs are finished\n";
foreach $f (@errfiles){
    chomp ($f);
    $finished= `cat $f | grep "Finished"`;
    chomp ($finished);
    $unfin=0;
    unless ($finished){
	print LOG "EVAL WARNING:${f} did not finish\n";
# Finish this so that it will resubmit the error programs
	($tnum)=$f=~/${UNIQUE}\.([0-9]+)\.${AFTER}.err/;
	die "evalulate_parallele_results.pl: Missing process num from regex (can not be 0): Process $tnum File: $f\n" unless ($tnum);
	print RESUB "$tnum\n";
	$unfin++;
    }
}
print LOG "All of the error files finished\n" unless ($unfin);

#look too see whether files were generated
@logfiles = `ls ${UNIQUE}.*.${AFTER}.log`;
$numberlogs = @logfiles;
if ($numberlogs == $totlines){
    print LOG "All of the $totlines of log files (${UNIQUE}.*.${AFTER}.log) were created\n";
} else {
    print LOG "EVAL WARNING: Not all of the log files were created\n";
}
$warning=();
foreach $file (@logfiles){
    $result=`cat ${file}`;
    if ($result=~/WARN/){
	print LOG "There was at least one  WARNING in ${file}, check to see what the warning is\n";
	$warning++;
	($tnum)=$file=~/^${UNIQUE}\.([0-9]+)\.${AFTER}/;
	print MISS "$tnum\n";
    }
}
print LOG "There were no WARNINGs\n" unless ($warning);

sub printmissingno {

    my ($total, $filetype)= @_;
    my ($f);
    my ($i);
    my (%gothash);
    my ($done);
    %gothash=();
    $done=0;

    if ($filetype eq "error files"){
	foreach $f (@errfiles){
	    chomp ($f);
	    next unless ($f=~/${UNIQUE}\.*\.${AFTER}/);
	    ($process)=${f}=~/${UNIQUE}\.([0-9]+)\.${AFTER}/;
	    die "evaluate_parallel_results.pl: Can not find process no from regex (can not be 0) File: $f Process: $process\n" unless ($process);
	    $gothash{$process}++;
	}
	$i=1;
	if ($total){
	    until ($i >$total){
		print MISS "\$i\n" unless ($gothash{$i});
		print LOG "Missing $i\t$filetype\n" unless ($gothash{$i});
		$i++;
	    }
	    $done++;
	    return ($done);
	} else {
	    die "evaluate_parallel_results.pl: Missing the total number of processes to find $total\n";
	}
    }
}
