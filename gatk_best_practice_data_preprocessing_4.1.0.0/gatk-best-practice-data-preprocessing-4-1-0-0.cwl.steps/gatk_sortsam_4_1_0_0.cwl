cwlVersion: v1.0
class: CommandLineTool
label: GATK SortSam
doc: |-
  The **GATK SortSam** tool sorts the input SAM or BAM file by coordinate, queryname (QNAME), or some other property of the SAM record.

  The **GATK SortOrder** of a SAM/BAM file is found in the SAM file header tag @HD in the field labeled SO.  For a coordinate
  sorted SAM/BAM file, read alignments are sorted first by the reference sequence name (RNAME) field using the reference
  sequence dictionary (@SQ tag).  Alignments within these subgroups are secondarily sorted using the left-most mapping
  position of the read (POS).  Subsequent to this sorting scheme, alignments are listed arbitrarily.</p><p>For
  queryname-sorted alignments, all alignments are grouped using the queryname field but the alignments are not necessarily
  sorted within these groups.  Reads having the same queryname are derived from the same template


  ###Common Use Cases

  The **GATK SortSam** tool requires a BAM/SAM file on its **Input SAM/BAM file**   (`--INPUT`)  input. The tool sorts input file in the order defined by (`--SORT_ORDER`) parameter. Available sort order options are `queryname`, `coordinate` and `duplicate`.  

  * Usage example:

  ```
  java -jar picard.jar SortSam
       --INPUT=input.bam 
       --SORT_ORDER=coordinate
  ```


  ###Changes Introduced by Seven Bridges

  * Prefix of the output file is defined with the optional parameter **Output prefix**. If **Output prefix** is not provided, name of the sorted file is obtained from **Sample ID** metadata from the **Input SAM/BAM file**, if the **Sample ID** metadata exists. Otherwise, the output prefix will be inferred form the **Input SAM/BAM file** filename. 


  ###Common Issues and Important Notes

  * None


  ###Performance Benchmarking
  Below is a table describing runtimes and task costs of **GATK SortSam** for a couple of different samples, executed on the AWS cloud instances:

  | Experiment type |  Input size | Paired-end | # of reads | Read length | Duration |  Cost | Instance (AWS) | 
  |:--------------:|:------------:|:--------:|:-------:|:---------:|:----------:|:------:|:------:|
  |     WGS     |          |     Yes    |     16M     |     101     |   4min   | ~0.03$ | c4.2xlarge (8 CPUs) | 
  |     WGS     |         |     Yes    |     50M     |     101     |   7min   | ~0.04$ | c4.2xlarge (8 CPUs) | 
  |     WGS     |         |     Yes    |     82M    |     101     |  10min  | ~0.07$ | c4.2xlarge (8 CPUs) | 
  |     WES     |         |     Yes    |     164M    |     101     |  20min  | ~0.13$ | c4.2xlarge (8 CPUs) |

  *Cost can be significantly reduced by using **spot instances**. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*



  ###References
  [1] [GATK SortSam home page](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.12.0/picard_sam_SortSam.php)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: "${\n    return inputs.cpu_per_job ? inputs.cpu_per_job : 1;\n}"
  ramMin: |-
    ${
        var memory = 4096;
        if (inputs.memory_per_job) 
        {
            memory = inputs.memory_per_job;
        }
        if (inputs.memory_overhead_per_job)
        {
            memory += inputs.memory_overhead_per_job;
        }
        return memory;
    }
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/stefan_stojanovic/gatk:4.1.0.0
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
        if (!('metadata' in file))
            file['metadata'] = metadata;
        else {
            for (var key in metadata) {
                file['metadata'][key] = metadata[key];
            }
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
- id: in_alignments
  label: Input SAM/BAM file
  doc: Input BAM or SAM file to sort.  Required
  type: File
  inputBinding:
    prefix: --INPUT
    position: 4
    shellQuote: false
  sbg:altPrefix: -I
  sbg:category: Required Arguments
  sbg:fileTypes: BAM, SAM
- id: output_prefix
  label: Output prefix
  doc: Sorted bam or sam output file.
  type: string?
  sbg:altPrefix: -O
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: sample_id.sorted.bam
- id: compression_level
  label: Compression level
  doc: Compression level for all compressed files created (e.g. Bam and vcf).
  type: int?
  inputBinding:
    prefix: --COMPRESSION_LEVEL
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '2'
- id: create_index
  label: Create index
  doc: Whether to create a bam index when writing a coordinate-sorted bam file.
  type: boolean?
  inputBinding:
    prefix: --CREATE_INDEX
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: create_md5_file
  label: Create md5 file
  doc: Whether to create an md5 digest for any bam or fastq files created.
  type: boolean?
  inputBinding:
    prefix: --CREATE_MD5_FILE
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: max_records_in_ram
  label: Max records in ram
  doc: |-
    When writing files that need to be sorted, this will specify the number of records stored in ram before spilling to disk. Increasing this number reduces the number of file handles needed to sort the file, and increases the amount of ram needed.
  type: int?
  inputBinding:
    prefix: --MAX_RECORDS_IN_RAM
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '500000'
- id: validation_stringency
  label: Validation stringency
  doc: |-
    Validation stringency for all sam files read by this program. Setting stringency to silent can improve performance when processing a bam file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded.
  type:
  - 'null'
  - name: validation_stringency
    type: enum
    symbols:
    - STRICT
    - LENIENT
    - SILENT
  inputBinding:
    prefix: --VALIDATION_STRINGENCY
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: STRICT
- id: memory_per_job
  label: Memory Per Job
  doc: Memory which will be allocated for execution.
  type: int?
  sbg:category: Execution
- id: memory_overhead_per_job
  label: Memory Overhead Per Job
  doc: Memory overhead which will be allocated for one job.
  type: int?
  sbg:category: Execution
- id: sort_order
  doc: |-
    Sort order of output file.   Required. Possible values: {
                                  queryname (Sorts according to the readname. This will place read-pairs and other derived
                                  reads (secondary and supplementary) adjacent to each other. Note that the readnames are
                                  compared lexicographically, even though they may include numbers. In paired reads, Read1
                                  sorts before Read2.)
                                  coordinate (Sorts primarily according to the SEQ and POS fields of the record. The
                                  sequence will sorted according to the order in the sequence dictionary, taken from from
                                  the header of the file. Within each reference sequence, the reads are sorted by the
                                  position. Unmapped reads whose mates are mapped will be placed near their mates. Unmapped
                                  read-pairs are placed after all the mapped reads and their mates.)
                                  duplicate (Sorts the reads so that duplicates reads are adjacent. Required that the
                                  mate-cigar (MC) tag is present. The resulting will be sorted by library, unclipped 5-prime
                                  position, orientation, and mate's unclipped 5-prime position.)
                                  }
  type:
    name: sort_order
    type: enum
    symbols:
    - queryname
    - coordinate
    - duplicate
  inputBinding:
    prefix: --SORT_ORDER
    position: 7
    shellQuote: false
  sbg:altPrefix: -SO
  sbg:category: Required  Arguments
- id: cpu_per_job
  label: CPU per job
  doc: |-
    This input allows a user to set the desired CPU requirement when running a tool or adding it to a workflow.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '1'
- id: output_file_format
  label: Output file format
  doc: Output file format.
  type:
  - 'null'
  - name: output_file_format
    type: enum
    symbols:
    - bam
    - sam
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: Same as input

outputs:
- id: out_alignments
  label: Sorted BAM/SAM
  doc: Sorted BAM or SAM output file.
  type: File?
  secondaryFiles:
  - |-
    ${
       if (inputs.create_index)
       {
           return [self.basename + ".bai", self.nameroot + ".bai"]
       }
       else {
           return []; 
       }
    }
  outputBinding:
    glob: '*am'
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: BAM, SAM

baseCommand: []
arguments:
- position: 0
  valueFrom: /opt/gatk
  shellQuote: false
- position: 1
  valueFrom: --java-options
  shellQuote: false
- prefix: ''
  position: 2
  valueFrom: |-
    ${
        if (inputs.memory_per_job) {
            return '\"-Xmx'.concat(inputs.memory_per_job, 'M') + '\"';
        }
        return '\"-Xmx2048M\"';
    }
  shellQuote: false
- position: 3
  valueFrom: SortSam
  shellQuote: false
- prefix: ''
  position: 4
  valueFrom: |-
    ${
        var tmp = [].concat(inputs.in_alignments);
        var ext = '';
      
        if (inputs.output_file_format){
            ext = inputs.output_file_format;
        }    else {
            ext = tmp[0].path.split(".").pop();
        }
        
        
        if (inputs.output_prefix) {
            return '-O ' +  inputs.output_prefix + ".sorted." + ext;
          
        }else if (tmp[0].metadata && tmp[0].metadata.sample_id) {
            
            return '-O ' +  tmp[0].metadata.sample_id + ".sorted." + ext;
        } else {
             
            return '-O ' +  tmp[0].path.split('/').pop().split(".")[0] + ".sorted."+ext;
        }
        
        
    }
  shellQuote: false
id: h-bcdc89f1/h-7bf71c2b/h-2aed7d38/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BAM Processing
sbg:content_hash: a4d21247730823bddd1b0c24a25cc7b27bea6e061eacc901c23e642f333f458d5
sbg:contributors:
- nens
- uros_sipetic
sbg:copyOf: veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/19
sbg:createdBy: uros_sipetic
sbg:createdOn: 1555498331
sbg:id: h-bcdc89f1/h-7bf71c2b/h-2aed7d38/0
sbg:image_url:
sbg:latestRevision: 8
sbg:license: Open source BSD (3-clause) license
sbg:links:
- id: https://software.broadinstitute.org/gatk/
  label: Homepage
- id: |-
    https://software.broadinstitute.org/gatk/documentation/tooldocs/4.1.0.0/picard_sam_SortSam.php
  label: Documentation
- id: https://www.ncbi.nlm.nih.gov/pubmed?term=20644199
  label: Publications
- id: https://github.com/broadinstitute/gatk/
  label: Source code
sbg:modifiedBy: nens
sbg:modifiedOn: 1561632457
sbg:project: uros_sipetic/gatk-4-1-0-0-demo
sbg:projectName: GATK 4.1.0.0 - Demo
sbg:publisher: sbg
sbg:revision: 8
sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/19
sbg:revisionsInfo:
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1555498331
  sbg:revision: 0
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/2
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1555582270
  sbg:revision: 1
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/9
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557417459
  sbg:revision: 2
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/11
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557734528
  sbg:revision: 3
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/13
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000570
  sbg:revision: 4
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/14
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558009951
  sbg:revision: 5
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/15
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351565
  sbg:revision: 6
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/17
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558449641
  sbg:revision: 7
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/18
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1561632457
  sbg:revision: 8
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-sortsam-4-1-0-0/19
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.0.0
sbg:validationErrors: []
