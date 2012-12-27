#! /usr/bin/perl -w
#   Edited on 08/16/12 
#
$programname="find_seq_errors29.pl";

	die dieHelp () unless (@ARGV); 

$j=@ARGV;
$i=0;

until ($i >= $j){
    $k=$i+1;
    if ($ARGV[$i] eq "-d"){
       $distfiles=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-m"){
       $matfile=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-R"){
       $Rfile=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-out"){
       $output=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-log"){
       $logfile = $ARGV[$k];
    } elsif ($ARGV[$i] eq "-old"){
       $oldstats=$ARGV[$k];
    } elsif ($ARGV[$i] eq "-dist"){
       $distcutoff=$ARGV[$k];
       $gotdistcutoff++;
    } elsif ($ARGV[$i] eq "-abund"){
       $abundcutoff=$ARGV[$k];
       $gotabundcutoff++;
    } elsif ($ARGV[$i] eq "-pval"){
       $pvaluecutoff=$ARGV[$k];
       $gotpvaluecutoff++;
   } elsif ($ARGV[$i] eq "-JS"){
       $JScutoff=$ARGV[$k];
       $useJSdiv++;
   } elsif ($ARGV[$i] eq "-verbose"){
       $verbose++;
   } elsif ($ARGV[$i] eq "-h" || $ARGV[$i] eq "--help" || $ARGV[$i] eq "-help"){
       exit dieHelp ();
   }
    $i++;
}
#Terminate program if essential flags are not provided
die "Please follow command line args
Output: ${output}
distfiles:$distfiles
matfile:$matfile
Rfile:$Rfile
logfile:$logfile\n" unless ($output && $distfiles && $matfile && $Rfile && $logfile);
chomp ($distfiles);
chomp ($matfile);
chomp ($Rfile);
chomp ($oldstats) if ($oldstats);
chomp ($output);
chomp ($logfile);

#check requirements: R is required
open (OUT, ">${Rfile}.lic") or die "Can't open ${Rfile}.lic\n";
print OUT "license()\n";
close (OUT);
$licinfo= `R --slave --vanilla --silent < '${Rfile}'.lic`;
unless ($licinfo=~/GNU/){
   die "R module not functional, please make R avaiable by loading the module as such:
module add R/2.12.1
or equivalent before running
$licinfo
 ${Rfile}.lic\n";
}

#write to the log file
open (LOG, ">${logfile}") or die "Can't open ${logfile}\n";
#define your cutoffs
$pvaluecutoff=0.0005 unless ($gotpvaluecutoff);
$distcutoff=0.1 unless ($gotdistcutoff);
$abundcutoff=10 unless ($gotabundcutoff);
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
$isdst="NA";
$wday="NA";
$yday="NA";
$newyear = $year+1900;
$newmonth=$mon+1;
$lt= "$newmonth-$mday-$newyear $hour:$min:$sec";

print LOG "Running: ${programname}
Time started: $lt
Input:$distfiles
Distributions:$matfile
Routput:$Rfile
Pvalue cutoff:$pvaluecutoff
Distance cutoff:${distcutoff}
Abundance cutoff:${abundcutoff}
Output:$output
Old Stats:";
    if ($oldstats){
	print LOG "$oldstats\n";
    } else {
	print LOG "None\n";
    }
print LOG "Verbose:";
if ($verbose){
    print LOG "yes\n";
} else {
    print LOG "no\n";
}

print LOG "R license Info:
$licinfo\n";
print LOG "Use JSdiv: $JScutoff\n" if ($useJSdiv);
#record library distribution data
print "Finished printing to log\n";

