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
