#!/usr/bin/env perl
use Getopt::Long;
use strict;

my ($file, $k, $rc, $pe);    # input fasta | kmer shred size | add revcomps? | paired-end insert size (otherwise, single-end)
GetOptions("f=s" => \$file, "k=i" => \$k, "i" => \$pe, "revcomp" => \$rc);
die "File '$file' unreadable!\n" unless -e $file;
die "K value '$k' must be a positive integer!\n" if $k =~ /\D/;
die "PE insert size '$pe', if specified, must be a positive integer!\n" if ($pe && $pe =~ /\D/);
my ($fname) = ($file =~ /([^\/]+)/);

my ($header, @headers, %seq);
open IN, $file;
while (<IN>) {
     $_ =~ s/[\n\r]+$//;
     if ($_ =~ /^>(.*)/) {
          $header = $1;
          push @headers, $1;
     } else {
          $seq{$header} .= "\U$_";
     }
}
close IN;

my ($outname1, $outname2);
if ($pe) {
    $outname1 = $rc ? "shredded_${k}_1_RC_$fname" : "shredded_${k}_1_$fname";
    $outname2 = $rc ? "shredded_${k}_2_RC_$fname" : "shredded_${k}_2_$fname";
} else {
    $outname1 = $rc ? "shredded_${k}_1_RC_$fname" : "shredded_${k}_1_$fname";
}
open OUT1, "> $outname1";
open OUT2, "> $outname2" if $pe;
foreach my $header (@headers) {
    my $max = length($seq{$header}) - $k;
    for (my $i = 0; $i <= $max; $i++) {
	my $subseq = substr($seq{$header}, $i, $k);
	(my $subrc = reverse($subseq)) =~ tr/ACGT/TGCA/ if $rc;
	if ($k > 50) {
	    $subseq = blockify($subseq);
	    $subrc = blockify($subrc) if $rc;
	}
	if ($pe) {
	    print OUT1 ">$header:$i:1\n$subseq\n";
	    print OUT1 ">$header:$i:1:RC\n$subrc\n" if $rc;
	    my $subseq2 = substr($seq{$header}, $i+$pe, $k);
	    (my $subrc2 = reverse($subseq2)) =~ tr/ACGT/TGCA/ if $rc;
	    if ($k > 50) {
		$subseq2 = blockify($subseq2);
		$subrc2 = blockify($subrc2) if $rc;
	    }
	    print OUT2 ">$header:$i:2\n$subseq2\n";
	    print OUT2 ">$header:$i:2:RC\n$subrc2\n" if $rc;
	} else {
	    print OUT1 ">$header:$i\n$subseq\n";
	    print OUT1 ">$header:$i:RC\n$subrc\n" if $rc;
	}
    }
}
close OUT1;
close OUT2 if $pe;
exit;

sub blockify {
     my $SEQ = shift;
     my @block;
     my $loops = int(length($SEQ) / 50) + 1;
     foreach my $i (1..$loops) {
          my $start = ($i - 1) * 50;
          my $SEQ = substr($SEQ, $start, 50);	
          push @block, $SEQ;
     }
     return (join "\n", @block);
}