#read in old information to continue where the program left off from a previous run
if ($oldstats){
    $init=();
    print LOG "Reading in oldstats file: $oldstats\n" if ($verbose);
    (@oldstatsfiles)=split (",", $oldstats);
    foreach $oldstatsfile (@oldstatsfiles){
	open (IN, "<$oldstatsfile" ) or die "Can't open $oldstatsfile\n";
	while ($line =<IN>){
	    chomp ($line);
	    next unless ($line);
	    if ($line=~/Changefrom,.+,.+,Changeto/){
		($id, $oid)=$line=~/Changefrom,(.+),(.+),Changeto/;
		$parenthash{$oid}++;
		$childhash{$id}++;
	    } elsif ($line=~/Done testing as child/){
		($oid)=$line=~/^(.+): Done testing as child/;
		$donehash{$oid}++;
	    }
	}
	close (IN);
    }
} else {
    $init=1;
}
print "Matfile\n";
print LOG "Reading in matfile file: $matfile\n" if ($verbose);

open (IN, "<$matfile" ) or die "Can't open $matfile\n";
$first=1;
while ($line =<IN>){
    chomp ($line);
    next unless ($line);
    ($OTU, @libs) =split ("\t", $line);
    if ($first){
	$first=();
	(@headers)=@libs;
    } else {
	$i=0;
	$j=@headers;
	$total=0;
	until ($i>=$j){
	    $mathash{$OTU}{$headers[$i]}=$libs[$i] if ($headers[$i]);
	    $matbarhash{$headers[$i]}++ if ($headers[$i]);
	    $total+=$libs[$i];
	    $i++;
	}
	$abundhash{$OTU}=$total;
    }
      
}
close (IN);

print "Done matfile
Distfile\n";

#now parse the distance files
print LOG "Reading in dist files: $distfiles\n" if ($verbose);

(@distarray)=split (",", $distfiles);
foreach $file (@distarray){
    print LOG "Reading in dist file: $file\n" if ($verbose);
    ($answer)=dst2transhash ($file);
    die "Didn't finish transhash\n" unless ($answer eq "Finished");
}

foreach $file (@distarray){
    print LOG "Reading in dist file: $file\n" if ($verbose);
    ($answer)=dst2tab ($file);
    die "Didn't finish distance\n" unless ($answer eq "Finished");
}

print "Done distfile
Open output\n";

open (OUT, ">${output}") or die "Can't open $output\n";

#make the program files that R will use to run the Fisher exact, Chi Square and Correlation tests
makeRexecutables ();

