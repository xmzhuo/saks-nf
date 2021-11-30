#!/usr/bin/env bash
# script to automatically generate nextflow 
# bash run.sh ./example.json
current=`pwd`
DIRECTORY=`dirname $0`
#cd $DIRECTORY
#copy ./template.nf to ./main.nf
cp $DIRECTORY/template.nf $DIRECTORY/main.nf


#step1 input from json file
#name = 'step1'
#input = "$baseDir/data/input_sanitychk"
#script = "$baseDir/bin/script_sanitychk"
#dockerimg = ""
#argument = ""
#outputDir = 'results'
#sakcpu = "2"
#sakmem = "4.GB"
#saktime = "1.hour"


#inputjson='./example.json'
inputjson=$1
echo "" > new_params.txt
echo "" > new_steps.txt
echo "" > new_module.txt
echo "" > new_loginfo.txt
for step in $(cat $inputjson | jq .process | jq .[].name -r); do
    #echo $step
    #check argument and generate an insertion for argument shell script
    { echo $(cat $inputjson | jq .process | jq .${step} | jq .argument -r | sed 's/\$/\\$/g'); echo '2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log'; } | tr "\n" " " | sed 's/;/\n/g' > arg_temp.txt
    # generate process for step
    cat $DIRECTORY/modules/sak.nf | sed "s/SAK/${step^^}/" | sed '/#bash advarg_temp.sh/r arg_temp.txt' > $DIRECTORY/modules/${step}.nf
    cat $DIRECTORY/modules/sak_docker.nf | sed "s/SAK/${step^^}/" | sed '/#bash advarg_temp.sh/r arg_temp.txt' > $DIRECTORY/modules/${step}_docker.nf
    rm arg_temp.txt
    
    #compose params insertion
    cat $inputjson | jq .process | jq .${step} | grep -v '"upstream"'| grep ':' | sed "s/^\s*\"/params.${step}_/" | sed 's/\"\:/ =/' | sed 's/\,$//' | sed 's/\$/\\$/g'  >> new_params.txt
    
    #compose loginfo insertion
    cat $inputjson | jq .process | jq .${step} | sed 's/\$/\\$/g' | sed s/\"/\'/g >> new_loginfo.txt

    #compose module insertion
    echo "include { ${step^^} } from './modules/${step}'" >> new_module.txt
    echo "include { ${step^^}DOC } from './modules/${step}_docker'"  >> new_module.txt
    
    #chk upstream files (allow parse the json mulitple value in the form or array ['a','b','c']), and generate the concat line for all upstream input
    upitems=$(echo $(cat $inputjson | jq .process | jq .${step}.upstream[] -r))
    echo "" > upitem.txt
    for upstep in $upitems; do
        if [ $(echo $upstep | wc -c) -gt 1 ]; then
            upimg=$(cat $inputjson | jq .process | jq .${upstep}.dockerimg -r)
            if [ $(echo $upimg | wc -c) -gt 1 ]; then upstep=${upstep^^}DOC.out; else upstep=${upstep^^}.out; fi
        else
            upstep=""
        fi
        echo $upstep >> upitem.txt
    done 
    #upitem=$(echo $(cat $inputjson | jq .process | jq .${step}.upstream[] -r) | sed 's/ /, /g') 
    ##chk container status
    #upimg=$(cat $inputjson | jq .process | jq .${step}.dockerimg -r)
    ##upitem=$(echo ${upitem^^} | sed 's/.OUT/.out/') 
     
    #if [ $(echo $upimg | wc -c) -gt 1 ]; then upitem=${upitem^^}.out; else upitem=${upitem^^}DOC.out; fi
    upitem=$(cat upitem.txt | sed 1d | sed 's/ /, /g')
    if [ $(echo $upitem | wc -c) -gt 5 ]; then upitem=".concat(${upitem})|collect"; else upitem=""; fi
    
    #compose step cmd example

    cat $DIRECTORY/template.nf | grep "* ## step cmd example" -A10 | sed 's/\*//' \
    | sed "s/SAK/${step^^}/g" | sed "s/params./params.${step}_/g" | sed "s/params.${step}_defdir/params.defdir/g" | sed "s/Var_/${step^^}_/g" \
    | sed "s/.concat_upstream/$upitem/" >> new_steps.txt

done 
# add new params after "// compose params"
sed -i '/\/\/ compose params/r new_params.txt' $DIRECTORY/main.nf

# add new loginfo after "===log.info==="
sed -i '/===log.info===/r new_loginfo.txt' $DIRECTORY/main.nf

# include module after "// import modules"
sed -i '/\/\/ import modules/r new_module.txt' $DIRECTORY/main.nf

# include process after "// compose workflow"
sed -i '/\/\/ compose workflow/r new_steps.txt' $DIRECTORY/main.nf

#get profile from json
profile=$(cat $inputjson | jq .profile -r)
workdir=$(cat $inputjson | jq .workdir -r)
reportdir=$(cat $inputjson | jq .reportdir -r)
#run nextflow
nextflow run $DIRECTORY -profile ${profile} -w ${workdir} --outputDir ${reportdir}
timestamp=$(date '+%Y%m%d_%H%M')
mv ${reportdir}/timeline.html ${reportdir}/$(basename ${inputjson%.json}).${timestamp}.timeline.html
mv ${reportdir}/report.html ${reportdir}/$(basename ${inputjson%.json}).${timestamp}.report.html