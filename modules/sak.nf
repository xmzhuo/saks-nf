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
    set -euxo pipefail
    cpulog='.command.log'
    maxtime=!{timeout}
    chkperd=300
    maxchk=\$(awk -v time=\${maxtime%.*} -v chkr=\${chkperd} 'BEGIN{print time*60*60/chkr}')
    chkn=0
    while :; do
        datechk=\$(date)
        cpufree=\$(top -b -n 1 | sed -n 3p | awk -F',' '{print \$1,\$4}')
        memfree=\$(top -b -n 1 | sed -n 4p | awk -F',' '{print \$1,\$2}')
        diskfree=\$(df -h / | sed -n 2p | awk '{print \$4"/"\$2}')
        echo "System Check: "\$datechk, \$cpufree, \$memfree, "Disk free: "\$diskfree
        sleep \${chkperd}
        chk=\$(cat \$cpulog | grep '### job done' | wc -l)
        if [ \$chk -ge 1 ]; then break; fi
        chkcount=\$(expr \$chkn + 1)
        if [ \$chkn -ge \$maxchk ]; then break; fi
    done | tee -a \$cpulog &

    echo "input files check: !{input}"
    echo "upstream files check: !{upstream}"
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
    
    #rm advarg_temp.sh
    echo '### job done' >> \$cpulog
    cp \$cpulog command.log
    """
}
