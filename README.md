# An api for automatic building nextflow pipeline with json input
API for building pipeline from json input without writing nextflow code from scratch. Swiss Army Knife Solution for nextflow (saks-nf). <br />
Once run completely, saks-nf will generate a completed and ready-to-go nextflow workflow with default of designate name. User can choose to run it immediatley or run it later with 'nextflow run' after manual examiniation. <br />
User can build single process or multiple processes workflow with a json file. <br />
Saks is compatible with docker or local executer and run on various platform, such as local pc, hpc(slurm) or cloud with default config files in nextflow format (see example in ./config).  <br />
User can configure the requirement of the process,such as cpu, mem and timeout policy in the json file. <br />
By default, the workflow will generate timeline.html and report.html once the workflow complete in a user designate location. <br />
The user have the option to generate a log file as output, the md5sum with be appended to the end of log file. <br />
Since v0.0.3.0, saks support parallel by optionally including a "inputpairing" or "upstreampairing" key with pattern of interest. <br />
Since v0.0.4.0, saks support process specific string variable input, for example "name" will become a variable callable in the process by !{name}.
User can assign any key under the process element except the reserved items, such as the "input","output","upstream","inputpairing","upstreampairing","dockerimg","argument","script","sak*".   <br />

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
bash ./saks-nf/run.sh -i ./sak-nf/sak_data/example_io.json
```

```
    Syntax: run.sh [-i|h|r|o|f|V|v]
    options:
    -i|--input        Json file as input.
    -h|--help         Print this Help.
    -r|--run          Running mode. run, otherwise compose.
    -o|--output       Name and location for the new workflow. Otherwise it will be named to match json file at the same location.
    -f|--force        Force overwriting existing output (if exisit), otherwise exit.
    -V|--version      Print software version and exit.
    -v|--verbose      Verbose.
```
* without -r, it only compose the workflow (recommend pratice when run it for the first time to do sanity check), you can manually run the pipeline with 'nextflow run /path/to/saks-nf' after passing your check with the workflow.
* with -r the nextflow will run right after the pipeline composed

input example files (json, bed, dict) locate in ./sak_data


### * example_io.json is a demo for composing and run two process workflow. The first process uses gatk docker image to convert bed file to interval_list. The second process add chr to chromosome in interval_list. This example show the basic element of the json schema of saks-nf. The example nextflow script and result can be found in ./sak_example_output/standard.
![example](/sak_example_output/example-flowchart.png)

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
                "bed" : "./sak_data/test.bed",                                      # location of input files
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
        "upstream" : ["bed2interval.file"],                                         # assign specif output from upstream process, the specific upstream input is an available variable in the argument(to use the variable, process.out should be converted to process_out)
        "script" : "",                                                              # if not script is needed
        "dockerimg" : "",                                                           # use local environment rather than docker
        "argument" : "file=!{bed2interval_file}; cat $file | sed 's/^/chr/' > ${file%.*}.chr.interval_list",
        "outputDir" : "./results/addchr",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    }
}
}
```

