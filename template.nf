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
         
         """
         .stripIndent()


// import modules

//
/*include { SAK } from './modules/sak'
*include { SAKDOC } from './modules/sak_docker'
*/


workflow {
    /*
    *
    */
    
    // compose workflow
    
    /*
    *//* ## step cmd example SAK
    *if(params.input) {Var_InFiles = Channel.fromPath(params.input).toSortedList()} else {Var_InFiles = Channel.fromPath(params.defdir + "/data/input_sanitychk")}
    *Var_UpStream = Channel.fromPath(params.defdir + "/data/upstream_sanitychk").concat_upstream
    *Var_UpStream.view()
    *if(params.script) {Var_ScriptFiles = Channel.fromPath(params.script).toSortedList()} else {Var_ScriptFiles = Channel.fromPath(params.defdir + "/bin/script_sanitychk")}
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