print LOG "Checking for seq errors\n" if ($verbose);
print "Checking for errors\n";
#start the error processing
$init=1;
foreach $oid (sort {$abundhash{$b} <=> $abundhash{$a}} keys %abundhash){
    print LOG "Working on $oid\n" if ($verbose);
    if ($init){
	print LOG "Evaluating mergeall situation: $init\n" if ($verbose);
	#this is the most abundant one, see if it clears the threshold
	#otherwise, if you have singletons, they will all be seperate OTUs
	#because the most abundant one isn't even above the threshold
	if ($abundhash{$oid} < ${abundcutoff}){
	    $mergeall=1;
	    $allparent=$oid;
	    print LOG "All will be merged into $oid\n" if ($verbose); 
	} else {
	    $mergeall=();
	    print LOG "Not under mergeall conditions\n" if ($verbose);
	}
	$init=();
    }
    #in this step we want to find things that are less abundant and look at all of the things that are closely related
    #Take the distribution of chisq values and find the best one
    #next unless ($examplehash{$oid});
    print LOG "Checking for doneness: $oid\n" if ($verbose);
    next if ($parenthash{$oid} || $donehash{$oid});
    print LOG "$oid was not previously done\n" if ($verbose);
    #look for possible parents beginning with the closest relative
    foreach $id (sort {$disthash{$oid}{$a} <=> $disthash{$oid}{$b}} keys %{$disthash{$oid}}){
	#only change to something than or equal to current abundance
	print LOG "$id is the next closest sequence to $oid: $disthash{$oid}{$id}\n" if ($verbose);
	#only evaluate things that have a distance in the file (some files are too long to keep all pairs)
	if ($mergeall){
	    unless ($oid eq $allparent){
		print LOG "Under mergeall assumptions $oid changed to $allparent\n" if ($verbose);
		print OUT "Changefrom,${oid},${allparent},Changeto,DIST,MERGEALL,PVAL,MERGEALL,Done\n";
	    }
	    last;
	} else {
	    #only evaluate things that are at higher abundance, not already changed and not to distant
	    if ($childhash{$id}){
		print LOG "FAILED: $id is already a child\n" if ($verbose);
		next;
	    }
	    #check to see if the alignment is the only thing that is different between these sequences
	    #make a gapless sequence
	    #check if the distributions are the same across libraries
	    $totalnolib=0;
	    $string=();
	    $pvalue=();	
	    foreach $bar (sort keys %matbarhash){
		#don't print, but pass something to R
		$mathash{$oid}{$bar} = 0 unless ($mathash{$oid}{$bar});
		$mathash{$id}{$bar} =0 unless ($mathash{$id}{$bar});
		if ($mathash{$oid}{$bar} || $mathash{$id}{$bar}){
		    if ($string){
			$string="$string"."$mathash{$oid}{$bar}\t$mathash{$id}{$bar}\n";
		    } else {
			$string="$mathash{$oid}{$bar}\t$mathash{$id}{$bar}\n";
		    }
		    $totalnolib++ if ($mathash{$oid}{$bar} || $mathash{$id}{$bar});
		}
	    }
	    $gotpvalue=();
	    $pvalue=();
	    if ($totalnolib ==1){
		print LOG "$oid and $id are only in one library\n" if ($verbose);
		#if they are both only found in one library, combine them
		$pvalue=1;
		$gotpvalue++;
	    } else {
		#run chisq and fishers
		system ("rm ${Rfile}.chip\n") if (-e "${Rfile}.chip");
		system ("rm ${Rfile}.chiexp\n") if (-e "${Rfile}.chiexp");
		system ("rm ${Rfile}.chisimp\n") if (-e "${Rfile}.chisimp");
		$cpvalue=();
		open (INPUT, ">${Rfile}.in") or die "Can't open ${Rfile}.in\n";
		print INPUT "$string\n";
		close (INPUT);
		#now try chisq
		$cpvalue=();
		#Run R from the system command
		#Change this if you want to alter the R call
		system ("R --slave --vanilla --silent < ${Rfile}.chi >> ${Rfile}.err");
		$gotchip=0;
		if (-e "${Rfile}.chip"){
		    $gotchip=1;
		    open (RES, "<${Rfile}.chip") or die "Can't open ${Rfile}.chip\n";
		    while ($Rline=<RES>){
			chomp ($Rline);
			($cpvalue)=$Rline=~/^(.+)/;
		    }
		    close (RES);
		    print LOG "Recording pvalue for $id $oid $cpvalue\n" if ($verbose); 
		    #now get expected
		    @retpie=();
		    if (-e "${Rfile}.chiexp"){
			open (RES, "<${Rfile}.chiexp") or die "Can't open ${Rfile}.chiexp\n";
			while ($Rline=<RES>){
			    chomp ($Rline);
			    next unless ($Rline);
			    push (@retpie, $Rline);
			}
			close (RES);
			$exptot=0;
			$hightot=0;
			foreach $pie (@retpie){
			    if ($pie=~/^(.+)\t(.+)$/){
				($exp1, $exp2)=$pie=~/^(.+)\t(.+)$/;
				if ($exp1 > 5){
				    $hightot++;
				}
				if ($exp2 > 5){
				    $hightot++;
				}
				#print "Add two\n";
				$exptot+=2;
			    } else {
				print LOG "WARNING: Unrecognizable exp format $id $oid\n" if ($verbose);
			    }
			}
			if ($exptot){
			    $expercent=$hightot/$exptot;
			    if ($expercent<0.8){
				#if the expected values are too low
				#then the chisq will be incorrect, simulate pvalue with monte carlo simulation
				print LOG "$expercent value ($hightot over $exptot) is less than the expected 0.8: try to simulate pvalue $id $oid\n" if ($verbose);
				system ("R --slave --vanilla --silent < ${Rfile}.chisim >> ${Rfile}.err");
				if (-e "${Rfile}.chisimp"){
				    print LOG "got chipsimp $id $oid\n" if ($verbose);
				    open (RES, "<${Rfile}.chisimp") or die "Can't open ${Rfile}.chisimp\n";
				    while ($Rline=<RES>){
					chomp ($Rline);
					next unless ($Rline);
					($pvalue)=$Rline=~/^(.+)/;
					$gotpvalue++;
					print LOG "Got pvalue from simulated chisq: $id $oid $pvalue\n" if ($verbose);
				    }
				    close (RES);
				}
			    } elsif ($gotchip){
				#just go with the calculated pvalue
				$pvalue=$cpvalue;
				$gotpvalue++;
				print LOG "Got the calculated pvalue for chisq: $id $oid $pvalue\n" if ($verbose);
			    }
			} else {
			    print LOG "WARNING: Missing the total expected in percent expected calculation for chisq ID: $id OID: $oid\n";
			}
		    } else {
			print LOG "WARNING: Found ${Rfile}.chip but not ${Rfile}.chiexp $id $oid\n";
		    }
		} else {
		    print LOG "Missing results from regular chisq, trying to simulate chisq: $id $oid\n" if ($verbose);
		    system ("R --slave --vanilla --silent < ${Rfile}.chisim >> ${Rfile}.err");
		    if (-e "${Rfile}.chisimp"){
			print LOG "got chipsimp $id $oid\n" if ($verbose);
			open (RES, "<${Rfile}.chisimp") or die "Can't open ${Rfile}.chisimp\n";
			while ($Rline=<RES>){
			    chomp ($Rline);
			    next unless ($Rline);
			    print LOG "Rline chisimp $Rline $id $oid\n" if ($verbose);
			    ($pvalue)=$Rline=~/^(.+)/;
			    $gotpvalue++;
			    print LOG "Got pvalue from simulated chisq: $id $oid $pvalue\n" if ($verbose);
			}
			close (RES);
		    } else {
			print LOG "WARNING: Tried everything and couldn't get a pvalue from $id $oid\n";
			#die "Could not get a pvalue for these: $id $oid\n";
		    }
		}
	    }
	}
	if ($gotpvalue){
	    if ($pvalue > $pvaluecutoff){
		print LOG "pvalue ($pvalue) is larger than the critical pvalue cutoff value ($pvaluecutoff): change $oid to $id\n" if ($verbose); 
		unless ($mergeall){
		    print OUT "Changefrom,$oid,$id,Changeto,DIST,$disthash{$oid}{$id},PVAL,$pvalue,Done\n";
		    #when it's assigned as a parent, don't evalualte as a child                                                                                                                              
		    $parenthash{$id}++;
		    #when it's assigned as a child, don't evaluate as a parent                                                                                                                               
		    $childhash{$oid}++;
		    last;
		}
	    } elsif ($useJSdiv){
		#calculate JSdiv
		print LOG "Checking the JSdiv for $id $oid\n" if ($verbose);
		($JSres) = JS_value ($oid, $id);
		if ($JSres < $JScutoff){
		    print OUT "Changefrom,$oid,$id,Changeto,DIST,$disthash{$oid}{$id},PVAL,$pvalue,JSdiv,$JSres,Done\n";
		    print LOG "JSdiv $JSres is below the cutoff $JScutoff; Change $oid to $id\n" if ($verbose);
		    $parenthash{$id}++;
		    $childhash{$oid}++;
		    last;
		} else {
		    print LOG "JSdiv $JSres is not below the cutoff $JScutoff for $id and $oid\n" if ($verbose);
		}
		
	    }
	} else {
	    print LOG "WARNING: Didn't record a pvalue for $id $oid\n";
	    if ($useJSdiv){
		#calculate JSdiv
		print LOG "Checking the JSdiv for $id $oid\n" if ($verbose);
		($JSres) = JS_value($oid, $id);
		if ($JSres < $JScutoff){
		    print OUT "Changefrom,$oid,$id,Changeto,DIST,$disthash{$oid}{$id},PVAL,Could not calc.,JSdiv,$JSres,Done\n";
		    print LOG "JSdiv is below the JSdiv cutoff $JSres $JScutoff for $id $oid; Changing $oid to $id\n" if ($verbose);
		    $childhash{$oid}++;
		    $parenthash{$id}++;
		    last;
		} else {
		    print LOG "JSdiv is not below the JSdiv cutoff $JSres $JScutoff for $id $oid\n" if ($verbose);
		}
	    }
	}
    }
    
    if ($verbose){
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$isdst="NA";
	$wday="NA";
	$yday="NA";
	$newyear = $year+1900;
	$newmonth=$mon+1;
	$lt= "$newmonth-$mday-$newyear $hour:$min:$sec";
	print LOG "$oid: Done testing as child\n$lt\n";
    }
    print OUT "$oid: Done testing as child\n";
}
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
$isdst="NA";
$wday="NA";
$yday="NA";
$newyear = $year+1900;
$newmonth=$mon+1;
$lt= "$newmonth-$mday-$newyear $hour:$min:$sec";
print LOG "Finished: $lt\n";
print OUT "Finished\n";
close (OUT);
close (LOG);

