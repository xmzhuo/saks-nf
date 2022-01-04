#!/usr/bin/env bash

############################################################
# Help                                                     #
############################################################
show_help(){ # Display Help
     show_version
cat << EOF
    script to automatically generate nextflow 
    bash run.sh -f example.json -r

    Syntax: run.sh [-i|h|r|o|f|V|v]
    options:
    -i|--input        Json file as input.
    -h|--help         Print this Help.
    -r|--run          Running mode. run, otherwise compose.
    -o|--output       Name and location for the new workflow. Otherwise it will be named to match json file at the same location.
    -f|--force        Force overwriting existing output (if exisit), otherwise exit.
    -V|--version      Print software version and exit.
    -v|--verbose      Verbose.

EOF
}

show_version(){ # Display Version
     echo "sak-nf:v0.0.3.2" 
}
############################################################
# Process the input options.                               #
############################################################

# Get the options
File="json"
Mode="compose"
verbose=0
nfname=''
Force='Not'

while :; do
     case $1 in
         -h|-\?|--help)
             show_help    
             exit
             ;;
         -i|--input)       # Takes an option argument; ensure it has been specified.
             if [ "$2" ]; then
                 File=$2
                 shift
             else
                 die 'ERROR: "--file" requires a non-empty option argument.'
             fi
             ;;
         --input=?*)
             file=${1#*=} # Delete everything up to "=" and assign the remainder.
             ;;
         --input=)         # Handle the case of an empty --file=
             die 'ERROR: "--file" requires a non-empty option argument.'
             ;;
         -r|--run)
             Mode="run"  # running mode, otherwise composing only.
             ;;
         -o|--output)
             if [ "$2" ]; then
                 nfname=$2
                 shift
             else
                 die 'ERROR: "--nfname" requires a non-empty option argument.'
             fi
             ;;
         --output=?*)
             nfname=${1#*=} # Delete everything up to "=" and assign the remainder.
             ;;
         --output=)         # Handle the case of an empty --file=
             die 'ERROR: "--nfname" requires a non-empty option argument.'
             ;;
         -f|--force)
             Force="force"  # running mode, otherwise composing only.
             ;;
         -V|--version)
             show_version
             exit   # print version.
             ;;
         -v|--verbose)
             verbose=$((verbose + 1))  # Each -v adds 1 to verbosity.
             ;;
         --)              # End of all options.
             shift
             break
             ;;
         -?*)
             printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
             show_help
             ;;
         *)               # Default case: No more options, so break out of the loop.
             break
     esac
 
     shift
done

echo $File $Mode 

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
# script to automatically generate nextflow 
# bash run.sh ./example.json
current=`pwd`
DIRECTORY=`dirname $0`
if [ $nfname ]; then echo $nfname; else nfname=${File%.*}-nf; echo $nfname; fi

#check if designate directory exist avoid overriding if not force flag
if [ -d $nfname ]; then
    if [ $Force == 'force' ]; then
        rm $nfname -r
    else 
        echo "$nfname exist, Please rename/remove it before running saks-nf"
        exit 1
    fi
fi

cp $DIRECTORY $nfname -r
#cd $DIRECTORY

#switch directory to avoid occasional java version error in nextflow
cd $nfname
cd $current

#copy ./template.nf to ./main.nf
#cp $DIRECTORY/template.nf $DIRECTORY/main.nf
cp $nfname/template.nf $nfname/main.nf

#inputjson='./example.json'
inputjson=$File

#get profile from json
profile=$(cat $inputjson | jq .profile -r)

