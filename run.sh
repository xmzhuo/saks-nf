#!/usr/bin/env bash

############################################################
# Help                                                     #
############################################################
show_help(){ # Display Help
     show_version
cat << EOF
    script to automatically generate nextflow 
    bash run.sh -f example.json -r

    Syntax: run.sh [-f|h|r|n|V|v]
    options:
    -f|--file         Json file as input.
    -h|--help         Print this Help.
    -r|--run          Running mode. run, otherwise compose.
    -n|--nfname       Name and location for the new workflow. Otherwise it will be named to match json file at the same location.
    -V|--version      Print software version and exit.
    -v|--verbose      Verbose.

EOF
}

show_version(){ # Display Version
     echo "sak-nf:v0.0.2.1" 
}
############################################################
# Process the input options.                               #
############################################################

# Get the options
File="json"
Mode="compose"
verbose=0
nfname=''

while :; do
     case $1 in
         -h|-\?|--help)
             show_help    
             exit
             ;;
         -f|--file)       # Takes an option argument; ensure it has been specified.
             if [ "$2" ]; then
                 File=$2
                 shift
             else
                 die 'ERROR: "--file" requires a non-empty option argument.'
             fi
             ;;
         --file=?*)
             file=${1#*=} # Delete everything up to "=" and assign the remainder.
             ;;
         --file=)         # Handle the case of an empty --file=
             die 'ERROR: "--file" requires a non-empty option argument.'
             ;;
         -r|--run)
             Mode="run"  # running mode, otherwise composing only.
             ;;
         -n|--nfname)
             if [ "$2" ]; then
                 nfname=$2
                 shift
             else
                 die 'ERROR: "--nfname" requires a non-empty option argument.'
             fi
             ;;
         --nfname=?*)
             nfname=${1#*=} # Delete everything up to "=" and assign the remainder.
             ;;
         --nfname=)         # Handle the case of an empty --file=
             die 'ERROR: "--nfname" requires a non-empty option argument.'
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

#check if designate directory exist avoid overriding
if [ -d $nfname ]; then echo "$nfname exist, Please rename/remove it before running saks-nf"; exit 1; fi

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
    #get poutput keys from json
    outitem=$(cat $inputjson | jq .process.${step}.output | jq 'paths | join ("_")' -r)
    cat $inputjson | jq .process.${step}.output | grep :  | sed "s/\s\"//g" | sed 's/\"//g' | sed 's/\,$//' \
    | awk -F':' '{print "    path \""$2"\", emit:"$1}' > output.tmp

    #check argument and generate an insertion for argument shell script
    { echo $(cat $inputjson | jq .process | jq .${step} | jq .argument -r | sed 's/\$/\\$/g'); echo '2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log'; } | tr "\n" " " | sed 's/;/\n/g' > arg_temp.txt
    # generate process for step, first fix argument, then input, then output
    cat $nfname/modules/sak.nf | sed "s/SAK/${step^^}/" | sed '/#bash advarg_temp.sh/r arg_temp.txt' \
    | sed "s/path input/$inpath/" | sed "s/\!{input}/${invar}/" \
    | sed '/output:/r output.tmp' | grep -v ", emit: out"> $nfname/modules/${step}.nf
    
    cat $nfname/modules/sak_docker.nf | sed "s/SAK/${step^^}/" | sed '/#bash advarg_temp.sh/r arg_temp.txt' \
    | sed "s/path input/$inpath/" | sed "s/\!{input}/${invar}/" \
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
    | jq 'del(.upstream, .input, .output)' \
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
            upsteph=${upstep%.*}
            upstept=$(echo ${upstep} | sed 's/^.*\.//')
            upimg=$(cat $inputjson | jq .process | jq .${upstep}.dockerimg -r)
            #if [ $(echo $upimg | wc -c) -gt 1 ]; then upstep=${upstep^^}DOC.out; else upstep=${upstep^^}.out; fi
            if [ $(echo $upimg | wc -c) -gt 1 ]; then 
                upstep=${upsteph^^}DOC.out.${upstept}
            else 
                upstep=${upsteph^^}.out.${upstept}
            fi
        else
            upstep=""
        fi
        echo $upstep >> upitem.txt
    done 
   
    upitem=$(cat upitem.txt | sed 1d | sed 's/ /, /g')
    if [ $(echo $upitem | wc -c) -gt 5 ]; then upitem=".concat(${upitem})|collect"; else upitem=""; fi
    
    #compose step cmd example
    
    for item in $initem; do
        cat $nfname/template.nf | grep "* ## step cmd example" -A1 | sed 's/\*//' \
        | sed "s/Var_InFiles/${step^^}_${item}/g" | sed "s/params.input/params.${step}_input_${item}/g">> new_steps.txt  
    done
    itemfile=$(echo $(cat $inputjson | jq .process.${step}.input | jq 'paths | join ("_")' -r | sed "s/^/${step^^}_/") | sed 's/ /,/g')
    cat $nfname/template.nf | grep "* ## step cmd example" -A10 | tail -n9 | sed 's/\*//' \
    | sed "s/SAK/${step^^}/g" | sed "s/params./params.${step}_/g" | sed "s/Var_/${step^^}_/g" \
    | sed "s/.concat_upstream/$upitem/" | sed "s/${step^^}_InFiles/$itemfile/g" >> new_steps.txt

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