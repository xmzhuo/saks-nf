process SAK {
    tag "# ${outputDir} swiss army knife (sak) nf without docker"
    cpus "$cpu"
    memory "$mem"
    time "$timeout"
    stageInMode 'copy' 
    echo true
    
    publishDir "$outputDir", mode: 'copy' 
   

    input:
    path input
    path upstream
    path script
    val advarg
    
    val cpu
    val mem
    val timeout
    val outputDir
     
    output:
    path "*" , emit: out
    
    shell:   
    """
    cpulog='.command.log'
    while :; do
        datechk=\$(date)
        cpufree=\$(top -b -n 1 | sed -n 3p | awk -F',' '{print \$1,\$4}')
        memfree=\$(top -b -n 1 | sed -n 4p | awk -F',' '{print \$1,\$2}')
        diskfree=\$(df -h / | sed -n 2p | awk '{print \$4"/"\$2}')
        echo "System Check: "\$datechk, \$cpufree, \$memfree, "Disk free: "\$diskfree
        sleep 300
        chk=\$(cat \$cpulog | grep '### job done' | wc -l)
        if [ \$chk -ge 1 ]; then break; fi
    done | tee -a \$cpulog &

    echo "input files check: !{input}"
    echo "upstream files check: !{upstream}"
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
    
    #rm advarg_temp.sh
    echo '### job done' >> \$cpulog
    """
}
