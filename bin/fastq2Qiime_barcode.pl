#! /usr/bin/perl -w

die "Usage: fastq\n" unless (@ARGV);
($new) = (@ARGV);
chomp ($new);

open (IN, "<$new" ) or die "Can't open $new\n";
while ($head1 =<IN>){
    chomp ($head1);
    $seq=<IN>;
    $head2=<IN>;
    $qual=<IN>;
    next unless ($head1);
    ($first, $bar, $second)=$head1=~/^(.+)\#([ATGCKMRYSWBVHDNX]+)(.+)$/;
    ($lcbar)=lc($bar);
    print "${head1}\n$bar\n+\n$lcbar\n";
} 
close (IN);

