process SCATTERDOC {
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
    
    path script
    val advarg
    val dockerimg
    val cpu
    val mem
    val timeout
    val outputDir
     
    output:
    path "*.bed", emit: file
    path "*.log", emit: log

    shell:   
    """
    echo "input files check: !{file}"
    echo "upstream files check: "
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
for chr in \$(cat !{file} | awk '{print \$1}' | sort | uniq)
 do echo \$chr
 cat !{file} | awk -v var=\$chr '{if(\$1 == var) print}' > \$chr.bed
 done 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M%S).log 
outfileval=*.bed
logname=\$(ls *.log | grep sak-nf)
 echo "# md5sum #" >> \${logname}
md5sum \${outfileval} >> \${logname}
 logmd5=\$(md5sum \${logname} | sed "s/ /_/g")
 mv \${logname} \${logmd5}

    #rm advarg_temp.sh
    """
}
