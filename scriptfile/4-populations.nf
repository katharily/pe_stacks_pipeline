#!/usr/bin/env nextflow

//  Color styles for different types of messages.

def styleDefault = "\033[0m"
def styleInfo    = "\033[32;1m"
def styleWarn    = "\033[33;1m"
def styleError   = "\033[31;1m"

// *** FUNCTIONS ***

// Prints out the help for this nextflow script
def printHelp() {
    println "Execution options:"
    println "--inputDir           The input directory where the Stacks data are located. [mandatory]"
    println "--outputDir          Output directory. [mandatory]"
    println "--populationMap      Path to population map file. [mandatory]"
    println "--ref                Specify if data provided is mapped against a reference (not denovo) [flag] [optional]"
    println ""
    println "Filter options:"
    println "--p [ int ]   min-populations         minimum number of populations a locus must be present in to process a locus."
    println "--r [float]   min-samples-per-pop     minimum percentage of individuals in a population required to process a locus for that population." 
    println "--R [float]   min-samples-overall     minimum percentage of individuals across populations required to process a locus."
    println "--H           filter-haplotype-wise   apply the above filters haplotype wise (unshared SNPs will be pruned to reduce haplotype-wise missing data)."
    println ""
    println "--minMaf    [float]                   specify a minimum minor allele frequency required to process a nucleotide site at a locus (0 < min_maf < 0.5)."
    println "--minMac    [ int ]                   specify a minimum minor allele count required to process a SNP."
    println "--maxObsHet [float]                   specify a maximum observed heterozygosity required to process a nucleotide site at a locus."
    println ""
    println "--writeSingleSnp                      restrict data analysis to only the first SNP per locus."
    println "--writeRandomSnp                      restrict data analysis to one random SNP per locus."
    println ""
    println "--blacklist                           path to a file containing Blacklisted markers to be excluded from the export."
    println "--whitelist                           path to a file containing Whitelisted markers to include in the export."
    println ""
    println "--help                                A flag used to print this help."
}

// Prints out the usage of this nextflow script
def printUsage() {
    println ""
    println "You did not specify mendatory parameters. Multiple parameters are required!"
    println "Usage:"
    println "nextflow run 4-populations.nf --inputDir <path_to_input_directory> --outputDir <path_to_output_directory> --populationMap <Path to population map file> [--ref <if files were aligned against reference>] [filter options; see --help for details]"
    println styleError + "INFO: all locations must be specified as absolute path"
    println styleDefault
    println "If you require further information about the parameters please execute:"
    println "nextflow run 4-populations.nf --help"
    println ""
}


// *** PARAMETERS *** //

/*  @param inputDir         Path to the current working directory [mandatory]
    @param outputDir        Path to the output directory [mandatory]
    @param populationMap    Path to the population map file [mandatory]
    @param ref              Flag to specify whether the input data was aligned against a reference genome [optional]
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
if (!params.inputDir || !params.outputDir || !params.populationMap) {
    print styleError + "ERROR: Missing parameters. Exiting pipeline."
    println styleDefault
    printUsage()
    System.exit(0)
}


// *** VARIABLES *** //

INPUT_DIR               = params.inputDir
OUTPUT_DIR              = params.outputDir

MIN_POPULATIONS         = ""
MIN_SAMPLES_PER_POP     = ""
MIN_SAMPLES_OVERALL     = ""
FILTER_HAPLOTYPE_WISE   = ""
MIN_MAF                 = ""
MIN_MAC                 = ""
MAX_OBS_HET             = ""
WRITE_SINGLE_SNP        = ""
WRITE_RANDOM_SNP        = ""
BLACKLIST               = ""
WHITELIST               = ""

REF_OUTPUT              = ""

if(params.p){ 
    MIN_POPULATIONS = "-p " + params.p 
}
if(params.r){
    MIN_SAMPLES_PER_POP = "-r " + params.r 
}
if(params.R){
    MIN_SAMPLES_OVERALL = "-R " + params.R 
}
if(params.H){
    FILTER_HAPLOTYPE_WISE = "-H"
}
if(params.minMaf){
     MIN_MAF = "--min-maf " + params.minMaf 
}
if(params.minMac){
    MIN_MAC = "--min-mac " + params.minMac 
}
if(params.maxObsHet){
    MAX_OBS_HET = "--max-obs-het " + params.maxObsHet 
}
if(params.writeSingleSnp){
    WRITE_SINGLE_SNP = "--write-single-snp" 
}
if(params.writeRandomSnp){
    WRITE_RANDOM_SNP = "--write-random-snp" 
}
if(params.blacklist){
    BLACKLIST = "-B " + params.blacklist 
}
if(params.whitelist){
    WHITELIST = "-W " + params.whitelist 
}

if(params.ref) {
    REF = "--ordered-export"
}

// *** CHANNELS *** //

Channel.fromPath(params.populationMap)
    .set{ ch_popmap_input }


// *** PROCESSES *** //

process populations {
conda 'stacks=2'
publishDir OUTPUT_DIR, mode: 'copy'
input:
    file popmap from ch_popmap_input
output:
    file '' into ch_populations_output
script:
    """
    mkdir -p ${OUTPUT_DIR}
    populations -P ${INPUT_DIR} -O ${OUTPUT_DIR} -M ${popmap} -t 24 \
    --hwe --fstats \
    ${MIN_POPULATIONS} ${MIN_SAMPLES_PER_POP} ${MIN_SAMPLES_OVERALL} ${FILTER_HAPLOTYPE_WISE} ${MIN_MAF} ${MIN_MAC} \
    ${MAX_OBS_HET} ${WRITE_SINGLE_SNP} ${WRITE_RANDOM_SNP} ${BLACKLIST} ${WHITELIST} \
    ${REF_OUTPUT} --fasta-loci --fasta-samples --vcf --genepop --structure --hzar --phylip --phylip-var --treemix --fasta-samples-raw \
    --log-fst-comp 
    """
}

//
