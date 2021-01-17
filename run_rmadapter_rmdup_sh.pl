#!usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';
my $usage=<<USAGE;
	perl $0 -o <outdir> -pe <PE sample name list> -se <SE sample name list> -adapter -cut -l <low Qual> -r <low_qual rate> -dup -save -S <sort -S> -qsub -vf <in.resource>
	-o <STR>		outdir where process result,outdir/rm_adapter|rm_dup/sample name/(rm*sample_name*);
	-pe <STR>		PE list file 
	sample.list
        <Column 1:>             Sample name
        Column -2:               _1.fq file
        Column -1:               _2.fq file
	-se<STR>		SE list file
	sample.list
	Column 1:               Sample name
        Column -1:               _1.fq file
	-adapter		whether dispose of polluted read by adapter 
	-cut 			cut off the adapter sequence,default remove the polluted read by adapter
	-l <int>		low Qual,default 5;
	-r<f>			low_qual rate,default 0.5;
	-dup 			whether rm  duplication
	-save 			whether save the duplication
	-S			sort max memory
	-qsub 			automatically qsub jobs; default FALSE
	-vf <int> 		in.resource
USAGE
my($out,$pelist,$selist,$adapter,$cut,$dup,$save,$ram,$qsub,$help,$low_qual,$rate,$vf);
GetOptions (
	'o=s'=>\$out,
	'pe=s'=>\$pelist,
	'se=s'=>\$selist,
	'adapter!'=>\$adapter,
	'cut!'=>\$cut,
	'l=i'=>\$low_qual,
	'r=f'=>\$rate,
	'dup!'=>\$dup,
	'save!'=>\$save,
	'S=i'=>\$ram,
	'qsub!'=>\$qsub,
	'vf=s'=>\$vf,
	'help|?'=>\$help,
);


if ($vf){$vf=$vf."g" unless $vf=~/g/;}
$ram=2500000000 if !defined $ram;
die $usage if ($help);
die $usage if (!$out|!$pelist&& !$selist|!$adapter && !$dup);
$out =abs_path ($out);
`mkdir $out` if (!-d $out);
my $bin=dirname (abs_path ($0));
#my ($rmadapter,$adapter_sh,$rmdup,$dup_sh);
#if ($adapter){
#	$rmadapter = "$out/rmadapter";
#	`mkdir $rmadapter` unless -d -e $rmadapter;
#	$adapter_sh= "$rmadapter/adapter_sh";
#	`mkdir $adapter_sh` unless -d -e $adapter_sh;
#}
#if ($dup){
#	$rmdup= "$out/rmdup";
#	`mkdir $rmdup` unless -d -e $rmdup;
#	$dup_sh="$rmdup/rmdup_sh";
#	`mkdir $dup_sh` unless -e -d $dup_sh;
#}
#---------------------------------------------------------------


