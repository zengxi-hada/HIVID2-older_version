# 1. Install
Download all the files into one folder and run main.pl using "perl /absolute_path_of_main.pl/main.pl parameter1 parameter2 parameter3 ......".
The users should install the packages used in perl and python programs, such as PerlIO::gzip, Getopt::Long, File::Basename, etc.

# 2. A Step-to-step protocol of the HIVID2 pipeline 

## 2.1 The main program: main.pl

## 2.2 Parameters
-o	output directory path
-l	a file containing sample_id, library_id and FC_id
-stp step number (1/2/3/4)
-c	parameter configuration file
-filter	whether to filter the repeated comparison reads. Here, only the repeated comparison reads on the human genome are filtered. The repeated comparison reads on the HBV genome are not filtered. However, in the result, the reads of repeated alignments on the HBV genome will be discarded, and the only aligned reads on the corresponding human genome will be retained.

## 2.3 Description of several predefinding files
### (1) -C    the Configure file
This configure file difined the referece genomes and alignment parameters used in step3. The users can make their own configure file. But we have involved some configure files which is named as Config* in the same folder of main.pl.

### (2) -l	  a file containing sample_id, library_id and FC_id
It can be named as any name and simply write as the sample name in three column. For example, a file named "list" and contain a line with three columns:
SRR12345 SRR12345 SRR12345


## 2.4 Step to step tutorial

### 1st step

Manually create a file named "list" in the output directory. Then manually create a folder named step1, and create a file named sample.list in folder step1. The location of sample.list should be step1/sample.list. Note that the path in the sample.list should be absolute full path. Below is an example of sample.list:

Sample  FC  Lane  Libray  read_length library_size  
simdata simdata simdata simdata 110;110 170 /absolute_path/bkread1.fq.gz /absolute_path/bkread2.fq.gz

### 2nd step

perl /absolute_path_of_main.pl/main.pl -o <output directory> -l list -stp 2 -c configuration_file
  
Example: perl main.pl -o test2 -l list -c ConfigHPV_19 -stp 2

Note: 1) After running this command, the directory for each sample will be generated under the step2 folder. A shell script for each sample will be generated under corresponding folder. These shell scripts could be manually submitted onto to the server using qsub.

### 3rd step

perl /absolute_path_of_main.pl/main.pl -o <output directory> -l <sample list> -stp 3 -c configuration_file
  Example: perl main.pl -o test2 -l list -c ConfigHPV_19 -stp 3
  
Note: 1) After running this command, a folder named after the sample name will be automatically generated in step3 folder. In each sample folder, there are three scripts Human_virus_soap.sh and station.sh. These scripts could be manually delivered to the sge system using qsub. The user should run Human_virus_soap.sh first before running station.sh.

2) Run Dataproduction.sh manually to get the data production report including the data amount, data quality, sequence alignment profiles.

### 4th step

perl /absolute_path_of_main.pl/main.pl -o <output directory> -l <sample list> -stp 4 -c configuration_file -filter -fa1 <bwa index for human ref> -fa2 <bwa index for virus ref>
Example: perl main.pl -o test2 -l list -c ConfigHPV_19 -stp 4 -filter -fa1 human.fa -fa2 hpv.fa

Note: 
  
  (1) Once this step is finished, a folder named after the sample name will be generated in step4 folder. There is a shell script in each directory. These scripts could be manually delivered to the SGE system using qsub. 
  
  (2) It should be noted that there are a file named "ref.list" in the same folder of main.pl. "ref.list" must contain all the ID of reference genomes used in the sequence alignment of step3 and step4, or the user will get error or uncomplete results in *human_bk.final.stp2.uniq2.final during the procedure of deep removing PCR-duplications. We have involved some predefined reference names in ref.list, but the users should add the references names used in their own experiments.
  


## 2.5 Result file and the format descript

The path of the files of final results:

The file of human breakpoint: step4/*/human/ breakpoint/*human_bk.final.stp2.uniq2.final

The file of virus breakpoint: step4/*/virus/breakpoint/*HBV_bk.final.stp2.uniq

Format description of the result file:

1st column is the number of the chromosome where the breakpoint located.

2nd column is Specific position coordinates

3rd column is the pair amount of left support reads

4th column is the pair amount of right support reads

5th column is the pair amount of discordant support reads

6th column is total number of all support reads

7th column is normalized pair amount of left support reads (normalized_value =support_reads_number / effective_reads_number_of_the_sample)

8th column is normalized pair amount of right support reads (logarithmic) normalized value

9th column is normalized pair amount of discordant support reads

10th column is total number of reads (logarithmic) normalized value

11th column is reads id of left support reads

12th column is reads id of right support reads


# 3. Advanced analysis

After obtaining the integration sites, HIVID2 allows the user to decide whether to automatically perform advanced analysis using the identified virus integrations. 

(1)	Manually seprate result folders of step4 into two groups, For example, tumor and normal, or other user-definednames. If you ran tumor and normal samples in a single run, then you may move each sample (each sample has a folder in step4) into the tumor or normal folder; if you iniatially ran tumor and normal samples seprately during step4, then you can simply use the step4 folder of tumor and normal of each run.

(2)	Run advanced analysis
#First， run Analyse.sh, generatint R scripts and the relevant files.
sh /absolute_path_of_main.pl/advanced_analysis/Analyse.sh /absolute_path/tumor /absolute_path/normal        
#Second, run the generated R scripts
Rscript xxx.R

Note: If you want to get the graph one by one, please separate the script and change parameters. You can also run it line by line, and modify the parameters by yourself. 

# 4. Other tips
(1) In order to help the users to track the data processing, HIVID2 retained some intermediate procedure files during running of the pipeline. It may cause big hard disk consuming when deal with large amount of data such as WGS data. Fortunately, The users can can remove most of intermediate files of previous steps when running step4. When running step4, the user can remove all the files named "*paired.gz" and "*unpaired.gz" in step2, all the files named "*soap.gz" in step2. After completing step4, all the files except the files of final results could be deleted. But before deleting, the users should make sure they don't need them later.
(2) There is a file named "tfbsConsSites.txt" in the advanced analysis. This file cannot be uploaded onto github due to the size limitation. But the user could download this file from Table browser of UCSC.


# 5. Citation
Xi Zeng, Linghao Zhao, Chenhang Shen, Yi Zhou, Guoliang Li, Wing-Kin Sung, HIVID2: an accurate tool to detect virus integrations in the host genome, Bioinformatics, 2021, btab031, https://doi.org/10.1093/bioinformatics/btab031