echo "" > new_params.txt
echo "" > new_steps.txt
echo "" > new_module.txt
echo "" > new_loginfo.txt
for step in $(cat $inputjson | jq .process | jq .[].name -r); do
    #echo $step
    ##changes for the module 
    #get input keys from json
    initem=$(cat $inputjson | jq .process.${step}.input | jq 'paths | join ("_")' -r)
    inpath=$(echo $(cat $inputjson | jq .process.${step}.input | jq 'paths | join ("_")' -r | sed "s/^/path__/") | sed 's/ /\\n/g' | sed 's/__/ /g')
    invar=$(echo $(cat $inputjson | jq .process.${step}.input | jq 'paths | join ("_")' -r | sed 's/^/!{/' | sed 's/$/}/') | sed 's/ /, /g')
    #get upstream keys from json, convert bed2interval.file to bedeinterval_file for vriable handeling
    upitem=$(cat $inputjson | jq .process.${step}.upstream | jq 'join (" ")' -r | sed 's/\./_/g')
    uppath=$(echo $(cat $inputjson | jq .process.${step}.upstream | jq 'join ("\n")' -r | sed 's/\./_/g' | sed 's/^/path__/') | sed 's/ /\\n/g' | sed 's/__/ /g' )
    upvar=$(echo $(cat $inputjson | jq .process.${step}.upstream | jq 'join ("\n")' -r | sed 's/\./_/g' | sed 's/^/!{/' | sed 's/$/}/') | sed 's/ /, /g')
    if [ $(echo $upitem | wc -c) -lt 5 ]; then uppath=""; upvar=""; fi

    #get output keys from json
    outitem=$(cat $inputjson | jq .process.${step}.output | jq 'paths | join ("_")' -r)
    cat $inputjson | jq .process.${step}.output | grep :  | sed "s/\s\"//g" | sed 's/\"//g' | sed 's/\,$//' \
    | awk -F':' '{print "    path \""$2"\", emit:"$1}' > output.tmp

    #check argument and generate an insertion for argument shell script
    { echo $(cat $inputjson | jq .process | jq .${step} | jq .argument -r | sed 's/\$/\\$/g'); echo '2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M%S').log'; } | tr "\n" " " | sed 's/;/\n/g' > arg_temp.txt
    echo "" >> arg_temp.txt
    #echo "outfileval=$(cat $inputjson | jq .process.${step}.output | jq 'join ("\n")' -r | grep -v .log)" >> arg_temp.txt
    echo "outfileval=\"$(cat $inputjson | jq .process.${step}.output | jq 'join (" ")' -r | sed 's/\*.log//')\"" >> arg_temp.txt
    echo 'logname=\$(ls *.log | grep sak-nf); echo "# md5sum #" >> \${logname};md5sum \${outfileval} >> \${logname}; logmd5=\$(md5sum \${logname} | sed "s/ /_/g"); mv \${logname} \${logmd5}' | sed 's/;/\n/g' >> arg_temp.txt
    
    # generate process for step, first fix argument, then input, then output
    cat $nfname/modules/sak.nf | sed "s/SAK/${step^^}/" | sed '/#bash advarg_temp.sh/r arg_temp.txt' \
    | sed "s/path input/$inpath/" | sed "s/\!{input}/${invar}/" \
    | sed "s/path upstream/$uppath/" | sed "s/\!{upstream}/${upvar}/" \
    | sed '/output:/r output.tmp' | grep -v ", emit: out"> $nfname/modules/${step}.nf
    
    cat $nfname/modules/sak_docker.nf | sed "s/SAK/${step^^}/" | sed '/#bash advarg_temp.sh/r arg_temp.txt' \
    | sed "s/path input/$inpath/" | sed "s/\!{input}/${invar}/" \
    | sed "s/path upstream/$uppath/" | sed "s/\!{upstream}/${upvar}/" \
    | sed '/output:/r output.tmp' | grep -v ", emit: out"> $nfname/modules/${step}_docker.nf
    
    #cat $nfname/modules/sak_docker.nf | sed "s/SAK/${step^^}/" | sed '/#bash advarg_temp.sh/r arg_temp.txt' > $nfname/modules/${step}_docker.nf
    rm arg_temp.txt output.tmp
 
    #allow queue setting for process with cloud
    if [ $(echo 'azure|aws|gcp' | grep $profile | wc -l) -gt 0 ]; then 
        queue=$(cat $inputjson | jq .process | jq .${step} | jq .queue -r)
        sed -i "/echo true/a\    queue \"${queue}\"" $nfname/modules/${step}.nf
        sed -i "/echo true/a\    queue \"${queue}\"" $nfname/modules/${step}_docker.nf
    fi
    
    ###change the main.nf
    #compose params insertion, first exclude upstream, input and output, then clean up the format, finally handle the $ in argument
    cat $inputjson | jq .process | jq .${step} \
    | jq 'del(.upstream, .input, .output, .inputpairing, .upstreampairing)' \
    | grep ':' | sed "s/^\s*\"/params.${step}_/" | sed 's/\"\:/ =/' | sed 's/\,$//' \
    | sed 's/\$/\\$/g'  >> new_params.txt
    
    #add input items to params insertion
    for key in 'input'; do
        cat $inputjson | jq .process.${step}.input \
        | grep ':' | sed "s/^\s*\"/params.${step}_input_/" | sed 's/\"\:/ =/' | sed 's/\,$//' >> new_params.txt
    done

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
            upstepkey=$(echo $upstep | sed 's/\./_/g') #get the key in pairing
            pairpattern=$(cat $inputjson | jq ".process.${step}.upstreampairing.${upstepkey} | length")
            #modify the upstream input to meet process
            upsteph=${upstep%.*}
            upstept=$(echo ${upstep} | sed 's/^.*\.//')
            upimg=$(cat $inputjson | jq .process | jq .${upsteph}.dockerimg -r) #fix an issue with the upstream process name upstep > upsteph
            
            if [ $(echo $upimg | wc -c) -gt 1 ]; then 
                upstep="${upsteph^^}DOC.out.${upstept}.collect()"
            else 
                upstep="${upsteph^^}.out.${upstept}.collect()"
            fi
            #allow parallel of the upstream input
            if [ $pairpattern -gt 0 ]; then 
                upstep=${upstep}'.sort().flatten().buffer(size:'$pairpattern')'
            fi
        else
            upstep=""
        fi
        echo $upstep >> upitem.txt
    done 
   
    #upitem=$(cat upitem.txt | sed 1d | sed 's/ /, /g')
    #if [ $(echo $upitem | wc -c) -gt 5 ]; then upitem=".concat(${upitem})|collect"; else upitem=""; fi
    upitem=$(echo $(cat upitem.txt | sed 1d) | sed 's/ /, /g')
    if [ $(echo $upitem | wc -c) -gt 5 ]; then upitem="$upitem,"; fi

    #compose step cmd example
    
    for item in $initem; do
        pairpattern=$(cat $inputjson | jq ".process.${step}.inputpairing.$item | length")
        if [ $pairpattern -gt 0 ]; then 
            #inputitem=$(ls $(cat $inputjson | jq .process.${step}.input.${item} -r) | grep $pairpattern | sed "s/${pairpattern}/\*/")
            #regroup files by pattern number as pairing, allow parallel processing
            cat $nfname/template.nf | grep "* ## step cmd example" -A1 | sed 's/\*//' \
            | sed "s/fromPath(params.input).toSortedList()/fromPath(params.input).toSortedList().flatten().buffer(size : $pairpattern)/g" \
            | sed "s/Var_InFiles/${step^^}_${item}/g" | sed "s/params.input/params.${step}_input_${item}/g" >> new_steps.txt 
        else
            cat $nfname/template.nf | grep "* ## step cmd example" -A1 | sed 's/\*//' \
            | sed "s/Var_InFiles/${step^^}_${item}/g" | sed "s/params.input/params.${step}_input_${item}/g">> new_steps.txt 
        fi 
    done
    itemfile=$(echo $(cat $inputjson | jq .process.${step}.input | jq 'paths | join ("_")' -r | sed "s/^/${step^^}_/") | sed 's/ /,/g')
    cat $nfname/template.nf | grep "* ## step cmd example" -A10 | tail -n9 | sed 's/\*//' \
    | sed "s/SAK/${step^^}/g" | sed "s/params./params.${step}_/g" | sed "s/Var_/${step^^}_/g" \
    | grep -v "${step^^}_UpStream.view" | grep -v "${step^^}_UpStream =" \
    | sed "s/${step^^}_InFiles/$itemfile/g" | sed "s/${step^^}_UpStream,/$upitem/g" >> new_steps.txt
    #| sed "s/.concat_upstream/$upitem/" | sed "s/${step^^}_InFiles/$itemfile/g" >> new_steps.txt