if ($pelist){
#	my ($rmdupdir,$rmadapterdir);
	open DULIST,">$out/rmdup.list" or die $! if $dup;
	open ADLIST,">$out/rmadapter.list" or die $! if $adapter;
	open LIST,"<$pelist" or die $!;
	my ($num,$info);
	my $head=<LIST>;
	print DULIST "$head" if $dup;
	print ADLIST "$head" if $adapter;
	while (<LIST>){
		chomp;
		$num++;
		my @a=split;
		my $sampledir="$out/$a[0]";
		`mkdir $sampledir` if (!-d $sampledir);
		open INT,">$sampledir/$a[0]_$num.sh" or die $!;
		if ($dup){
			print INT "date\necho \"## rm fq file duplication\"\nperl $bin/rm_duplication.pl -a1 $a[-3] -a2 $a[-2] -S $ram -o $sampledir " ;
			print INT "-save" if ($save);
			print INT "\n";
#			$info= `qsub -cwd -l vf=$vf  "$dup_sh/$a[0]$num.sh" -e $dup_sh -o $dup_sh` if ($qsub);
			my $name1=basename ($a[-3]);
			$a[-3]="$sampledir/rmdup_$name1";
			my $name2=basename ($a[-2]);
			$a[-2]="$sampledir/rmdup_$name2";
			my $list=join "\t",@a;
			print DULIST "$list\n";
		}
		if ($adapter){
			my ($file_name1,$file_name2);
#			$rmadapterdir="$out/$a[0]";
#			`mkdir $rmadapterdir` if (!-d $rmadapterdir);
			my $adapter=dirname($a[-1]);
			opendir DIR,"$adapter" or die $!;
			my @dir=readdir(DIR);
			for my $file(@dir){
				chomp;
				$file_name2=$file if $file=~/2.adapter.list/;
				$file_name1=$file if $file=~/1.adapter.list/;
			
			}
			closedir DIR;
			my $adapter1="$adapter/$file_name1";
			my $adapter2="$adapter/$file_name2";
			die "no $adapter1 file" if (!-e $adapter1);
			die "no $adapter2 file" if (!-e $adapter2);
	#		$a[-3]=~/.*\//;
	#		my ($fq1,$fq2);
	#		if ($dup){ $fq1="$rmdupdir/rmdup_$'"}else{$fq1=$a[-3]}
	#		$a[-2]=~/.*\//;
	#		if($dup){$fq2="$rmdupdir/rmdup_$'"}else{$fq2=$a[-2]}
#			open IN,">$ad/$a[0]$num.sh" or die $!;
			print INT "echo \"## rm fq file adapter and low quality \"\nperl $bin/rm_adaptor.pl -a1 $adapter1 -a2 $adapter2 -f1 $a[-3] -f2 $a[-2] -o $sampledir ";
			print INT "-l $low_qual " if ($low_qual);
			print INT "-r $rate " if ($rate);
			print INT "-cut " if ($cut);
			print INT "\ndate>&2\necho \"## all work done\"\n";
			close INT;
			if ($qsub){
			#	$info=~/\d+/;
			#	my $job_id =$&;
				`qsub -cwd -l vf=$vf "$sampledir/$a[0]_$num.sh" -e $sampledir -o $sampledir `;
			#}else{
			#	`qsub -cwd -l vf=$vf "$adapter_sh/$a[0]$num.sh" -e $rmdupdir -o $rmdupdir ` if $qsub;
			}
			my $name=basename $a[-3];
			$a[-3]=~/.*\//;
                        $a[-3]="$sampledir/rm_adapter_$'";
                        $a[-2]=~/.*\//;
                        $a[-2]="$sampledir/rm_adapter_$'";
			$name=~s/_\d.fq.gz\b//;
			my $dupstat="$sampledir/$name.stat";
			my $adpterstat="$sampledir/rm_adapter_$name.stat";
			$a[-4]="$a[-4]\t$dupstat\t$adpterstat";
                        my $ad_list=join "\t",@a;
			print ADLIST "$ad_list\n";

		}
	}
	close LIST;
	close DULIST;
	close ADLIST;
}
#------------------------------------------------------------------
if ($selist){
#	my ($rmdupdir,$rmadapterdir);
	open DULIST,">$out/rmdup.list" or die $! if $dup;
        open ADLIST,">$out/rmadapter.list" or die $! if $adapter;
	open SE,"<$selist" or die $!;
        my ($num,$info);
	my $head=<SE>;
	print DULIST "$head" if $dup;
        print ADLIST "$head" if $adapter;
        while (<SE>){
                chomp;
                $num++;
                my @a=split;
		my $sampledir="$out/$a[0]";
                `mkdir $sampledir` if (!-d $sampledir);
		 open INT,">$sampledir/$a[0]$num.sh" or die $!;
                if ($dup){
#                        open INT,">$sampledir/$a[0]$num.sh" or die $!;
                        print INT "date\necho ","## rm duplication ","perl $bin/rm_duplication.pl -a1 $a[-2] -S $ram -o $sampledir " ;
                        print INT "-save" if ($save);
                        print INT "\n";
#                        close INT;
#                        $info= `qsub -cwd -l vf=$vf  "$dup_sh/$a[0]$num.sh" -e $dup_sh -o $dup_sh` if $qsub;
#			$a[-3]=~/.*\//;
#                        $a[-3]="$sampledir/rmdup_$'";
                        $a[-2]=~/.*\//;
                        $a[-2]="$sampledir/rmdup_$'";
                        my $list=join "\t",@a;
                        print DULIST "$list\n";
                }
                if ($adapter){
#                        $rmadapterdir="$rmadapter/$a[0]";
#                       `mkdir $rmadapterdir` if (!-d $rmadapterdir);
			my $adapter=dirname(abs_path($a[-2]));
			my $file_name;
			 opendir DIR,"$adapter" or die $!;
                        my @dir=readdir(DIR);
                        for(@dir){
                                chomp;
                                $file_name=$_ if $_=~/2.adapter.list/;
                        }
                        closedir DIR;
                        $adapter="$adapter/$file_name";
                        die "no $adapter file" if (!-e $adapter);
	#                $a[-2]=~/.*\//;
	#		my $fq1;
        #                if($dup){$fq1="$rmdupdir/rmdup_$'"}else{$fq1=$a[-2]}
        #                open IN,">$adapter_sh/$a[0]_$num.sh" or die $!;
                        print INT "date \necho ","## rm adapter and low quality","\nperl $bin/rm_adaptor.pl -a1 $adapter  -f1 $a[-2] -o $sampledir ";
                        print INT "-l $low_qual " if ($low_qual);
                        print INT "-r $rate " if ($rate);
                        print INT "-cut " if ($cut);
                        print INT "date>&2\necho ","## all work over",">&2\n";
                        close INT;
                        #if ($qsub){
                        #        $info=~/\d+/;
                        #        my $job_id =$&;
                        #        `qsub -hold_jid $job_id -cwd -l vf=$vf "$adapter_sh/$a[0]$num.sh" -e $rmdupdir -o $rmdupdir ` if $qsub;
                        #}else{
                                `qsub -cwd -l vf=$vf  "$sampledir/$a[0]_$num.sh" -e $sampledir -o $sampledir ` if $qsub;
                       # }
#			$a[-3]=~/.*\//;
#                        $a[-3]="$rmadapterdir/rm_adapter_$'";
			my $name=basename ($a[-2]);
                        $a[-2]=~/.*\//;
                        $a[-2]="$sampledir/rm_adapter_$'";
			$name=~s/_\d.fq.gz\b//;
			my $dupstat="$sampledir/$name.stat";
			my $adaperstat="$sampledir/rm_adapter_$name.stat";
			$a[-3]="$a[-3]\t$dupstat\t$adaperstat";
                        my $ad_list=join "\t",@a;
                        print ADLIST "$ad_list\n";
                }
        }
	close SE;
	close ADLIST;
	close DULIST;
}
