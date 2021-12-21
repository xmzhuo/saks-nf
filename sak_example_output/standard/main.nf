#! /usr/bin/env nextflow
/*
 * SAK for Swiss Army Knife
 * created by Xinming Zhuo <xmzhuo@gmail.com> 
 * 
 */ 


nextflow.enable.dsl=2


def helpMessage() {
    log.info"""
    ================================================================
    saks-nf
    ================================================================
    DESCRIPTION
    SAKs for Swiss Army Knifes, a versatile nextflow to run many things 
    Usage:
    nextflow run xmzhuo/saks-nf

    Options for each process:
        --input             Input files  
        --script            optional: run your own script in nextflow, as long as your environment support the language of choice
        --dockerimg         optional: provide a docker image to work with
        --argument          cmdline argument
        --outputDir         Output directory ['results']
        --sakcpu            request cpu for task ['2']
        --sakmemory         reeuest memory for task ['4.GB']
        --saktime           time out policy ['1.hour']

    Profiles:
        standard            local execution
        slurm               SLURM execution with singularity on HPC
        azure               Azure (under development)
        aws                 AWS (under development)

    Author:
    Xinming Zhuo (xmzhuo@gmail.com)
    """.stripIndent()
}


params.help = false

if (params.help) {
    helpMessage()
    exit 0
}


/*
 * Defines some parameters in order to specify input and advance argument by using the command line options
 */

// compose params

params.bed2interval_name = "bed2interval"
params.bed2interval_script = "./sak_data/test.sh"
params.bed2interval_dockerimg = "broadinstitute/gatk:4.2.2.0"
params.bed2interval_argument = "bash !{script} test.bed human_g1k_v37_decoy.dict"
params.bed2interval_outputDir = "./results/bed2interval"
params.bed2interval_sakcpu = "2"
params.bed2interval_sakmem = "4.GB"
params.bed2interval_saktime = "1.hour"
params.bed2interval_input_bed = "./sak_data/test.bed"
params.bed2interval_input_dict = "./sak_data/*.dict"
params.addchr_name = "addchr"
params.addchr_script = ""
params.addchr_dockerimg = ""
params.addchr_argument = "file=\$(ls *.interval_list); cat \$file | sed 's/^/chr/' > \${file%.*}.chr.interval_list"
params.addchr_outputDir = "./results/addchr"
params.addchr_sakcpu = "2"
params.addchr_sakmem = "4.GB"
params.addchr_saktime = "1.hour"
params.addchr_input_file = ""
params.defdir = "$baseDir"
//
/*params.input = "$baseDir/data/input_sanitychk"
*params.input = "$baseDir/data/upstream_sanitychk"
*params.script = "$baseDir/bin/script_sanitychk"
*params.dockerimg = ""
*params.argument = ""
*params.outputDir = 'results'
*params.sakcpu = "2"
*params.sakmem = "4.GB"
*params.saktime = "1.hour"
*
*input_dir = file(params.input).parent
*/

log.info """\
         Swiss Army Knifes Battery  P I P E L I N E    
         ===log.info==========================

{
  'name': 'bed2interval',
  'input': {
    'bed': './sak_data/test.bed',
    'dict': './sak_data/*.dict'
  },
  'output': {
    'file': '*.interval_list',
    'log': '*.log'
  },
  'upstream': [
    ''
  ],
  'script': './sak_data/test.sh',
  'dockerimg': 'broadinstitute/gatk:4.2.2.0',
  'argument': 'bash !{script} test.bed human_g1k_v37_decoy.dict',
  'outputDir': './results/bed2interval',
  'sakcpu': '2',
  'sakmem': '4.GB',
  'saktime': '1.hour'
}
{
  'name': 'addchr',
  'input': {
    'file': ''
  },
  'output': {
    'file': '*.interval_list',
    'log': '*.log'
  },
  'upstream': [
    'bed2interval.file'
  ],
  'script': '',
  'dockerimg': '',
  'argument': 'file=\$(ls *.interval_list); cat \$file | sed 's/^/chr/' > \${file%.*}.chr.interval_list',
  'outputDir': './results/addchr',
  'sakcpu': '2',
  'sakmem': '4.GB',
  'saktime': '1.hour'
}
         
         """
         .stripIndent()


