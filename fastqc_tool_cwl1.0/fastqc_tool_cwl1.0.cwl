cwlVersion: v1.0
class: CommandLineTool
label: FastQC CWL 1.0
doc: |-
  **Note:** This version of this tool is for testing purposes regarding github actions and CI/CD only. Changes vs the public tool are purely to run tests and should't affect functionality, but this version is not supported by SBG in production.

  **FastQC** reads a set of sequence files and produces a quality control report from each one. These reports consist of a number of different modules, each of which will help identify a different type of potential problem in your data [1].

  *A list of **all inputs and parameters** with corresponding descriptions can be found at the end of the page.*

  ### Common Use Cases

  **FastQC** is a tool which takes a FASTQ file and runs a series of tests on it to generate a comprehensive QC report.  This report will tell you if there is anything unusual about your sequence.  Each test is flagged as a pass, warning, or fail depending on how far it departs from what you would expect from a normal large dataset with no significant biases.  It is important to stress that warnings or even failures do not necessarily mean that there is a problem with your data, only that it is unusual.  It is possible that the biological nature of your sample means that you would expect this particular bias in your results.

  - In order to search the library for specific adapter sequences, a TXT file with the adapter sequences needs to be provided on the **Adapters** (`--adapters/-a`) input port. The lines in the file must follow the name [tab] sequence format.
  - In order to search the overrepresented sequences for specific contaminants, a TXT file with the contaminant sequences needs to be provided on the **Contaminants** (`--contaminants/-c`) input port. The lines in the file must follow the name [tab] sequence format.
  - In order to determine the warn/error limits for the various modules or remove some modules from the output, a TXT file with sets of criteria needs to be provided on the **Limits** (`--limits/-l`) input port. The lines in the file must follow the parameter [tab] warn/error [tab] value format.


  ### Changes introduced by Seven Bridges

  No modifications to the original tool representation have been made.


  ### Common Issues and Important Notes

  User can manually set CPU/Memory requirements by providing values on the **Number of CPUs** and **Memory per job [MB]** input ports. If neither of these two is provided and number of threads has been specified on the **Threads** (`--threads/-t`) input port, both CPU and memory per job will be determined by the provided number of threads; if neither number of CPUs/memory per job nor number of threads have been provided as inputs, the CPU and memory requirements will be determined according to the number of files provided on the **Input file** input port.


  ### Performance Benchmarking

  The speed and cost of the workflow depend on the size of the input FASTQ files. The following table showcases the metrics for the task running on the c4.2xlarge on-demand AWS instance. The price can be significantly reduced by using spot instances (set by default). Visit [The Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.

  Fastq file 1 size(.gz) | Fastq file 2 size(.gz) | Duration | Cost | Instance type (AWS) |
  |---------------|-----------------|-----------|--------|-----|
  | 700 MB | 680 MB | 2 min. | $0.01 | c4.2xlarge |
  | 12.6 GB | 12.6 GB | 25 min. | $0.11 | c4.2xlarge |
  | 23.8 GB | 26.8 GB | 1 hour |$0.27 | c4.2xlarge |
  | 47.9 GB | 48.9 GB | 1 hour 40 min. | $0.44 | c4.2xlarge |

  ### References

  [1] [FastQC GitHub](https://github.com/s-andrews/FastQC/blob/master/fastqc)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: |-
    ${
        // if cpus_per_job is set, it takes precedence
        if (inputs.cpu_per_job) {
            return inputs.cpu_per_job
        }
        // if threads parameter is set, the number of CPUs is set based on that parametere
        else if (inputs.threads) {
            return inputs.threads
        }
        // else the number of CPUs is determined by the number of input files, up to 7 -- default
        else return Math.min([].concat(inputs.in_reads).length, 7)
    }
  ramMin: |-
    ${
        // if mem_per_job is set, it takes precedence
        if (inputs.mem_per_job) {
            return inputs.mem_per_job
        }
        // if threads parameter is set, memory req is set based on the number of threads
        else if (inputs.threads) {
            return 1024 + 300 * inputs.threads
        }
        // else the memory req is determined by the number of input files, up to 7 -- default
        else return (1024 + 300 * Math.min([].concat(inputs.in_reads).length, 7))
    }
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/stefan_cidilko/fastqc-0-11-9:0
  dockerImageId: 003e7ddd8cb9
- class: InitialWorkDirRequirement
  listing: []
- class: InlineJavascriptRequirement
  expressionLib:
  - |-
    var updateMetadata = function(file, key, value) {
        file['metadata'][key] = value;
        return file;
    };


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
        }
        if (!Array.isArray(o1)) {
            o1 = setMetadata(o1, commonMetadata)
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
            }
        }
        return o1;
    };

    var toArray = function(file) {
        return [].concat(file);
    };

    var groupBy = function(files, key) {
        var groupedFiles = [];
        var tempDict = {};
        for (var i = 0; i < files.length; i++) {
            var value = files[i]['metadata'][key];
            if (value in tempDict)
                tempDict[value].push(files[i]);
            else tempDict[value] = [files[i]];
        }
        for (var key in tempDict) {
            groupedFiles.push(tempDict[key]);
        }
        return groupedFiles;
    };

    var orderBy = function(files, key, order) {
        var compareFunction = function(a, b) {
            if (a['metadata'][key].constructor === Number) {
                return a['metadata'][key] - b['metadata'][key];
            } else {
                var nameA = a['metadata'][key].toUpperCase();
                var nameB = b['metadata'][key].toUpperCase();
                if (nameA < nameB) {
                    return -1;
                }
                if (nameA > nameB) {
                    return 1;
                }
                return 0;
            }
        };

        files = files.sort(compareFunction);
        if (order == undefined || order == "asc")
            return files;
        else
            return files.reverse();
    };
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
        }
        if (!Array.isArray(o1)) {
            o1 = setMetadata(o1, commonMetadata)
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
            }
        }
        return o1;
    };

