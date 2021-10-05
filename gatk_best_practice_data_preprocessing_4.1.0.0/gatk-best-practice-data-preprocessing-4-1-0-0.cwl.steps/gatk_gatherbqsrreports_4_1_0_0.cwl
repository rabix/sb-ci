cwlVersion: v1.0
class: CommandLineTool
label: GATK GatherBQSRReports CWL1.0
doc: |-
  **GATK GatherBQSRReports** gathers scattered BQSR recalibration reports into a single file [1].

  *A list of **all inputs and parameters** with corresponding descriptions can be found at the bottom of the page.*


  ### Common Use Cases 

  * This tool is intended to be used to combine recalibration tables from runs of **GATK BaseRecalibrator** parallelized per-interval.

  * Usage example:
  ```
     gatk --java-options "-Xmx2048M" GatherBQSRReports \
     --input input1.csv \
     --input input2.csv \
     --output output.csv

  ```


  ###Changes Introduced by Seven Bridges

  * The output file will be prefixed using the **Output name prefix** parameter. If this value is not set, the output name will be generated based on the **Sample ID** metadata value from **Input BQSR reports**. If the **Sample ID** value is not set, the name will be inherited from the **Input BQSR reports** file name. In case there are multiple files on the **Input BQSR reports** input, the files will be sorted by name and output file name will be generated based on the first file in the sorted file list, following the rules defined in the previous case. Moreover, **.recal_data** will be added before the extension of the output file name.

  * The following GATK parameters were excluded from the tool wrapper: `--arguments_file`, `--gatk-config-file`, `--gcs-max-retries`, `--gcs-project-for-requester-pays`, `--help`, `--QUIET`, `--showHidden`, `--tmp-dir`, `--use-jdk-deflater`, `--use-jdk-inflater`, `--verbosity`, `--version`


  ###Common Issues and Important Notes

  *  **Memory per job** (`mem_per_job`) input allows a user to set the desired memory requirement when running a tool or adding it to a workflow. This input should be defined in MB. It is propagated to the Memory requirements part and “-Xmx” parameter of the tool. The default value is 2048MB.

  * **Memory overhead per job** (`mem_overhead_per_job`) input allows a user to set the desired overhead memory when running a tool or adding it to a workflow. This input should be defined in MB. This amount will be added to the Memory per job in the Memory requirements section but it will not be added to the “-Xmx” parameter. The default value is 100MB. 


  ###Performance Benchmarking

  This tool is fast, with a running time of a few minutes. The experiment task was performed on the default AWS on-demand c4.2xlarge instance on 50 CSV files (size of each ~350KB) and took 2 minutes to finish ($0.02).

  *Cost can be significantly reduced by using **spot instances**. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*


  ###References

  [1] [GATK GatherBQSRReports](https://gatk.broadinstitute.org/hc/en-us/articles/360036359192-GatherBQSRReports)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: '$(inputs.cpu_per_job ? inputs.cpu_per_job : 1)'
  ramMin: |-
    ${
      var memory = 2048;
      
      if(inputs.mem_per_job) {
      	 memory = inputs.mem_per_job;
      }
      if(inputs.mem_overhead_per_job) {
    	memory += inputs.mem_overhead_per_job;
      }
      else {
          memory += 100;
      }
      return memory;
    }
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/marijeta_slavkovic/gatk-4-1-0-0:0
- class: InitialWorkDirRequirement
  listing: []
- class: InlineJavascriptRequirement
  expressionLib:
  - |2-

    var setMetadata = function(file, metadata) {
        if (!('metadata' in file)) {
            file['metadata'] = {}
        }
        for (var key in metadata) {
            file['metadata'][key] = metadata[key];
        }
        return file
    };
    var inheritMetadata = function(o1, o2) {
        var commonMetadata = {};
        if (!o2) {
            return o1;
        };
        if (!Array.isArray(o2)) {
            o2 = [o2]
        }
        for (var i = 0; i < o2.length; i++) {
            var example = o2[i]['metadata'];
            for (var key in example) {
                if (i == 0)
                    commonMetadata[key] = example[key];
                else {
                    if (!(commonMetadata[key] == example[key])) {
                        delete commonMetadata[key]
                    }
                }
            }
            for (var key in commonMetadata) {
                if (!(key in example)) {
                    delete commonMetadata[key]
                }
            }
        }
        if (!Array.isArray(o1)) {
            o1 = setMetadata(o1, commonMetadata)
            if (o1.secondaryFiles) {
                o1.secondaryFiles = inheritMetadata(o1.secondaryFiles, o2)
            }
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
                if (o1[i].secondaryFiles) {
                    o1[i].secondaryFiles = inheritMetadata(o1[i].secondaryFiles, o2)
                }
            }
        }
        return o1;
    };

