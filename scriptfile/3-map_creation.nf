#!/usr/bin/env nextflow

//  Color styles for different types of messages.

def styleDefault = "\033[0m"
def styleInfo    = "\033[32;1m"
def styleWarn    = "\033[33;1m"
def styleError   = "\033[31;1m"

// *** FUNCTIONS ***

// Prints out the help for this nextflow script
def printHelp() {
    println "Options:"
    println "--workingDir      The outputDir of clean_reads.nf where the processed datasets are located. [mandatory]"
    println "--populationMap   The directory where the population map is located. [mandatory]"
    println "--dirName         The name of the directory in which the mapping and all follow up results are located (dirName of 2-sort_control_and_map.nf). [mandatory]"
    println "--refMapOnly      Flag can be used, when denovo map already exists. Only refmap is executed. [optional]"
    println "--help            A flag used to print this help."
}

// Prints out the usage of this nextflow script
def printUsage() {
    println ""
    println "You did not specify mendatory parameters. Multiple parameters are required!"
    println "Usage:"
    println "nextflow run 3-map_creation.nf --workingDir <path_to_working_directory> --populationMap <path_to_population_file> --dirName <name_of_the_file_where_mapping_output_is_piped_to (called like used reference genome) --refMapOnly <OPTIONAL: only ref_map.pl is executed (useful, when denovo_map.pl is already done)>"
    println styleInfo + "INFO: all locations must be specified as absolute path"
    println styleDefault
    println "If you require further information about the parameters please execute:"
    println "nextflow run 3-map_creation.nf --help"
    println ""
}


// *** PARAMETERS *** //

/*  @param workingDir       Path to current working directory [mandatory]
    @param populationMap    Path to the population map file [mandatory]
    @param dirName          Name of the file where the mapping outputs are saved to (preferably named after the used reference genome) [mandatory]
    @param refMapOnly       Flag to specify if only the ref_map.pl should be perfomed (when denovo_map.pl was already executed) [optional]
    @param help             A flag used to print out the help for using this pipeline */


// *** SANITY CHECKS *** //

// Stops pipeline execution if no parameters are specified. Prints out usage.
if (params.size() == 0) {
    print   styleError + "ERROR: Missing parameters. Exiting pipeline."
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
if (!params.workingDir || !params.populationMap || !params.dirName) {
    print styleError + "ERROR: Missing parameters. Exiting pipeline."
    println styleDefault
    printUsage()
    System.exit(0)
}

// Returns a short info whether or not denovo map is executed.
if(params.refMapOnly){
    println styleError + "INFO: You are not executing the denovo map pipeline."
    println styleDefault
 } else {
    println styleError + "INFO: You are executing the denovo map pipeline."
    println styleDefault

 }


// *** VARIABLES *** //

RADTAG_P_DIR    = params.workingDir + params.dirName + "/map_building_stacks/paired_read_files/"
SORTED_BAM_DIR  = params.workingDir + params.dirName + "/map_building_stacks/sorted_bam_files/"
REF_MAP_DIR     = params.workingDir + params.dirName + "/ref_map/"
DENOVO_MAP_DIR  = params.workingDir + "denovo_map/"


// *** CHANNELS *** //

// Generated a channel for the input files for denovo_map.pl
Channel.fromPath(RADTAG_P_DIR + "**.fq.gz")
    .set{ ch_de_novo_input }

// Generates a channel for the input files for ref_map.pl
Channel.fromPath(SORTED_BAM_DIR + "**.bam")
    .set{ ch_ref_map_input }

// Generates two channels with the population map for both map pipelines
Channel.fromPath(params.populationMap)
    .into{ ch_popmap_denovo_input; ch_popmap_refmap_input }


// *** PROCESSES *** //

// Process for the execution of the denovo_map.pl pipeline.
process creating_denovo_map {
    conda 'stacks'
    publishDir DENOVO_MAP_DIR, mode: 'copy'
    maxForks 12
    input:
        file popmap from ch_popmap_denovo_input
        file fq_files from ch_de_novo_input.collect()
    output:
        file '' into ch_de_novo_output
    when:
        !params.refMapOnly
    script:
        """
        mkdir -p ${DENOVO_MAP_DIR}
        denovo_map.pl --samples ${RADTAG_P_DIR} --popmap ${popmap} -o ${DENOVO_MAP_DIR} -T 20 -m 3 -M 3 -n 2 --paired
        """
}

// Process for the execution of the ref_map.pl pipeline.
process creating_ref_map {
    conda 'stacks'
    publishDir REF_MAP_DIR, mode: 'copy'
    maxForks 12
    input:
        file popmap from ch_popmap_refmap_input
        file bam_files from ch_ref_map_input
    output:
        file '' into ch_ref_map_output
    script:
        """
        mkdir -p ${REF_MAP_DIR}
        ref_map.pl --samples ${SORTED_BAM_DIR} --popmap ${popmap} -o ${REF_MAP_DIR} -T 20 
        """
}