inputs:
- id: adapters_file
  label: Adapters
  doc: |-
    Specifies a non-default file which contains the list of adapter sequences which will be explicity searched against the library. The file must contain sets of named adapters in the form name[tab]sequence.  Lines prefixed with a hash will be ignored.
  type: File?
  inputBinding:
    prefix: --adapters
    position: 1
    shellQuote: false
  sbg:altPrefix: -a
  sbg:category: File inputs
  sbg:fileTypes: TXT
- id: casava
  label: Casava
  doc: |-
    Files come from raw casava output. Files in the same sample group (differing only by the group number) will be analysed as a set rather than individually. Sequences with the filter flag set in the header will be excluded from the analysis. Files must have the same names given to them by casava (including being gzipped and ending with .gz) otherwise they won't be grouped together correctly.
  type: boolean?
  inputBinding:
    prefix: --casava
    position: 1
    separate: false
    shellQuote: false
  sbg:category: Options
- id: contaminants_file
  label: Contaminants
  doc: |-
    Specifies a non-default file which contains the list of contaminants to screen overrepresented sequences against. The file must contain sets of named contaminants in the form name[tab]sequence.  Lines prefixed with a hash will be ignored.
  type: File?
  inputBinding:
    prefix: --contaminants
    position: 1
    shellQuote: false
  sbg:altPrefix: -c
  sbg:category: File inputs
  sbg:fileTypes: TXT
- id: cpu_per_job
  label: Number of CPUs
  doc: Number of CPUs to be allocated per execution of FastQC.
  type: int?
  sbg:category: Execution parameters
  sbg:toolDefaultValue: Determined by the number of input files
- id: format
  label: Format
  doc: |-
    Bypasses the normal sequence file format detection and forces the program to use the specified format.  Valid formats are BAM, SAM, BAM_mapped, SAM_mapped and FASTQ.
  type:
  - 'null'
  - name: format
    type: enum
    symbols:
    - bam
    - sam
    - bam_mapped
    - sam_mapped
    - fastq
  inputBinding:
    prefix: --format
    position: 1
    shellQuote: false
  sbg:altPrefix: -f
  sbg:category: Options
  sbg:toolDefaultValue: FASTQ
- id: in_reads
  label: Input file
  doc: Input file.
  type: File[]
  inputBinding:
    position: 101
    shellQuote: false
  sbg:category: File inputs
  sbg:fileTypes: FASTQ, FQ, FASTQ.GZ, FQ.GZ, BAM, SAM
- id: kmers
  label: Kmers
  doc: |-
    Specifies the length of Kmer to look for in the Kmer content module. Specified Kmer length must be between 2 and 10. Default length is 7 if not specified.
  type: int?
  inputBinding:
    prefix: --kmers
    position: 1
    shellQuote: false
  sbg:altPrefix: -f
  sbg:category: Options
  sbg:toolDefaultValue: '7'
- id: limits_file
  label: Limits
  doc: |-
    Specifies a non-default file which contains a set of criteria which will be used to determine the warn/error limits for the various modules.  This file can also be used to selectively remove some modules from the output all together.  The format needs to mirror the default limits.txt file found in the Configuration folder.
  type: File?
  inputBinding:
    prefix: --limits
    position: 1
    shellQuote: false
  sbg:altPrefix: -l
  sbg:category: File inputs
  sbg:fileTypes: TXT
- id: mem_per_job
  label: Memory per job [MB]
  doc: Amount of memory allocated per execution of FastQC job.
  type: int?
  sbg:category: Execution parameters
  sbg:toolDefaultValue: Determined by the number of input files
- id: min_length
  label: Min length
  doc: |-
    Sets an artificial lower limit on the length of the sequence to be shown in the report.  As long as you set this to a value greater or equal to your longest read length then this will be the sequence length used to create your read groups.  This can be useful for making directly comaparable statistics from datasets with somewhat variable read lengths.
  type: int?
  inputBinding:
    prefix: --min_length
    position: 1
    shellQuote: false
  sbg:category: Options
- id: nano
  label: Nano
  doc: |-
    Files come from naopore sequences and are in fast5 format. In this mode you can pass in directories to process and the program will take in all fast5 files within those directories and produce a single output file from the sequences found in all files.
  type: boolean?
  inputBinding:
    prefix: --nano
    position: 1
    separate: false
    shellQuote: false
  sbg:category: Options