done 
# add new params after "// compose params"
sed -i '/\/\/ compose params/r new_params.txt' $nfname/main.nf

# add new loginfo after "===log.info==="
sed -i '/===log.info===/r new_loginfo.txt' $nfname/main.nf

# include module after "// import modules"
sed -i '/\/\/ import modules/r new_module.txt' $nfname/main.nf

# include process after "// compose workflow"
sed -i '/\/\/ compose workflow/r new_steps.txt' $nfname/main.nf

rm new_params.txt new_loginfo.txt new_module.txt new_steps.txt upitem.txt

rm $nfname/template.nf $nfname/modules/sak_docker.nf $nfname/modules/sak.nf $nfname/run.sh
rm $nfname/sak_data -r
rm $nfname/sak_example_output -r
#get directory for work and report
workdir=$(cat $inputjson | jq .workdir -r)
reportdir=$(cat $inputjson | jq .reportdir -r)

if [ $Mode == 'run' ]; then
    #run nextflow
    nextflow run $nfname -profile ${profile} -w ${workdir} --outputDir ${reportdir}
    #chk if report is local or not
    if [ $(echo $reportdir | grep "://" | wc -l) -eq 0 ]; then
        timestamp=$(date '+%Y%m%d_%H%M')
        mv ${reportdir}/timeline.html ${reportdir}/$(basename ${inputjson%.json}).${timestamp}.timeline.html
        mv ${reportdir}/report.html ${reportdir}/$(basename ${inputjson%.json}).${timestamp}.report.html
    fi
fi