inputs:
- id: in_bqsr_reports
  label: Input BQSR reports
  doc: |-
    List of scattered BQSR report files. This argument must be specified at least once.
  type: File[]
  inputBinding:
    position: 4
    valueFrom: |-
      ${
         if (inputs.in_bqsr_reports)
         {
             var bqsr_reports = [].concat(inputs.in_bqsr_reports);
             var cmd = [];
             for (var i = 0; i < bqsr_reports.length; i++)
             {
                 cmd.push('--input', bqsr_reports[i].path);
             }
             return cmd.join(' ');
         }
         return '';
      }
    itemSeparator: 'null'
    shellQuote: false
  sbg:altPrefix: -I
  sbg:category: Required Arguments
  sbg:fileTypes: CSV
- id: prefix
  label: Output name prefix
  doc: Output prefix for the gathered BQSR report.
  type: string?
  sbg:category: Config Inputs
- id: mem_per_job
  label: Memory per job
  doc: |-
    It allows a user to set the desired memory requirement (in MB) when running a tool or adding it to a workflow.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '2048'
- id: mem_overhead_per_job
  label: Memory overhead per job
  doc: |-
    It allows a user to set the desired overhead memory (in MB) when running a tool or adding it to a workflow.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '100'
- id: cpu_per_job
  label: CPU per job
  doc: Number of CPUs to be used per job.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '1'

outputs:
- id: out_gathered_bqsr_report
  label: Gathered BQSR report
  doc: File to output the gathered file to.
  type: File?
  outputBinding:
    glob: '*.csv'
    outputEval: $(inheritMetadata(self, inputs.in_bqsr_reports))
  sbg:fileTypes: CSV

baseCommand:
- /opt/gatk-4.1.0.0/gatk --java-options
arguments:
- prefix: ''
  position: 1
  valueFrom: |-
    ${
        if (inputs.mem_per_job) {
            return '\"-Xmx'.concat(inputs.mem_per_job, 'M') + '\"';
        } else {
            return '\"-Xmx2048M\"';
        }
    }
  shellQuote: false
- prefix: ''
  position: 2
  valueFrom: GatherBQSRReports
  shellQuote: false
