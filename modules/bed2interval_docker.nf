process BED2INTERVALDOC {
    tag "# ${outputDir}swiss army knife (sak) nf with docker: ${dockerimg}"
    cpus "$cpu"
    memory "$mem"
    time "$timeout"
    stageInMode 'copy' 
    echo true
    container "$dockerimg" 
    publishDir "$outputDir", mode: 'copy' 
   

    input:
    path input
    path upstream
    path script
    val advarg
    val dockerimg
    val cpu
    val mem
    val timeout
    val outputDir
     
    output:
    path "*" , emit: out

    shell:   
    """
    echo "input files check: !{input}"
    echo "upstream files check: !{upstream}"
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
bash !{script} test.bed human_g1k_v37_decoy.dict 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M).log 
    #rm advarg_temp.sh
    """
}