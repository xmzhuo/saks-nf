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
    path bed
path dict
    
    path script
    val advarg
    val dockerimg
    val cpu
    val mem
    val timeout
    val outputDir
     
    output:
    path "*.interval_list", emit: file
    path "*.log", emit: log

    shell:   
    """
    echo "input files check: !{bed}, !{dict}"
    echo "upstream files check: "
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
name=!{bed[0]}
 echo \$name
 cat !{bed} > \${name%%.*}.bed
 bash !{script} \${name%%.*}.bed human_g1k_v37_decoy.dict 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M%S).log 
outfileval=*.interval_list
logname=\$(ls *.log | grep sak-nf)
 echo "# md5sum #" >> \${logname}
md5sum \${outfileval} >> \${logname}
 logmd5=\$(md5sum \${logname} | sed "s/ /_/g")
 mv \${logname} \${logmd5}

    #rm advarg_temp.sh
    """
}