// import modules

include { BED2INTERVAL } from './modules/bed2interval'
include { BED2INTERVALDOC } from './modules/bed2interval_docker'
include { ADDCHR } from './modules/addchr'
include { ADDCHRDOC } from './modules/addchr_docker'

//
/*include { SAK } from './modules/sak'
*include { SAKDOC } from './modules/sak_docker'
*/


workflow {
    /*
    *
    */
    
    // compose workflow

    //* ## step cmd example SAK
    if(params.bed2interval_input_bed) {BED2INTERVAL_bed = Channel.fromPath(params.bed2interval_input_bed).toSortedList()} else {BED2INTERVAL_bed = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    //* ## step cmd example SAK
    if(params.bed2interval_input_dict) {BED2INTERVAL_dict = Channel.fromPath(params.bed2interval_input_dict).toSortedList()} else {BED2INTERVAL_dict = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    if(params.bed2interval_script) {BED2INTERVAL_ScriptFiles = Channel.fromPath(params.bed2interval_script).toSortedList()} else {BED2INTERVAL_ScriptFiles = Channel.fromPath("$baseDir" + "/bin/script_sanitychk")}
    
    if (params.bed2interval_dockerimg) {
        BED2INTERVALDOC(BED2INTERVAL_bed,BED2INTERVAL_dict,  BED2INTERVAL_ScriptFiles, params.bed2interval_argument, params.bed2interval_dockerimg, params.bed2interval_sakcpu, params.bed2interval_sakmem, params.bed2interval_saktime, params.bed2interval_outputDir)
    } else {
        BED2INTERVAL(BED2INTERVAL_bed,BED2INTERVAL_dict,  BED2INTERVAL_ScriptFiles, params.bed2interval_argument, params.bed2interval_sakcpu, params.bed2interval_sakmem, params.bed2interval_saktime, params.bed2interval_outputDir)   
    }
    //* ## step cmd example SAK
    if(params.addchr_input_file) {ADDCHR_file = Channel.fromPath(params.addchr_input_file).toSortedList()} else {ADDCHR_file = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    if(params.addchr_script) {ADDCHR_ScriptFiles = Channel.fromPath(params.addchr_script).toSortedList()} else {ADDCHR_ScriptFiles = Channel.fromPath("$baseDir" + "/bin/script_sanitychk")}
    
    if (params.addchr_dockerimg) {
        ADDCHRDOC(ADDCHR_file, BED2INTERVALDOC.out.file.collect(), ADDCHR_ScriptFiles, params.addchr_argument, params.addchr_dockerimg, params.addchr_sakcpu, params.addchr_sakmem, params.addchr_saktime, params.addchr_outputDir)
    } else {
        ADDCHR(ADDCHR_file, BED2INTERVALDOC.out.file.collect(), ADDCHR_ScriptFiles, params.addchr_argument, params.addchr_sakcpu, params.addchr_sakmem, params.addchr_saktime, params.addchr_outputDir)   
    }
    
    /*
    *//* ## step cmd example SAK
    *if(params.input) {Var_InFiles = Channel.fromPath(params.input).toSortedList()} else {Var_InFiles = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    *Var_UpStream = Channel.fromPath("$baseDir" + "/data/upstream_sanitychk").concat_upstream
    *Var_UpStream.view()
    *if(params.script) {Var_ScriptFiles = Channel.fromPath(params.script).toSortedList()} else {Var_ScriptFiles = Channel.fromPath("$baseDir" + "/bin/script_sanitychk")}
    *
    *if (params.dockerimg) {
    *    SAKDOC(Var_InFiles, Var_UpStream, Var_ScriptFiles, params.argument, params.dockerimg, params.sakcpu, params.sakmem, params.saktime, params.outputDir)
    *} else {
    *    SAK(Var_InFiles, Var_UpStream, Var_ScriptFiles, params.argument, params.sakcpu, params.sakmem, params.saktime, params.outputDir)   
    *}
    */
}


workflow.onComplete { 
    log.info """\
        sak-nf has finished.
        Status:   ${workflow.success ?  "Done!" : "Oops .. something went wrong"}
        Time:     ${workflow.complete}
        Duration: ${workflow.duration}\n
        """
        .stripIndent()
}
