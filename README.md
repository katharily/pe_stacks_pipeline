# pe_stacks_pipeline

## Prerequisites and Set-Up
### Windows Users: Activation of Subsystem for Linux
For the execution of the pipeline with nextflow on a Windows computer, the activation of the Linux subsystem (provided for Windows 10) is required.
Ubuntu is recommended as Linux distribution but others will also work. <br>
A detailed set-up guide is provided by Microsoft in German and English language at the following link:<br> https://docs.microsoft.com/de-de/windows/wsl/install-win10

### Installation of Conda and Bioconda
<b>Note:</b> 	Windows users must execute the conda setup within the previously installed Linux subsystem. <br>
For the setup of conda and Bioconda, please follow the instructions Install conda and Set up Channels given in the documentation page of Bioconda:<br> http://bioconda.github.io/user/install.html#install-conda

### Installation of Nextflow
<b>Note:</b> 	Windows users must execute the nextflow setup within the previously installed Linux subsystem.<br>
Execute the nextflow installation as described in the Quickstart section of the nextflow documentation: <br>https://www.nextflow.io/index.html#GetStarted. <br>
The executable nextflow file will be installed in the directory you execute the setup, please keep this location in mind.<br>

### Execute the Nextflow Scripts
For running a nextflow script in general, call the executable nextflow file like the following: <br>
`$ ./nextflow run ${script name}.nf`<br>
If necessary, direct to the nextflow file and/or the script you want to execute via a relative path.
<br>
<br>
# Quick start
1.	Run `conda activate`; you should see `(base)` on the left side of the username in the terminal 
2.	Direct into the folder where nextflow is located `/data/nextflow`, then execute nextflow with `run`.
3.	Navigate to code folder `/data/PE_Stacks_Pipelines/` and choose the script you want to execute
4.	Specify the required inputs as <b>absolute paths</b> and run the code by pressing enter
<b>Example:</b> _Catananche lutea_ 	<br>

### 1-clean_reads.nf

`/data/nextflow run /data/PE_Stacks_Pipelines/1-clean_reads.nf \` <br>
`--inputDir /data/Israel-Projekt/Catanache_lutea_AdapterClipped/ \`<br>
`--outputDir /data/Israel-Projekt/Analysis_Catananche_lutea/`<br>

### 1-prepare_reference_genome.nf

`/data/nextflow run /data/PE_Stacks_Pipelines/1-prepare_reference_genome.nf \` <br>
`--referenceDir /data/Israel-Projekt/genome_assemblies\ lettuce\ cv\ salinas/ \`<br>
`--outputDir /data/Israel-Projekt/Reference_genomes_indices/lettuce_cv_salinas/`<br>

### 2-sort_control_and_map.nf

`/data/nextflow run /data/PE_Stacks_Pipelines/2-sort_control_and_map.nf \` <br>
`--workingDir /data/Israel-Projekt/Analysis_Catananche_lutea/ \`<br>
`--referenceDir /data/Israel-Projekt/Reference_genomes_indices/lettuce_cv_salinas/ \`<br>
`--dirName lettuce_cv_salinas`<br>

### 3-map_creation.nf

`/data/nextflow run /data/PE_Stacks_Pipelines/3-map_creation.nf \`<br>
`--workingDir /data/Israel-Projekt/Analysis_Catananche_lutea/ \`<br>
`--populationMap /data/Israel-Projekt/Populationmap/Populationmap_Catananche.txt \`<br>
`--dirName lettuce_cv_salinas`

### 4-populations.nf

`/data/nextflow run /data/PE_Stacks_Pipelines/4-populations.nf \`<br>
`--inputDir /data/Israel-Projekt/Analysis_Catananche_lutea/denovo_map/ \`<br>
`--outputDir /data/Israel-Projekt/Analysis_Catananche_lutea/denovo_map_populations/ \`<br>
`--populationMap /data/Israel-Projekt/Populationmap/Populationmap_Catananche.txt`<br>

<b>For your info:</b> If an error occurred, you can resume the nextflow execution after fixing the bug specifying `-resume` behind the previous command. In case you get <b>funny errors</b> like the print-out of the usage of _Stacks_ tools run `conda deactivate` followed by `conda activate`. It is <b>not possible to run several nextflow applications</b> within different terminals at the same time but this should not be desired anyway regarding the computation power of the cloud. 