############
#subroutines
############

sub dst2transhash {
    my ($file) = (@_);
    my ($line);
    my (@pieces);
    my ($isolate);
    chomp ($file);
    $k=0;
    open (IN, "<$file") or die "Can't open $file\n";
    print LOG "Opened $file\n" if ($verbose);
    while ($line=<IN>){
        chomp ($line);
        (@pieces) = split (" ", $line);
        if ($pieces[0] =~/[A-z]/){
            ($isolate) = shift (@pieces);
            $translatehash2{$file}{$k}=$isolate;
            $k++;
        }
    }
    close (IN);
    $result= "Finished";

}

sub dst2tab {
    my ($file) = (@_);
    my ($line);
    my (@pieces);
    my ($isolate);
    chomp ($file);
    $k=0;
    open (IN, "<$file") or die "Can't open $file\n";
    print LOG "Opened $file\n" if ($verbose);
    while ($line=<IN>){
	chomp ($line);
	(@pieces) = split (" ", $line);
	if ($pieces[0] =~/[A-z]/){
	    ($isolate) = shift (@pieces);
	    $j=0;
	    $k++;
	    foreach $distance (@pieces){
		#get the name of the other isolate
		$otheriso=$translatehash2{$file}{$j};
		#other iso are possible parents, only record for otherisos that satisfy criteria
		if ($isolate ne $otheriso && ${abundcutoff}*${abundhash{$isolate}} < $abundhash{$otheriso} && $distance < $distcutoff && ${abundhash{$isolate}} <= $abundhash{$otheriso}){
		    if ($disthash{$isolate}{$otheriso}){
			if ($distance < $disthash{$isolate}{$otheriso}){
			    #only keep the lowest distance
			    $disthash{$isolate}{$otheriso}=$distance;
			}
		    } else {
			$disthash{$isolate}{$otheriso}=$distance;
		    }
		} else {
		    #don't record the distance of anything that is not a possible parent of $isolate
		}
		$j++;
	    }   
	}
    }
    close (IN);
    $result= "Finished";
    return ($result);
}

