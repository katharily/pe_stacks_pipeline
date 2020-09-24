#!/usr/bin/env nextflow

// Styles for error messages
def styleDefault    = "\033[0m"
def styleInfo       = "\033[32;1m"
def styleWarn       = "\033[33;1m"
def styleError      = "\033[31;1m"

// *** FUNCTIONS ** //

// Prints out the help for this nextflow script
def printHelp() {
    println ""
    println "Options:"
    println "--inputDir    The directory where the data files in .bz2 format are located. [mandatory]"
    println "--outputDir   The directory where the results are saved to. [mandatory]"
    println "--t           Truncate final read length to this value; default = 100. [int] [optional]"
    println "--e1          specify restriction enzyme; default = mslI. [name] [optional]"
    println "--e2          specify second restriction enzyme in case of double digest [name] [optional]"
    println "--help        A flag used to print this help."
    println ""
}

// Prints out the usage of this nextflow script
def printUsage() {
    println ""
    println "You did not specify mendatory parameters. Input and output directories are requried!"
    println "Usage:"
    println "nextflow 1-clean_reads.nf --inputDir <path_to_input_directory_with_bz2_files> --outputDir <path_to_output_directory (empty)> --t <int> [optional] --e <name> [optional]"
    println styleInfo + "INFO: all locations must be specified as absolute path"
    println styleDefault
    println "If you require further information about the parameters please execute:"
    println "nextflow run 1-clean_reads.nf --help"
    println ""
}


// *** PARAMETERS *** //

/*  @param inputDir         Path to directory where the .bz2 files to be processed are located [mendatory]
    @param outputDir        Path to directory where the results are to be saved [mandatory]
    @param t                Truncate final read length to this value; default = 100 [int] [optional]
    @param e                specify restriction enzyme; default = mslI [name] [optional]
    @param help             A flag used to print out the help for using this pipeline [optional] */


// *** SANITY CHECKS *** //

// Stops pipeline execution if no parameters are specified. Prints out usage.
if (params.size() == 0) {
    print   styleError + "ERROR: Missing parameters. Exiting pipeline."
    println styleDefault
    printUsage()
    System.exit(0)
}

params.help = false

// If --help is submitted the pipelines stops and printHelp() is executed.
if (params.help) {
    printHelp()
    System.exit(0)
}

// If mandatory parameters are not set, the system prints out an error.
else if (!params.inputDir || !params.outputDir ) {
    print styleError + "ERROR: Missing parameters. Exiting pipeline."
    println styleDefault
    printUsage()
    System.exit(0)
}


// *** VARIABLES *** //

LOG_DIR         = params.outputDir + "log_files"
FASTQC_DIR      = params.outputDir + "quality_control/fastqc_raw"
RENAMED_DIR     = params.outputDir + "gz_files"
RADTAGS_DIR     = params.outputDir + "cleaning/process_radtags/"
READ_LENGTH     = 100
ENZYME1         = "mslI"
ENZYME2         = ""

if(params.t){ 
    READ_LENGTH = params.t 
}

if(params.e1){ 
    ENZYME1 = params.e1
}
if(params.e2){
    ENZYME2 = "--renz_2 " + params.e2
}

// *** CHANNELS *** //

// Create channel with all of the available reads in `inputDir`

Channel.fromFilePairs(params.inputDir + '/**{1,2}_clipped.fastq.bz2')
    .set{ ch_renaming_input }

Channel.fromPath(params.inputDir + '/**.fastq.gz')
    .set{ ch_fastqc_gz_input }
    
Channel.fromFilePairs(params.inputDir + '/**{1,2}_clipped.fastq.gz')    
    .set{ ch_radtags_gz_input }

// *** PROCESSES *** //

// Files are converted from .bz2 files to .gz as needed for the following steps
process convert_bz2_to_gz {
    publishDir RENAMED_DIR, mode: 'copy', pattern: '*.fastq.gz'
    maxForks 12 // number of instances of a process that are allowed simultaneously
    input:
        set id, file(reads) from ch_renaming_input
    output:
        set id, file('*?_clipped.fastq.gz') into ch_radtags_input
        file '*?_clipped.fastq.gz' into ch_fastqc_input
    script:
        """ 
        mkdir -p $RADTAGS_DIR
        bunzip2 -c < ${reads[0].baseName}.bz2 | gzip -c > ${reads[0].baseName}.gz 
        bunzip2 -c < ${reads[1].baseName}.bz2 | gzip -c > ${reads[1].baseName}.gz 
        """
}

// Perform quality analysis on renamed but yet uncleaned files
process fastqc_bz2 {
    conda 'fastqc'
    publishDir FASTQC_DIR, mode: 'copy', pattern: '*.html'
    publishDir FASTQC_DIR, mode: 'copy', pattern: '*.zip'
    publishDir LOG_DIR,    mode: 'copy', pattern: '*.log'
    maxForks 8
    input:
        file read from ch_fastqc_input.flatten()
    output:
        file '*.zip'  into ch_fastqc_bz2_zip
        file '*.html' into ch_fastqc_bz2_html
        file '*.log'  into ch_fastqc_bz2_log
    script:
        """
        mkdir -p ${FASTQC_DIR}
        fastqc ${read} 2> fastqc_${read.simpleName}_raw.log
        """
}

// Clean up data using the clean script of Stacks: process_radtags
process process_radtags_bz2 {
    conda 'stacks=2'
    maxForks 12
    input:
        set id, file(reads) from ch_radtags_input 
    afterScript "cd !{RADTAGS_DIR} | rename 's/clipped/cleaned/g' *"
    script:
        """
        process_radtags -1 ${reads[0]} -2 ${reads[1]} -o ${RADTAGS_DIR} -t ${READ_LENGTH} --renz_1 ${ENZYME1} ${ENZYME2} -r -c -q -y gzfastq
        cd ${RADTAGS_DIR}
        rename 's/clipped/cleaned/g' *
        """
}


// Perform quality analysis on renamed but yet uncleaned files
process fastqc_gz {
    conda 'fastqc'
    publishDir FASTQC_DIR, mode: 'copy', pattern: '*.html'
    publishDir FASTQC_DIR, mode: 'copy', pattern: '*.zip'
    publishDir LOG_DIR,    mode: 'copy', pattern: '*.log'
    maxForks 8
    input:
        file read from ch_fastqc_gz_input.flatten()
    output:
        file '*.zip'  into ch_fastqc_gz_zip
        file '*.html' into ch_fastqc_gz_html
        file '*.log'  into ch_fastqc_gz_log
    script:
        """
        echo ${read}
        mkdir -p ${FASTQC_DIR}
        fastqc ${read} 2> fastqc_${read.simpleName}_raw.log
        """
}

// Clean up data using the clean script of Stacks: process_radtags
process process_radtags_gz {
    conda 'stacks=2'
    maxForks 12
    input:
        set id, file(reads) from ch_radtags_gz_input 
    afterScript "cd !{RADTAGS_DIR} | rename 's/clipped/cleaned/g' *"
    script:
        """
        process_radtags -1 ${reads[0]} -2 ${reads[1]} -o ${RADTAGS_DIR} -t ${READ_LENGTH} --renz_1 ${ENZYME1} ${ENZYME2} -r -c -q -y gzfastq
        cd ${RADTAGS_DIR}
        rename 's/clipped/cleaned/g' *
        """
}
