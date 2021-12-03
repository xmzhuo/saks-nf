# A json api for building and running nextflow workflow automaticlly
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
bash ./saks-nf/run.sh ./sak-nf/sak_data/example_io.json
```

```
Syntax: run.sh [-f|h|r|V|v]
    options:
    -f|--file         Json file as input.
    -h|--help         Print this Help.
    -r|--run          Running mode. run, otherwise compose
    -V|--version      Print software version and exit.
    -v|--verbose      Verbose.
```
* without -r, it only compose the workflow (recommend pratice when run it for the first time to do sanity check), you can manually run the pipeline with 'nextflow run /path/to/saks-nf' after passing your check with the workflow.
* with -r the nextflow will run right after the pipeline composed

input example files (json, bed, dict) locate in ./sak_data

### example_io.json is a demo for composing and run two process workflow. The first process uses gatk docker image to convert bed file to interval_list. The second process add chr to chromosome in interval_list. This example show the basic element of the json schema of saks-nf. 

```json
{
"title": "example saks-nf pipeline one process",                                    # Title of workflow
"description": "Proof of concept of a saks pipeline implemented with Nextflow",     # Description of workflow
"type": "workflow",                                                                 # Type 
"profile": "standard",                                                              # profile of choice (need to match the name in config file), standard (default on local machine), slurm (for hpc), azure, aws etc
"workdir": "./saks-work",                                                           # designate a work directory to store temporary files
"reportdir": "./saks-report",                                                       # designate a report directory to store timeline.html and report.html 
"process": {                                                                        
    "bed2interval" : {                                                              # process
        "name" : "bed2interval",                                                    # name of process, need to match the process name (recommend to use lowercase)
        "input" : {                                                                 # input files (allow wild card and some basic regex)
                "bed" : "./sak_data/*.bed",                                         # location of input files
                "dict" : "./sak_data/*.dict"
            }, 
        "output" : {                                                                # Output files (allow wild card and some basic regex)
            "file" : "*.interval_list",
            "log" : "*.log"
        },
        "upstream" : [""],                                                          # Upstream files, array format ["a","b"]. If not upstream file available such as the first process leave it as [""].
        "script" : "./sak_data/test.sh",                                            # Customized script for runing, any script as long as your evironment support it    
        "dockerimg" : "broadinstitute/gatk:4.2.2.0",                                # Docker image of choice, other wise leave it "".
        "argument" : "bash !{script} test.bed human_g1k_v37_decoy.dict",            # Allow some brief bash cmd (short and simple one line). As nextflow convention, variable for process params use !; others use $. 
        "outputDir" : "./results/bed2interval",                                     # Outpur Directory for this particular process, can be different for each process.
        "sakcpu" : "2",                                                             # Assign cpu cores for this process
        "sakmem" : "4.GB",                                                          # Assign memory for this process
        "saktime" : "1.hour"                                                        # Set timeout policy
    },
    "addchr" : {
        "name" : "addchr",                                                          # name of second process, need to match the process name (recommend to use lowercase)
        "input" : {
            "file" : ""                                                             # if not additional input 
        },
        "output" : {
            "file" : "*.interval_list",
            "log" : "*.log"
        },
        "upstream" : ["bed2interval.file"],                                         # assign specif output from upstream process
        "script" : "",                                                              # if not script is needed
        "dockerimg" : "",                                                           # use local environment rather than docker
        "argument" : "file=$(ls *.interval_list); cat $file | sed 's/^/chr/' > ${file%.*}.chr.interval_list",
        "outputDir" : "./results/addchr",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    }
}
}
```

### example_az.json is a demo for composing and above workflow on cloud environment. with minor change you can use it for aws et al.
```json
{
"title": "example saks-nf pipeline pipeline parameters",
"description": "Proof of concept of a saks pipeline implemented with Nextflow running on Azure cloud",
"type": "workflow",
"profile": "azure",                                                                 # set the profile as azure, you can change it to aws 
"workdir": "az://test/saks-work",                                                   # set the workdir on the cloud, if use aws, change to s3 accordingly
"reportdir": "./saks-report",                                                       # you can save the report on local or cloud location (may thraw a minor error message beacuse unable to change name etc, won't affect the normal running)
"process": {
    "bed2interval" : {
        "name" : "bed2interval",
        "input" : {
            "bed" : "./sak_data/*.bed",                                             # you can change it to a cloud location
            "dict" : "./sak_data/*.dict"
        },
        "output" : {
            "file" : "*.interval_list",
            "log" : "*.log"
        },
        "upstream" : [""],
        "script" : "./sak_data/test.sh",
        "dockerimg" : "broadinstitute/gatk:4.2.2.0",
        "argument" : "bash !{script} test.bed human_g1k_v37_decoy.dict",
        "outputDir" : "az://test/saks-results/bed2interval",                        # cloud location for ouput files 
        "sakcpu" : "4",
        "sakmem" : "4.GB",
        "saktime" : "1.hour",
        "queue" : "d4v3"                                                            # set queue of interest (you can change machine type for each queue in ./config/azure.cofig)
    },
    "addchr" : {
        "name" : "addchr",
        "input" : {
            "file" : ""
        },
        "output" : {
            "file" : "*.interval_list",
            "log" : "*.log"
        },
        "upstream" : ["bed2interval.file"],
        "script" : "",
        "dockerimg" : "xmzhuo/umi:2021",                                            # recommend to use a container in cloud environment, here just a small ubuntu image as example.
        "argument" : "file=$(ls *.interval_list); cat $file | sed 's/^/chr/' > ${file%.*}.chr.interval_list",
        "outputDir" : "az://test/saks-results/addchr",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour",
        "queue" : "d2v3"
    }
}
}
```

For running on cloud, please fill in the user name and credential in the config files accordingly or modify it to meet your need.
For Azure, you can configure the queue machine type directly on the azure.configure
For AWS, you can configure the queue machine type and policy on aws website. [Example from antunderwood](https://antunderwood.gitlab.io/bioinformant-blog/posts/running_nextflow_on_aws_batch/)

### result of 'bash saks-nf/run.sh saks-nf/example1.json'

1. Compose nextflow pipeline
Create a main.nf from template.nf; Create multiple sub-worflow porcess in ./module
2. Run nextflow and generate result
A interval_list file and a timestamped log file in ./results/bed2interval for process 1
A modified interval_list file and a timestamped log file in ./results/addchr for process 1
Timestamped timeline.html and report.html in ./saks-report 
Multiple tempoary files and docker/singularity image in work directory.

* For reference, All of the example Store in ./sak_example_output

## Credits
[Nextflow](https://github.com/nextflow-io/nextflow):  Paolo Di Tommaso

[Singularity](https://www.docker.com): Docker

[Singularity](https://singularity.lbl.gov): Singularityware