- id: nofilter
  label: No filter
  doc: |-
    If running with --casava then don't remove read flagged by casava as poor quality when performing the QC analysis.
  type: boolean?
  inputBinding:
    prefix: --nofilter
    position: 1
    shellQuote: false
  sbg:category: Options
- id: nogroup
  label: Nogroup
  doc: |-
    Disable grouping of bases for reads >50bp. All reports will show data for every base in the read.  WARNING: Using this option will cause fastqc to crash and burn if you use it on really long reads, and your plots may end up a ridiculous size. You have been warned.
  type: boolean?
  inputBinding:
    prefix: --nogroup
    position: 1
    separate: false
    shellQuote: false
  sbg:category: Options
- id: quiet
  label: Quiet
  doc: Supress all progress messages on stdout and only report errors.
  type: boolean?
  inputBinding:
    prefix: --quiet
    position: 1
    shellQuote: false
  sbg:altPrefix: -q
  sbg:category: Options
- id: threads
  label: Threads
  doc: |-
    Specifies the number of files which can be processed simultaneously.  Each thread will be allocated 250MB of memory so you shouldn't run more threads than your available memory will cope with, and not more than 6 threads on a 32 bit machine.
  type: int?
  default: 0
  inputBinding:
    prefix: --threads
    position: 1
    valueFrom: |-
      ${
          if (self == 0) {
              self = null;
              inputs.threads = null
          };


          //if "threads" is not specified
          //number of threads is determined based on number of inputs
          if (!inputs.threads) {
              inputs.threads = [].concat(inputs.in_reads).length
          }
          return Math.min(inputs.threads, 7)
      }
    shellQuote: false
  sbg:altPrefix: -t
  sbg:category: Options
  sbg:toolDefaultValue: '1'

outputs:
- id: out_html_report
  label: HTML reports
  doc: FastQC reports in HTML format.
  type: File[]?
  outputBinding:
    glob: '*.html'
    outputEval: $(inheritMetadata(self, inputs.in_reads))
  sbg:fileTypes: HTML
- id: out_zip
  label: Report zip
  doc: Zip archive of the report.
  type: File[]?
  outputBinding:
    glob: '*_fastqc.zip'
    outputEval: $(inheritMetadata(self, inputs.in_reads))
  sbg:fileTypes: ZIP

baseCommand: []
arguments:
- position: 0
  valueFrom: /opt/FastQC/fastqc
  shellQuote: false
- prefix: ''
  position: 1
  valueFrom: --noextract
  shellQuote: false
- prefix: --outdir
  position: 1
  valueFrom: .
  shellQuote: false
id: |-
  https://cgc-api.sbgenomics.com/v2/apps/jeffrey.grover/local-cwl-development-ci-cd-example/fastqc-0-11-9/1/raw/
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- FASTQ Processing
- QC
- CWL1.0
sbg:cmdPreview: |-
  /opt/FastQC/fastqc  --noextract --outdir .  /path/to/input_fastq-1.fastq  /path/to/input_fastq-2.fastq
sbg:content_hash: a7667fe2abe686bae29acbde82546475dfa954397092b7fa5d1de4056ae856f02
sbg:contributors:
- jeffrey.grover
sbg:createdBy: jeffrey.grover
sbg:createdOn: 1632777716
sbg:id: jeffrey.grover/local-cwl-development-ci-cd-example/fastqc-0-11-9/1
sbg:image_url:
sbg:latestRevision: 1
sbg:license: GNU General Public License v3.0 only
sbg:links:
- id: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
  label: Homepage
- id: |-
    http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5_source.zip
  label: Source Code
- id: https://wiki.hpcc.msu.edu/display/Bioinfo/FastQC+Tutorial
  label: Wiki
- id: http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip
  label: Download
- id: http://www.bioinformatics.babraham.ac.uk/projects/fastqc
  label: Publication
sbg:modifiedBy: jeffrey.grover
sbg:modifiedOn: 1632777811
sbg:project: jeffrey.grover/local-cwl-development-ci-cd-example
sbg:projectName: Local CWL Development CI/CD Example
sbg:publisher: sbg
sbg:revision: 1
sbg:revisionNotes: Description changed to stop automatic updates of app for testing
  purposes
sbg:revisionsInfo:
- sbg:modifiedBy: jeffrey.grover
  sbg:modifiedOn: 1632777716
  sbg:revision: 0
  sbg:revisionNotes: Copy of admin/sbg-public-data/fastqc-0-11-9/5
- sbg:modifiedBy: jeffrey.grover
  sbg:modifiedOn: 1632777811
  sbg:revision: 1
  sbg:revisionNotes: Description changed to stop automatic updates of app for testing
    purposes
sbg:sbgMaintained: false
sbg:toolAuthor: Babraham Institute
sbg:toolkit: FastQC
sbg:toolkitVersion: 0.11.9
sbg:validationErrors: []