sub makeRexecutables {
    open (FIS, ">${Rfile}.chi") or die "Can't open ${Rfile}.chi\n";
    print FIS "x <- read.table(\"${Rfile}.in\", header = FALSE)
htest2 <-chisq.test(x)
chip <-htest2\$p.value
chiexp <-htest2\$expected
write.table(chip,file=\"${Rfile}.chip\",sep=\"\t\",row.names=FALSE,col.names=FALSE)
write.table(chiexp,file=\"${Rfile}.chiexp\",sep=\"\t\",row.names=FALSE,col.names=FALSE)\n";
    close (FIS);
    open (FIS, ">${Rfile}.chisim") or die "Can't open ${Rfile}.chisim\n";
    print FIS "x <- read.table(\"${Rfile}.in\", header = FALSE)
htest3 <-chisq.test(x,simulate.p.value = TRUE, B = 10000)
chisimp <-htest3\$p.value
write.table(chisimp,file=\"${Rfile}.chisimp\",sep=\"\t\",row.names=FALSE,col.names=FALSE)\n";
    close (FIS);
}

sub dieHelp {

die "Usage: perl $programname {-d distance_file -m matrix_file -R R_output_prefix -out output.err -log file.log} [options]
Requires the addition of the R module prior to running (i.e. module add R/2.12.1)

{} indicates required input (order unimportant)
[] indicates optional input (order unimportant)

This program is designed to identify sequencing errors and sequences that can not be distinguished from sequencing error in Illumina data.
It identifies sequencing error by looking for a parent for each sequence, starting with the most abundant across libraries in your matrx file.
Parents are sequences that satisfies the following:
1.) The parental abundance is above the defined the abundance threshold
2.) It is within a specific distance cut-off
3.) The parental distribution is not statistically significantly different from the child distribution as determined by fisher (when possible), or chi-sq test above the pvalue threshold

A child is assigned to the most similar (smallest distance) parental sequence that fulfills the above criteria.
Once assigned as a child, a sequence will not be considered as a parent.

Example usage:
perl $programname -d file.dst -m file.mat -R R_file -out output.err -log file.log

Options:
    -d distance_file          A distance file, or list of distance files (i.e. aligned and unaligned) separated by commas
    -m matrix_file            The distribition of this sequence (a.k.a. 100% identity cluster) across your libraries
    -R R_output_prefix        The output prefix used for the R_files (requires R/2.12.1, make sure to add this module before running this program)
    -out output.err           The output file name containing the a list of errors and to be parsed into a typical OTU file format by err2list.pl
    -log LOGFILE              Name of the log file where some information will be logged
    -old old_err_files        Old stats file or list of old stats files separates by commas. The program will resume where it left off from previous runs.
    -dist DIST_CUTOFF         The distance cutoff that you would consider merging sequences to (default is 0.1)
    -abund ABUND_CUTOFF       The abundance cutoff that a parent has to satisfy to be considered. 
                              0 if you want to merge uninformative sequence diversity but take longer, 10 increases speed but detects many methodological errors (sequencing, PCR)
    -pval PVALUE_CUTOFF       P-value cutoff above which OTUs will be merged. Default=0.0005 (do not go below 9.999E-05 or simulated pvalues will not work)
			      Lower pvalues create fewer OTUs, higher pvalues create more OTUs.
    -JS JS_CUTOFF             Use the Jensen-Shannon diistance to determine whether to merge values (default=off), especially when ABUND_CUTOFF = 0.
                              Good JS_CUTOFF value around 0.2 (best to use when abundance thresh = 0). Will be applied after failing chi-sq test cut-off.
    -verbose                  Print out verbose information about progress to log file. Useful in debugging.
\n";
}

