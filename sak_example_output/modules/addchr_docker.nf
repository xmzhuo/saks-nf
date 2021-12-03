process ADDCHRDOC {
    tag "# ${outputDir}swiss army knife (sak) nf with docker: ${dockerimg}"
    cpus "$cpu"
    memory "$mem"
    time "$timeout"
    stageInMode 'copy' 
    echo true
    container "$dockerimg" 
    publishDir "$outputDir", mode: 'copy' 
   

    input:
    path file
    path upstream
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
    echo "input files check: !{file}"
    echo "upstream files check: !{upstream}"
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
file=\$(ls *.interval_list)
 cat \$file | sed 's/^/chr/' > \${file%.*}.chr.interval_list 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M).log 
    #rm advarg_temp.sh
    """
}
