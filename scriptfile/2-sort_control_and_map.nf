#!/usr/bin/env nextflow

 // Color styles for different types of messages.

def styleDefault = "\033[0m"
def styleInfo    = "\033[32;1m"
def styleWarn    = "\033[33;1m"
def styleError   = "\033[31;1m"

// *** FUNCTIONS ***

// Prints out the help for this nextflow script
def printHelp() {
    println "Options:"
    println "--workingDir      The outputDir of clean_reads.nf where the processed datasets are located. [mandatory]"
    println "--referenceDir    The directory where the reference are located. [optional]"
    println "--dirName         The name of the directory in which the mapping and all follow up results are located. [mandatory]"
    println "--mappingOnly     Flag which specifies that quality control is not carried out (in case it is already performed and thus no needed again) [optional]"
    println "--help            A flag used to print this help."
}

// Prints out the usage of this nextflow script
def printUsage() {
    println ""
    println "You did not specify mendatory parameters. Multiple parameters are required!"
    println "Usage:"
    println "nextflow run 2-sort_control_and_map.nf --workingDir <path_to_working_directory> --referenceDir <path_to_where_the_prepared_reference_files_are_located> --dirName <name_of_the_file_where_mapping_output_is_piped_to (preferably called like used reference genome) --mappingOnly <OPTIONAL: only mapping is performed (useful, when quality control is already done)>"
    println styleInfo + "INFO: all locations must be specified as absolute path"
    println styleDefault
    println "If you require further information about the parameters please execute:"
    println "nextflow run 2-sort_control_and_map.nf --help"
    println ""
}


// *** PARAMETERS *** //

/*  @param workingDir       Path to current working directory [mandatory]
    @param referenceDir     Path to directory where the reference genome is located [mandatory]
    @param dirName          Name of the file where the mapping outputs are saved to (preferably named after the used reference genome) [mandatory]
    @param mappingOnly      Flag to specify if only the mapping should be perfomed (when quality control was already executed) [optional]
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
if (!params.workingDir || !params.dirName ) {
    print styleError + "ERROR: Missing parameters. Exiting pipeline."
    println styleDefault
    printUsage()
    System.exit(0)
}

// Returns a short info why the quality control processes are not perfomed.
if(params.mappingOnly){
    println styleError + "INFO: You are not executing the quality control."
    println styleDefault
}


// *** VARIABLES *** //

// Generation of variables for the directories of intermediate and final results of the pipeline
LOG_DIR         = params.workingDir + "log_files"
RADTAGS_DIR     = params.workingDir + "cleaning/process_radtags/"
RADTAG_P_DIR    = params.workingDir + params.dirName + "/map_building_stacks/paired_read_files/"

FASTQC_DIR      = params.workingDir + "quality_control/fastqc_raw"
FASTQC_CLN_DIR  = params.workingDir + "quality_control/fastqc_cleaned"
MULTIQC_DIR     = params.workingDir + "quality_control/multiqc_all"

SAM_DIR         = params.workingDir + params.dirName + "/mapping/sam_files"
BAM_DIR         = params.workingDir + params.dirName + "/mapping/bam_files"
SORTED_BAM_DIR  = params.workingDir + params.dirName + "/map_building_stacks/sorted_bam_files/"


// *** CHANNELS *** //

// Creates channel for reference in the given directory `referenceDir`
Channel.fromPath(params.referenceDir + '*.fna*')
    .set{ ch_references_mapping }

// Creates channel for import of bowtie2 index files
Channel.fromPath(params.referenceDir + '*.bt2l')
    .set{ ch_bowtie_index }

// Creates channel for read in file pairs of cleaned reads for mapping
Channel.fromFilePairs(RADTAGS_DIR + '*{1,2}_cleaned.?.fq.gz')
    .set{ ch_bowtie_input }

// Creates channel for process_radtags cleaned reads from the RADTAGS_DIR directory
Channel.fromPath(RADTAGS_DIR + '*_cleaned.?.fq.gz')
    .into{ ch_fastqc_cleaned_input; ch_move_cleaned_reads_input }

// Creates channel for multiqc summary
Channel.fromPath(FASTQC_DIR + '/*.zip')
    .set { ch_fastqc_zip }


// *** PROCESSES *** //

/*  Mapping the reads to all reference genomes/trancriptomes provided. The mapping files are being 
    copied into `SAM_DIR` and are prefixed with the basename of the read and the reference file.
    Log files are copied into `LOG_DIR`, prefixed with the basename of the read. */
    
process move_cleaned_reads {
    stageInMode 'copy'
    input:
        file remaining from ch_move_cleaned_reads_input.collect()
    output:
        file '' into ch_move_cleaned_reads_output
    script:
        """
        mkdir -p ${RADTAG_P_DIR}
        mv ${remaining} ${RADTAG_P_DIR}
        cd ${RADTAG_P_DIR}
        rename 's/_R[1,2]_cleaned//g' *
        """
}
/*  Takes all fastq files and analyse them with FastQC.
    ZIP and html files are piped into two different channels.
    Log files are piped into the `LOG_DIR` */