sub JS_value {
    #pass the two OTUs that you want to compare
    #need to have matbarhash defined with all of the 
    #header values in the library
    #also need mathash defined with the count of each OTU across all libraries

    my ($one);
    my ($two);
    my ($JS1);
    $JS1=0;
    my ($JS2);
    $JS2=0;
    my ($newJS);
    $newJS=0;
    my ($q);
    my ($p);
    my ($header);
    ($one, $two) = @_;
    my ($total1, $total2);
    $total1=0;
    $total2=0;
    #Get the total number of counts per OTU
    foreach $header (sort keys %matbarhash){
	if ($mathash{$one}{$header}){
	    $total1+=$mathash{$one}{$header};
	}
	if ($mathash{$two}{$header}){
	    $total2+=$mathash{$two}{$header};
	}
    }
    
    foreach $header (sort keys %matbarhash){
	#each is defined as the portion of the total amount in the OTU
	if ($mathash{$one}{$header} && $total1){
	    #normalize to the total number of counts per OTU
	    ($p) = $mathash{$one}{$header}/$total1;
	} else {
	    $p=0;
	}
	if ($mathash{$two}{$header} && $total2){
	    ($q) = $mathash{$two}{$header}/$total2;
	} else {
	    $q=0;
	}
	#calculate for p
	if ($p > 0){
	    $sum1=($p+$q)/2;
	    $sum2=$p/$sum1;
	    $sum3=log($sum2)/log(2);
	    $sum4=$p*$sum3;
	    #sum of all JS1s
	    $JS1+=$sum4;
	}
	#calcuate for q
	if ($q > 0){
	    $sum1=($q+$p)/2;
	    $sum2=$q/$sum1;
	    $sum3=(log($sum2))/log(2);
	    $sum4=$q*$sum3;
	    #sum of all JS2s
	    $JS2+=$sum4;
	}
	print LOG "$one\t$p\t$total1\t$mathash{$one}{$header}\t$JS1\t$two\t$q\t$total2\t$mathash{$two}{$header}\t$JS2\n" if ($verbose);
    }
    $newJS=($JS1 + $JS2)/2;
    return ($newJS);
}