- prefix: --output
  position: 3
  valueFrom: |-
    ${
        //sort list of input files by nameroot
        function sortNameroot(x, y) {
            if (x.nameroot < y.nameroot) {
                return -1;
            }
            if (x.nameroot > y.nameroot) {
                return 1;
            }
            return 0;
        }
            
        var output_prefix;
        var output_ext;
        var in_num = [].concat(inputs.in_bqsr_reports).length;
        var output_ext = ".csv";
        var in_bqsr_reports = [].concat(inputs.in_bqsr_reports);
        
        //if input_prefix is provided by the user
        if (inputs.prefix) {
            output_prefix = inputs.prefix;
            if (in_num > 1) {
                output_prefix = output_prefix + '.' + in_num;
            }
        }
        else {
            //if there is only one input file
            if(in_num == 1){
                // check if the sample_id metadata value is defined for the input file
                if(in_bqsr_reports[0].metadata && in_bqsr_reports[0].metadata.sample_id) {
                    output_prefix = in_bqsr_reports[0].metadata.sample_id;
                // if sample_id is not defined
                } else {
                    output_prefix = in_bqsr_reports[0].path.split('/').pop().split('.')[0];
                }
            }
            //if there are more than 1 input files
            //sort list of input file objects alphabetically by file name 
            //take the first element from that list, and generate output file name as if that file is the only file on the input. 
            else if(in_num > 1) {
                //sort list of input files by nameroot
                in_bqsr_reports.sort(sortNameroot);
                //take the first alphabetically sorted file
                var first_file = in_bqsr_reports[0];
                //check if the sample_id metadata value is defined for the input file
                if(first_file.metadata && first_file.metadata.sample_id) {
                    output_prefix = first_file.metadata.sample_id + '.' + in_num;
                // if sample_id is not defined
                } else {
                    output_prefix = first_file.path.split('/').pop().split('.')[0] + '.' + in_num;
                }
            }
        }
        var output_full = output_prefix + ".recal_data" + output_ext;
        return output_full;
    }
  shellQuote: false
id: h-3e432399/h-4a45e64d/h-1eb57fad/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BAM Processing
- CWL1.0
sbg:content_hash: a0739e0aa57b81afb0485d881aae41db8b23cce8d2153fc5715a7794c934f0edb
sbg:contributors:
- nens
- uros_sipetic
- marijeta_slavkovic
sbg:createdBy: uros_sipetic
sbg:createdOn: 1554810073
sbg:id: h-3e432399/h-4a45e64d/h-1eb57fad/0
sbg:image_url:
sbg:latestRevision: 14
sbg:license: BSD 3-Clause License
sbg:links:
- id: https://www.broadinstitute.org/gatk/index.php
  label: Homepage
- id: https://github.com/broadinstitute/gatk
  label: Source Code
- id: |-
    https://github.com/broadinstitute/gatk/releases/download/4.1.0.0/gatk-4.1.0.0.zip
  label: Download
- id: https://www.ncbi.nlm.nih.gov/pubmed?term=20644199
  label: Publication
- id: https://gatk.broadinstitute.org/hc/en-us/articles/360036359192-GatherBQSRReports
  label: Documentation
sbg:modifiedBy: marijeta_slavkovic
sbg:modifiedOn: 1603192324
sbg:project: uros_sipetic/gatk-4-1-0-0-demo
sbg:projectName: GATK 4.1.0.0 - Demo
sbg:publisher: sbg
sbg:revision: 14
sbg:revisionNotes: description edited (usage example, memory in description etc)
sbg:revisionsInfo:
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1554810073
  sbg:revision: 0
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/8
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1554894740
  sbg:revision: 1
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/11
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557487015
  sbg:revision: 2
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/13
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557734524
  sbg:revision: 3
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/17
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557744219
  sbg:revision: 4
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/22
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000599
  sbg:revision: 5
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/23
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351550
  sbg:revision: 6
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/24
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558451160
  sbg:revision: 7
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbqsrreports-4-1-0-0/25
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1593698671
  sbg:revision: 8
  sbg:revisionNotes: New wrapper
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1593699134
  sbg:revision: 9
  sbg:revisionNotes: Description review suggestions added
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1593780288
  sbg:revision: 10
  sbg:revisionNotes: performance benchmarking cost edited
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1594045532
  sbg:revision: 11
  sbg:revisionNotes: naming description - added one sentence
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1594045569
  sbg:revision: 12
  sbg:revisionNotes: ''
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1598131313
  sbg:revision: 13
  sbg:revisionNotes: added [].concat to arrays
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1603192324
  sbg:revision: 14
  sbg:revisionNotes: description edited (usage example, memory in description etc)
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.0.0
sbg:validationErrors: []