process fastqc_cleaned {
    conda 'fastqc'
    publishDir FASTQC_CLN_DIR, mode: 'copy', pattern: '*.html'
    publishDir FASTQC_CLN_DIR, mode: 'copy', pattern: '*.zip'
    publishDir LOG_DIR,        mode: 'copy', pattern: '*.log'
    maxForks 8
    input:
        file read from ch_fastqc_cleaned_input.flatten()
    output:
        file '*.zip'  into ch_fastqc_zip_cleaned
        file '*.html' into ch_fastqc_html
        file '*.log'  into ch_fastqc_log
    when:
        !params.mappingOnly
    script:
        """
        fastqc ${read} 2> fastqc_${read.simpleName}_cleaned.log
        """
}

/*  Process all fastqc files with multiqc. Creates a quality report as a html file. 
    Report is copied into `MULTIQC_DIR`. Log files are copied into `LOG_DIR` and are suffixed 
    with the basename of the multiqc file. */ 

process multiqc {
    conda 'multiqc'
    publishDir MULTIQC_DIR, mode: 'copy', pattern: '*.html'
    publishDir MULTIQC_DIR, mode: 'copy', pattern: 'multiqc_data/*'
    publishDir LOG_DIR,     mode: 'copy', pattern: '*.log'
    input:
        file fastqc_zip_files from ch_fastqc_zip.collect()
        file fastqc_zip_files_cleaned from ch_fastqc_zip_cleaned.collect()
    output:
        file '*.html' into ch_multiqc_report_output
        file 'multiqc_data/*' into ch_multiqc_data_output
        file '*.log' into ch_multiqc_log
    when:
        !params.mappingOnly
    script:
    """
    multiqc -f ${fastqc_zip_files} ${fastqc_zip_files_cleaned} 2> multiqc.log
    """
}

/*  Mapping of the cleaned reads against the specified reference genome.
    Complex input structure ensures availability of all files needed for mapping are accessible at each
    iteration of the process.
    Log files are saved in the LOG_DIR */

process bowtie_mapping {
    conda 'bowtie2'
    publishDir SAM_DIR, mode: 'copy', pattern: '*.sam'
    publishDir LOG_DIR, mode: 'copy', pattern: '*.log'
    maxForks 8
    input:
        set id, file(reads), file(reference_file), file(indexes_a) from ch_bowtie_input.combine(ch_references_mapping.merge(ch_bowtie_index.collect().toList()))
    output:
        file '*.sam' into ch_bowtie_mapping
        file '*.log' into ch_bowtie_mapping_log
    shell:
    '''
    index_dir="$(basename !{reference_file} .fna.gz)"
    bowtie2 --threads 20 --very-sensitive-local -x $index_dir -1 !{reads[0]} -2 !{reads[1]} -S !{reads[0].simpleName}_${index_dir}_mapping.sam 2> bowtie_mapping_!{reads[0].simpleName}.log
    '''
}


/*  Removing all unaligned reads and creating a BAM file. All files are being copied into `BAM_DIR`
    and are named with the basename of the mapping file. Log files are copied into `LOG_DIR and are 
    suffixed with the basename of the mapping file. */

process samtools_unmapped {
    conda 'samtools'
    publishDir BAM_DIR, mode: 'copy', pattern: '*.bam'
    publishDir LOG_DIR, mode: 'copy', pattern: '*.log'
    maxForks 2
    input:
        file mapping from ch_bowtie_mapping
    output:
        file '*.bam' into ch_samtools_unmapped_output
        file '*.log' into ch_samtools_unmapped_log
    script:
    """
    samtools view --threads 6 -bh -F 4 ${mapping} > ${mapping.baseName}.bam 2> samtools_unmapped_${mapping.baseName}.log
    """
}

// Sorting the .bam files as this is required for the creation of the reference map of stacks later on.
process samtools_sort {
    conda 'samtools'
    publishDir SORTED_BAM_DIR, mode: 'copy', pattern: '*_sorted.bam'
    publishDir LOG_DIR,        mode: 'copy', pattern: '*.log'
    maxForks 2
    input:
        file bam_file from ch_samtools_unmapped_output
    output:
        file '*_sorted.bam' into ch_samtools_sorted_output
        file '*.log'        into ch_samtools_sorted_log
    script:
    """
    mkdir -p ${SORTED_BAM_DIR}
    samtools sort --threads 10 -o ${bam_file.baseName}_sorted.bam ${bam_file.baseName}.bam 2> samtools_sort_${bam_file.baseName}.log
    """
}

// Renames the .bam files for the ref_map.pl execution. Otherwise, the pipeline would not "find" the files specified in the population map.
process rename_bam_files {
    input:
        file sorted_bam from ch_samtools_sorted_output.collect()
    output:
        file '' into ch_rename_output
    script:
    """
    cd ${SORTED_BAM_DIR}
    rename 's/(_R1)(.*)(\\.)/\\./g' *
    """
}