sub findcorrel {
    #%matbarhash must be defined and contain the keys of all possible libraries
    #%mathash must be defined and contain the values of each OTU across all libraries
    #R must be loaded and running
    my ($one, $two);
    ($one, $two) = @_;
    my ($string);
    $string=();
    my ($totalnolib);
    $totalnolib=();
    my ($correl);
    foreach $bar (sort keys %matbarhash){
	#don't print, but pass something to R
	$mathash{$two}{$bar} = 0 unless ($mathash{$two}{$bar});
	$mathash{$one}{$bar} =0 unless ($mathash{$one}{$bar});
	if ($mathash{$two}{$bar} || $mathash{$one}{$bar}){
	    if ($string){
		$string="$string"."$mathash{$two}{$bar}\t$mathash{$one}{$bar}\n";
	    } else {
		$string="$mathash{$two}{$bar}\t$mathash{$one}{$bar}\n";
	    }
	    $totalnolib++ if ($mathash{$two}{$bar} || $mathash{$one}{$bar});
	}
    }
    if ($totalnolib ==1){
	$correl="NA";
    } else {
	system ("rm ${Rfile}.corv\n") if (-e "${Rfile}.corv");
	#run chisq and fishers
	open (INPUT, ">${Rfile}.in") or die "Can't open ${Rfile}.in\n";
	print INPUT "$string\n";
	close (INPUT);
	open (FIS, ">${Rfile}.cor") or die "Can't open ${Rfile}.cor\n";
	print FIS "x <- read.table(\"${Rfile}.in\", header = FALSE)                                                                                        
a<-x[1:${totalnolib},1]                                                                                               
b<-x[1:${totalnolib},2]                                                                                                                                                         
j<-cor(a,b)                                                                               
print(j)
write.table(j,file=\"${Rfile}.corv\",sep=\"\t\",row.names=FALSE,col.names=FALSE)\n";
	close (FIS);

	system ("R --slave --vanilla --silent < ${Rfile}.cor >> ${Rfile}.err");

	if (-e "${Rfile}.corv"){
	    $correl=();
	    my ($Rline);
	    open (RES, "<${Rfile}.corv") or die "Can't open ${Rfile}.corv\n";
	    while ($Rline=<RES>){
		chomp ($Rline);
		next unless ($Rline);
		($correl)=$Rline=~/^(.+)$/;
	    }
	    close (RES);
	} else {
	    die "${Rfile}.corv not available\n";
	}
    }
    return ($correl);

}

