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
    println "--referenceDir   The directory where the data files in .fna format are located. [mandatory]"
    println "--outputDir      The directory where the indexed references are saved to. [mandatory]"
    println "--help           A flag used to print this help."
    println ""
}

// Prints out the usage of this nextflow script
def printUsage() {
    println ""
    println "You did not specify mendatory parameters. Multiple parameters are required!"
    println "Usage:"
    println "nextflow run 1-prepare_reference_genome.nf --referenceDir <path_to_input_directory_with_.fna_files> --outputDir <path_to_output_directory>"
    println styleInfo + "INFO: all locations must be specified as absolute path"
    println styleDefault
    println "If you require further information about the parameters please execute:"
    println "nextflow run 1-prepare_reference_genome.nf --help"
    println ""
}


// *** PARAMETERS *** //

/*  @param referenceDir     Path to directory where the .fna files for indexing of the reference genome are located [mendatory]
    @param outputDir        Path to directory where the indices are saved [mandatory]
    @param dirName          Name of the directory where the indexed reference is saved [mandatory]
    @param help             A flag used to print out the help for using this pipeline [optional] */


// *** SANITY CHECKS *** //

// Stops pipeline execution if no parameters are specified. Prints out usage.
if (params.size() == 0) {
    print   styleError+"ERROR: Missing parameters. Exiting pipeline."
    println styleDefault
    printUsage()
    System.exit(0)
}

params.help = false

// If --help is submitted the pipelines stops and prinHelp() is executed.
if (params.help) {
    printHelp()
    System.exit(0)
}

// If mandatory parameters are not set, the system prints out an error.
else if (!params.referenceDir || !params.outputDir ) {
    print styleError + "ERROR: Missing parameters. Exiting pipeline."
    println styleDefault
    printUsage()
    System.exit(0)
}


// *** VARIABLES *** //

INDEX_DIR  = params.outputDir


// *** CHANNEL ** //

// Creates channel for reference in the given directory `referenceDir`
Channel.fromPath(params.referenceDir + '/*.fna*')
    .into{ ch_references_index_input; ch_copy_fna }


// *** PROCESSES *** //

/*  Creating a large bowtie2 index for each reference genome/trancriptome provided. 
    Index files are being copied into `INDEX_DIR` and are prefixed with the basename of the reference 
    file. Log files are being copied into `LOG_DIR`, prefixed with the basename of the reference file. */
    
process bowtie_index {
    conda 'bowtie2'
    publishDir INDEX_DIR, mode: 'copy', pattern: '*.bt2l'
    publishDir INDEX_DIR, mode: 'copy', pattern: '*.log'
    maxForks 24
    input:
        file reference_file from ch_references_index_input
    output:
        file '*.bt2l' into ch_bowtie_index_output
        file '*.log'  into ch_bowtie_log
    shell:
    '''
    mkdir -p !{INDEX_DIR}
    reference_name="$(basename !{reference_file} .fna.gz)"
    bowtie2-build --threads 24 --large-index !{reference_file} $reference_name 2> bowtie_index_${reference_name}.log
    '''
}

// Copying the .fna.gz file to the index file directory as it is needed later on for mapping.
process keep_fna {
    publishDir INDEX_DIR
    stageInMode 'copy'
    errorStrategy 'ignore'
    input:
        file fna_file from ch_copy_fna
    output:
        file '' into ch_fna_output
    script:
    """
    mkdir -p ${INDEX_DIR}
    mv ${fna_file} ${INDEX_DIR}
    """
}