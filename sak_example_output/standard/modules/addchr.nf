process ADDCHR {
    tag "# ${outputDir} swiss army knife (sak) nf without docker"
    cpus "$cpu"
    memory "$mem"
    time "$timeout"
    stageInMode 'copy' 
    echo true
    
    publishDir "$outputDir", mode: 'copy' 
   

    input:
    path file
    path bed2interval_file
    path script
    val advarg
    
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
    echo "upstream files check: !{bed2interval_file}"
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
file=\$(ls *.interval_list)
 cat \$file | sed 's/^/chr/' > \${file%.*}.chr.interval_list 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M%S).log 
outfileval=*.interval_list
logname=\$(ls *.log | grep sak-nf)
 echo "# md5sum #" >> \${logname}
md5sum \${outfileval} >> \${logname}
 logmd5=\$(md5sum \${logname} | sed "s/ /_/g")
 mv \${logname} \${logmd5}
    
    #rm advarg_temp.sh
    """
}