### * example_az.json is a demo for composing and above workflow on cloud environment. with minor change you can use it for aws et al.

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
            "bed" : "./sak_data/test.bed",                                             # you can change it to a cloud location
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
For slurm, you may need to define the cpu and memory in sbatch sh (sometimes slurm won't recognize the command in certian hpc), it also recommend to compose first then nextflow run the new composed nextflow folder with -profile slurm


### * example_io-parallel.json is a demo for composing and run two process workflow when paralelization is need. The first process uses gatk docker image to convert 6 bed files to 3 interval_list. The pairing strategy is 4.large.bed concatenate with 4.small.bed and generate a 4.bed then convert the 4.bed to 4.bed.intervallist. This step is paralized by create three process,4.d, 5.bed and 6.bed. The second process collecting all the result (3) and add chr to chromosome in interval_list (3). This example show the basic element of the json schema of saks-nf. The example nextflow script and result can be found in ./sak_example_output/parallel.
![example-parallel](/sak_example_output/example-parallel-flowchart.png)

```json
{
"title": "example saks-nf pipeline pipeline parameters",
"description": "Proof of concept of a saks pipeline implemented with Nextflow",
"type": "workflow",
"profile": "standard",
"workdir": "./saks-work",
"reportdir": "./saks-report",
"process": {
    "bed2interval" : {
        "name" : "bed2interval",
        "input" : {
            "bed" : "./sak_data/*{small,large}.bed",
            "dict" : "./sak_data/*.dict"
        },
        "inputpairing" : {                                                         # Parallele is allowed by including a key and value of pairing strategy, by default the parallel is off if inputpair is not provided
            "bed" : ["large","small"]                                              # Define pairing strategy to input bed, with pattern "large" and "small" (4.large.bed pair with 4.small.bed, 3 prarallel processes),  or just leave it 
        },                                                                         # Alternatively, leave it as "bed" to allow parallele for all bed files (6 parallel processes).
        "output" : {
            "file" : "*.interval_list",
            "log" : "*.log"
        },
        "upstream" : [""],
        "script" : "./sak_data/test.sh",
        "dockerimg" : "broadinstitute/gatk:4.2.2.0",
        "argument" : "name=!{bed[0]}; echo $name; cat !{bed} > ${name%%.*}.bed; bash !{script} ${name%%.*}.bed human_g1k_v37_decoy.dict",
        "outputDir" : "./results/bed2interval",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    },
    "addchr" : {
        "name" : "addchr",
        "input" : {
            "file" : ""
        },
        "output" : {
            "file" : "*.interval_list"
        },
        "upstream" : ["bed2interval.file"],
        "script" : "",
        "dockerimg" : "",
        "argument" : "for file in !{bed2interval_file}; do cat $file |  awk '{if($1 !~ \"@\") $1=\"chr\"$1; print}' > ${file%.*}.chr.interval_list; done",
        "outputDir" : "./results/addchr",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    }
}
}
```


### * example_io-scattergather.json is a demo for composing and run scatter gather. The first process scatter a bed file by chromosome. The second process uses gatk docker image to convert each chromosome bed file to interval_list in prarallel. The third process collecting all the intervallist from all bed2interval processes and add chr to chromosome in interval_list. The example nextflow script and result can be found in ./sak_example_output/scattergather.
![example-scattergather](/sak_example_output/example-scattergather-flowchart.png)

```json
{
"title": "example saks-nf pipeline pipeline parameters",
"description": "Proof of concept of a saks pipeline implemented with Nextflow",
"type": "workflow",
"profile": "standard",
"workdir": "./saks-work",
"reportdir": "./saks-report",
"process": {
    "scatter" : {                                                        # Process of scatter input files and allow next process to run in parallel 
        "name" : "scatter",
        "input" : {
            "file" : "./sak_data/test.bed"
        },
        "output" : {
            "file" : "*.bed",
            "log" : "*.log"
        },
        "upstream" : [""],                                              
        "script" : "",
        "dockerimg" : "",
        "argument" : "for chr in $(cat !{file} | awk '{print $1}' | sort | uniq); do echo $chr; cat !{file} | awk -v var=$chr '{if($1 == var) print}' > $chr.bed; done",
        "outputDir" : "./results/scatter",
        "sakcpu" : "1",
        "sakmem" : "1.GB",
        "saktime" : "1.hour"
    },
    "bed2interval" : {
        "name" : "bed2interval",
        "input" : {
            "dict" : "./sak_data/*.dict"
        },
        "output" : {
            "file" : "*.interval_list",
            "log" : "*.log"
        },
        "upstream" : ["scatter.file"],
        "upstreampairing" : {                                            # Parallele is allowed by including a key and value of pairing strategy, by default the parallel is off if upstreampairing is not provided
            "scatter_file" : ["bed"]
        },
        "script" : "./sak_data/test.sh",
        "dockerimg" : "broadinstitute/gatk:4.2.2.0",
        "argument" : "bash !{script} !{scatter_file} human_g1k_v37_decoy.dict",
        "outputDir" : "./results/bed2interval",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
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
        "dockerimg" : "",
        "argument" : "for file in !{bed2interval_file}; do cat $file |  awk '{if($1 !~ \"@\") $1=\"chr\"$1; print}' > ${file%.*}.chr.interval_list; done",
        "outputDir" : "./results/addchr",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    }
}
}
```

### * example_val.json is a demo for v0.0.4.1, the principle is the same as example_io.json. It take a string input "chr" : "4" to subset test.bed file to chr4 only, and parse the environmental variable "val_var" as ouput of first step and feed to the second step as "bed2interval.val_var".

```json
{
"title": "example saks-nf pipeline pipeline parameters",
"description": "Proof of concept of a saks pipeline implemented with Nextflow",
"type": "workflow",
"profile": "standard",
"workdir": "./saks-work",
"reportdir": "./saks-report",
"process": {
    "bed2interval" : {
        "name" : "bed2interval",
        "description" : "only convert chrosome 4 to intevallist",
        "input" : {
            "bed" : "./sak_data/test.bed",
            "dict" : "./sak_data/*.dict"
        },
        "output" : {
            "file" : "*.interval_list",
            "log" : "*.log",
            "val_var" : "env"                                                                                   #output environment variable to next step, set value as 'env' and key with 'val_'
        },
        "chr" : "4",                                                                                            #add a string input to process
        "upstream" : [""],
        "script" : "./sak_data/test.sh",
        "dockerimg" : "broadinstitute/gatk:4.2.2.0",
        "argument" : "cat !{bed} | awk -v var=!{chr} '{if($1 == var) print}' > temp.bed; val_var=!{chr}; bash !{script} temp.bed human_g1k_v37_decoy.dict",
        "outputDir" : "./results/bed2interval",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
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
        "upstream" : ["bed2interval.file","bed2interval.val_var"],                                            #accept upstream input both in file path or value with prefix 'path_' or 'val_', recognize as path if without prefix  
        "script" : "",
        "dockerimg" : "",
        "argument" : "file=$(ls *.interval_list); cat $file | sed 's/^/chr/' > ${file%.*}.chr.interval_list; echo only generate interval_list for chr !{bed2interval_val_var[0]}",     
        "outputDir" : "./results/addchr",
        "sakcpu" : "2",
        "sakmem" : "4.GB",
        "saktime" : "1.hour"
    }
}
}
```


### result of 'bash saks-nf/run.sh saks-nf/example.json' is exhibited in ./sak_example_output, seperate into standard, parallel and scattergather accordinly.

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

[JSON](https://www.json.org) : JSON

[Docker](https://www.docker.com): Docker

[Singularity](https://singularity.lbl.gov): Singularityware

### Notes
The "argument" in json does not support some operation for native variable !{var}; such as !{var%.txt}. It aslo does not support sed for escaping special character, such as sed 's/\.*//' . <br />
You can run docker directly from "argument", such as "docker run --rm -v $(pwd):$(pwd) broadinstitute/gatk gatk", which can be used to run multiple docker in one process as long as your environment support docker <br />


Shield: [![CC BY-NC 4.0][cc-by-nc-shield]][cc-by-nc]

This work is licensed under a
[Creative Commons Attribution-NonCommercial 4.0 International License][cc-by-nc].

[![CC BY-NC 4.0][cc-by-nc-image]][cc-by-nc]

[cc-by-nc]: http://creativecommons.org/licenses/by-nc/4.0/
[cc-by-nc-image]: https://licensebuttons.net/l/by-nc/4.0/88x31.png
[cc-by-nc-shield]: https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg
