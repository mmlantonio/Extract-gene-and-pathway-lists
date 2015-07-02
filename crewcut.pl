#!usr/bin/perl

#Margaret Antonio 
#Parser for .diff files to just get differentially expressed genes with significant fold change

#.diff file description: 0-test_id 1-gene_id 2-gene 3-locus 4-sample_1 5-sample_2 6-status 7-value_1 8-value_2 9-log2(fold_change) 10-p_value 11_q-value 12-significant


use strict;
use warnings;
use Getopt::Long;

sub print_usage(){

    print "\nRequired:\n";
    print "In the command line (without a flag), input the name of the .diff file to be parsed\n";
    
    print "\nOptional:\n"; 
    print "--fc \t Lowest acceptable fold_change value Default: 2\n";
    print "--out \t Name of output file\n";
    print "--ext \t specify output gene file extension (txt, sbt, etc). Default ext= txt for file.txt";
}


#Assign inputs to variables

our ($fc, $ext);
GetOptions(
	'fc:i' => \$fc,
	'ext' => \$ext,
);

sub get_time() {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    return "$hour:$min:$sec";
}

print print_usage(),"\n";
print "\n";

if (!$fc){$fc=2;}
if (!$ext){$ext="txt";}

print get_time;
print "\nReady to begin parsing file...\n\n";

#==========================================================================================
my @genes; #array to temporarily hold significant genes from a single comparison until written to txt file
my @genes_val1; #array like @genes, but for genes that have val1=0 and val2!=0
my @genes_val2; #array like @genes, but for genes that have val1!=0 and val2=0


my $fold_change;

sub uniq {		#subroutine to remove gene duplicates in the @genes array
    my %seen;
    grep !$seen{$_}++, @_;
}

my $file = $ARGV[0] or die "Need to get input file on the command line\n";
open(FH, '<', $file) or die "Could not open '$file' $!\n";

my $dummy=<FH>;			#Skips first line in file (header line)
my $sample1="none";
my $sample2;

while (my $line = <FH>) {               #Open the input file and go through each line
	my @fields = split("\t",$line);
	my $fields=\@fields;
	###Printing gene lists from single comparisons

    if (($sample1 ne "none") && (($fields[4] ne $sample1) or ($fields[5] ne $sample2))){ 
        #write @temp array to file and start a new data set
           
	my @sgenes= sort {$a cmp $b}@genes; #alphabetically sort each of the three gene lists
	my @fgenes=uniq(@sgenes); #filter gene lists to only include each gene once
	open (FILE,">$sample1-$sample2-genes.$ext");
	#print FILE "$sample1$sample2", "\t";
	foreach my $gene(@fgenes){
		print FILE $gene, "\n";
	}
        close FILE;
            
	my @sgenes_val1= sort { $a cmp $b}@genes_val1;
	my @fgenes_val1=uniq(@sgenes_val1);
	open (FILE,">$sample1-$sample2-genesval1.$ext");
	#print FILE "$sample1$sample2", "\t";
	foreach my $genes_val1(@fgenes_val1){
		print FILE $genes_val1, "\n";
	}
	close FILE;
	
	my @sgenes_val2= sort { $a cmp $b}@genes_val2;
	my @fgenes_val2=uniq(@sgenes_val2);
	open (FILE,">$sample1-$sample2-genesval2.$ext");
	#print FILE "$sample1$sample2", "\t";
	foreach my $genes_val2(@fgenes_val2){
		print FILE $genes_val2, "\n";
	}
	close FILE;


        #Empty array ,reset sample names, and increment i for new file

        @genes=();
        @genes_val1=();
        @genes_val2=();
        $sample1=$fields[4];
        $sample2=$fields[5];
    }
  	
  	if (($fields[6] ne "OK") or ($fields[2] eq "-")) {     #Only want known genes whose status is OK. Remove FAILED and NOTEST
  		next;
  	} 
  
	  #Work on making an option here to decide if unknown gene loci are included
	  #if ($known && $fields[2] eq "-"){     #If user only wants known genes
	  #  next;
	  # }
	  
	  #Make option here for choosing to base significance on fold change or p-value; \
	  #splice @fields, 10, 4; #If there are no biological replicates, then remove the p-val related fields
  
  if ($fields[7]==0 && $fields[8]!=0){
  	my @values1=split(',',$fields[2]);
  	foreach my $val1(@values1){
        	push (@genes_val1,$val1);
  	}
  }
  elsif ($fields[7]!=0 && $fields[8]==0){
  	my @values2=split(',',$fields[2]);
  	foreach my $val2(@values2){
        	push (@genes_val2,$val2);
  	}
  }
  else{
  	$fold_change=$fields[8]/$fields[7];
	if ($fold_change<$fc){
	  	next;
	}
	my @values=split(',',$fields[2]);
  	foreach my $val(@values){
        	push (@genes,$val);
	}
  }
            
 #Empty array ,reset sample names, and increment i for new file



    }
    
print get_time;

print "Finished \n\n";

