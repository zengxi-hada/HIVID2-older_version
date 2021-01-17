#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use PerlIO::gzip;
use File::Basename qw(basename dirname);
my $usage=<<USAGE;

Note:   Remove reads with adapter and low-quality reads.

USAGE:  PE: perl $0 -a1 <adapter_file1> -a2<adapter_file2> -f1<sample_file1> -f2 <sample_file2> -o <out_dir> -l <low Qual> -r <low_qual rate> -cut 
                SE: perl $0 -a1 <adapter_file1> -f1 <sample_file1> -o <out_dir> -l [<LowQual> -r <Q_rate>]
                adapter_file1:  must be _1 adapter file
                sample_file1:   must be _1 fq file
                LowQual/Q_rate: Remove low-quality reads in which bases with Q <=5 account for more than 50% of the total[5,0.5]

USAGE
my ($adapter_file1,$adapter_file2,$sample_file1,$sample_file2,$out,$cut,$qual,$rate);
$qual=5;
$rate=0.5;
GetOptions(
	'a1=s'=>\$adapter_file1,
	'a2=s'=>\$adapter_file2,
	'f1=s'=>\$sample_file1,
	'f2=s'=>\$sample_file2,
	'o=s'=>\$out,
	'cut!'=>\$cut,
	'l=i'=>\$qual,
	'r=f'=>\$rate,
);
die "$usage\n" if !$adapter_file1|!$sample_file1|!$out;
`mkdir $out` if !-d $out;
print "Remove adapter.. START TIME: ",`date`;
my @baseQual = qw/@ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [ \ ] ^ _ ` a b c d e f g h i j/; # ASCLL - 64 = 0-40 # B-f/2-38
my $STR;
for(my $i=2;$i<=$qual;$i++){
        if($baseQual[$i] =~ /\w/){
                $STR .= "$baseQual[$i]";
        }else{
                $STR .= "\\$baseQual[$i]";
        }
}
#------------------------------------------------------------
my %adapter=();
my ($sumre_num,$adapter_rm_num,$lowqualre_num,$seqL)=(0,0,0,0);
my %low_qual=();
#read apdapter file 
&readadapter($adapter_file1,\%adapter,$sample_file1,\%low_qual);
&readadapter($adapter_file2,\%adapter,$sample_file2,\%low_qual) if ($adapter_file2);
#read fq file and remove the reads with adapter or cut the adapter
if ($cut){
	&cutread($sample_file1,\%adapter,\%low_qual,\$sumre_num,\$adapter_rm_num,\$lowqualre_num);
	&cutread($sample_file2,\%adapter,\%low_qual,\$sumre_num,\$adapter_rm_num,\$lowqualre_num) if ($sample_file2);
}else{
	&rmread($sample_file1,\%adapter,\%low_qual,\$sumre_num,\$adapter_rm_num,\$lowqualre_num);
	&rmread($sample_file2,\%adapter,\%low_qual,\$sumre_num,\$adapter_rm_num,\$lowqualre_num) if ($sample_file2);
}
#-----------------------------------------------------------------
my $name=basename $sample_file1;
$name=~s/_\d.fq.gz\b//;
open STAT,">$out/rm_adapter_$name.stat" or die $!;
print STAT "Original reads number:\t$sumre_num\n";
print STAT "Original bases number:\t",$sumre_num*$seqL,"\n";
print STAT "Adapter reads number:\t$adapter_rm_num\n";
print STAT "Low-quality reads number:\t$lowqualre_num\n";
print STAT "Low-quality reads rate:\t",100*$lowqualre_num/$sumre_num,"\n";
print STAT "Adapter reads rate:\t",100*$adapter_rm_num/$sumre_num ,"\n";
print STAT "Modified reads rate:\t",100*(1-($lowqualre_num+$adapter_rm_num)/$sumre_num),"\n";
close STAT;
print "Remove adapter.. END TIME: ",`date`;
#read adapter----------------------------------------------------
sub readadapter{
	my ($file,$hash1,$file2,$hash2)=@_;
	if ($file=~/.gz\b/){
		open IN,"gzip -cd $file|" or die $!;
	}else{
		open IN,"$file" or die $!;
	}
	$/="\n";
	<IN>;
	while (<IN>){
		chomp;
		my @a=split;
		my $inf=join "\t", $a[1],$a[2],$a[3];
		$$hash1{$a[0]}=$inf;
	}
	close IN;
	if ($file2=~/.gz\b/){
                open INT,"gzip -cd $file2|" or die $!;
        }else{
                open INT,"$file2" or die $!;
        }
	$/="@";
	<INT>;
	while(<INT>){
		chomp;
		next if !defined $_;
		my @a=split /\n/;
		$a[0]=~s/\/[12]\b//;
		$seqL=length $a[3];
                my $lowQualNum = $a[3] =~ s/[$STR]//g;
                if($lowQualNum/$seqL>$rate ){ # >50%	
                       $$hash2{$a[0]}++;
		}
	}
	close INT;
		
}
#remove reads----------------------------------------------------
sub rmread{
	my($file,$hash,$hash2,$sum_num,$adapter_num,$lowqual_num)=@_;
	my $fi_na=basename $file;
	open OUT,"|gzip > $out/rm_adapter_$fi_na" or die $!;
#	open ADAPTER,"|gzip > $out/adapter_$'" or die $!;
#	open LOW,"|gzip > $out/low_qual_$'" or die $!;
	if ($file=~/.gz\b/){
		open IN,"<:gzip",$file or die $!;
	}else{
		open IN,$file or die $!;
	}
	$/="@";
	<IN>;
	while(<IN>){
		chomp;
		$$sum_num++;
		my @a=split /\n/;
		my $c=$a[0];
		$c=~s/\/[12]\b//;
		if (exists $$hash2{$c}){
#			print LOW "@"."$_";
                        $$lowqual_num++;
                        next;
                }
		$c =$a[0];
		if($a[0]=~/\/1\b/){$c=~s/\/1\b/\/2/}else{$c=~s/\/2\b/\/1/}
		if (exists $$hash{$a[0]}){	
#			print ADAPTER "@"."$_";
			$$adapter_num++;
		}elsif(exists $$hash{$c}){
#			print ADAPTER "@"."$_";
                        $$adapter_num++;

		}else{
			 print OUT "@"."$_";
		}
	}
	close IN;
	close OUT;
#	close ADAPTER;
#	close LOW;
}
#cut read ------------------------------------------------------
sub cutread{
	 my($file,$hash,$hash2,$sum_num,$adapter_num,$lowqual_num)=@_;
	my $fi_na=basename $file;
        open OUT,"|gzip > $out/rm_adapter_$fi_na" or die $!;
#        open ADAPTER,"|gzip > $out/adapter_$'" or die $!;
#	open LOW,"|gzip > $out/low_qual_$'" or die $!;
        if ($file=~/.gz\b/){
                open IN,"<:gzip",$file or die $!;
        }else{
                open IN,$file or die $!;
        }
        $/="@";
        <IN>;
	while(<IN>){
                chomp;
                $$sum_num++;
                my @a=split /\n/;
		my $c=$a[0];
               # $a[0]=~/\/1\b/? $c=~s/\/1\b/\/2\b/:$c=~s/\/2\b/\/1\b/;
               # if (exists $$hash2{$a[0]}|exists $$hash2{$c}){
		$c=~s/\/[12]\b//;
		if (exists $$hash2{$c}){
#                        print LOW "@"."$_";
                        $$lowqual_num++;
                        next;
                }
		if (exists $$hash{$a[0]}){
			$$adapter_num++;
			my @b=split /\t/,$$hash{$a[0]};
			if ($b[1]<5){
				substr($a[1],0,$b[2])="";
				substr($a[3],0,$b[2])="";
				print OUT "@"."$a[0]\n$a[1]\n+\n$a[3]\n";
#				print ADAPTER "$_\t$$hash{$a[0]}\n";
			}elsif($b[0]-$b[2]-1<5){
				substr($a[1],$b[1],$b[0]-1-$b[1])="";
				substr($a[3],$b[1],$b[0]-1-$b[1])="";
				print OUT "@"."$a[0]\n$a[1]\n+\n$a[3]\n";
#                                print ADAPTER "$_\t$$hash{$a[0]}\n";
			}else{
				substr($a[1],$b[1],$b[2]-$b[1])="";
				substr($a[3],$b[1],$b[2]-$b[1])="";
				print OUT "@"."$a[0]\n$a[1]\n+\n$a[3]\n";
#                                print ADAPTER "$_\t$$hash{$a[0]}\n";
			}
		}else{
			print OUT "@"."$_";
		}
	}
	close IN;
	close OUT;
#	close ADAPTER;
#	close LOW;
}
				
			
