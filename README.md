# A nextflow workflow for automatic building pipeline with json input
Workflow for building pipeline from json input without writing code from scratch. Once run completely, saks-nf will generate a complete and ready-to-go nextflow workflow, user can choose to rerun it with 'nextflow run' instead.
User can build single process or multiple processes workflow with a simple json file (example1.json for single process, example.json for multiple process) 
It is compatible with docker or local executer and run on various platform, such as local pc, hpc(slurm) or cloud with default config files in nextflow format (see example in ./config). 
User can configure the requirement of the process,such as cpu, mem and timeout policy in the json file.
By default, the workflow will generate timeline.html and report.html once the workflow complete in a user designate location.

## Installation

### Nextflow
Install `nextflow` following the [instructions](https://www.nextflow.io/docs/latest/getstarted.html).

Be sure to run at least Nextflow version 21.04.3.

### Docker or Singularity
saks-nf compatible with docker.
Install `docker` following the instructions at
https://docs.docker.com/get-docker/

Alternativly, some HPC or user may choose using Singularity.
Install `singularity` following the instructions at
https://singularity.lbl.gov/install-linux

### saks-nf pipeline

The most convenient way is to install `saks-nf` is to git clone the xmzhuo/saks-nf

## Documentation

* saks-nf: Workflows for for building 

```bash
bash saks-nf/run.sh saks-nf/example1.json
```

### example1.json is a demo for composing and run one process workflow. It uses gatk docker image to convert bed file to interval_list. This example show the basic element of the json schema of saks-nf. 
```json
"title": "example saks-nf pipeline one process",                                    # Title of workflow
"description": "Proof of concept of a saks pipeline implemented with Nextflow",     # Description of workflow
"type": "workflow",                                                                 # Type 
"profile": "standard",                                                              # profile of choice, standard (default on local machine), slurm (for hpc), azure, aws etc
"workdir": "./work",                                                                # designate a work directory to store temporary files
"reportdir": "./saks-report",                                                       # designate a report directory to store timeline.html and report.html 
"process": {                                                                        
    "bed2interval" : {                                                              # process
        "name" : "bed2interval",                                                    # name of process, need to match the process name (recommend to use lowercase)
        "input" : "./sak_data/*.{bed,dict}",                                        # input files (ideally put all input files in one folder, allow wild card and some basic regex) 
        "upstream" : [""],                                                          # Upstream files, array format ["a","b"]. If not upstream file available such as the first process leave it as [""].
        "script" : "./sak_data/test.sh",                                            # Customized script for runing, any script as long as your evironment support it    
        "dockerimg" : "broadinstitute/gatk:4.2.2.0",                                # Docker image of choice, other wise leave it "".
        "argument" : "bash !{script} test.bed human_g1k_v37_decoy.dict",            # Allow some brief bash cmd (short and simple one line). As nextflow convention, variable for process params use !; other use $. 
        "outputDir" : "./results/bed2interval",                                     # Outpur Directory for this particular process, can be different for each process.
        "sakcpu" : "2",                                                             # Assign cpu cores for this process
        "sakmem" : "4.GB",                                                          # Assign memory for this process
        "saktime" : "1.hour"                                                        # Set timeout policy
    }
}

```

### example.json is a demo for composing and run two process workflow. Base on example1.json, it add one process to add chr to chromosome in interval_list.
```json
"title": "example saks-nf pipeline pipeline parameters",
"description": "Proof of concept of a saks pipeline implemented with Nextflow",
"type": "workflow",
"profile": "standard",
"workdir": "./saks-work",
"reportdir": "./saks-report",
"process": {
    "bed2interval" : {
        "name" : "bed2interval",
        "input" : "./sak_data/*.{bed,dict}",
        "upstream" : [""],
        "script" : "./sak_data/test.sh",
        "dockerimg" : "broadinstitute/gatk:4.2.2.0",
        "argument" : "bash !{script} test.bed human_g1k_v37_decoy.dict",
        "outputDir" : "./results/bed2interval",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    },
    "addchr" : {                                
        "name" : "addchr",                                                            # second process name
        "input" : "",                                                                 # not external input for this process  
        "upstream" : ["bed2interval"],                                                # take the output of upstream process   
        "script" : "",                                                                # no script provide since this is a simple step  
        "dockerimg" : "",                                                             # no docker image is need (as long as your environment supper the one line cmd in the argument)
        "argument" : "file=$(ls *.interval_list); cat $file | sed 's/^/chr/' > ${file%.*}.chr.interval_list",
        "outputDir" : "./results/addchr",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    }
}
```

### result of 'bash saks-nf/run.sh saks-nf/example1.json'
1. Compose nextflow pipeline
Create a main.nf from template.nf; Create multiple sub-worflow porcess in ./module
2. Run nextflow and generate result
A interval_list file and a timestamped log file in ./results/bed2interval for process 1
A modified interval_list file and a timestamped log file in ./results/addchr for process 1
Timestamped timeline.html and report.html in ./saks-report 
Multiple tempoary files and docker/singularity image in work directory.

## Credits
[Nextflow](https://github.com/nextflow-io/nextflow):  Paolo Di Tommaso

[Singularity](https://www.docker.com): Docker

[Singularity](https://singularity.lbl.gov): Singularityware

