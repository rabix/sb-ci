cwlVersion: v1.0
class: CommandLineTool
label: GATK SetNmMdAndUqTags
doc: |-
  The **GATK SetNmMdAndUqTags** tool takes in a coordinate-sorted SAM or BAM and calculatesthe NM, MD, and UQ tags by comparing it with the reference. 

  The **GATK SetNmMdAndUqTags**  may be needed when **GATK MergeBamAlignment** was run with **SORT_ORDER** other than `coordinate` and thus could not fix these tags. 


  ###Common Use Cases
  The **GATK SetNmMdAndUqTags** tool  fixes NM, MD and UQ tags in SAM/BAM file **Input SAM/BAM file**   (`--INPUT`)  input. This tool takes in a coordinate-sorted SAM or BAM file and calculates the NM, MD, and UQ tags by comparing with the reference **Reference sequence** (`--REFERENCE_SEQUENCE`).

  * Usage example:

  ```
  java -jar picard.jar SetNmMdAndUqTags
       --REFERENCE_SEQUENCE=reference_sequence.fasta
       --INPUT=sorted.bam
  ```


  ###Changes Introduced by Seven Bridges

  * Prefix of the output file is defined with the optional parameter **Output prefix**. If **Output prefix** is not provided, name of the sorted file is obtained from **Sample ID** metadata form the **Input SAM/BAM file**, if the **Sample ID** metadata exists. Otherwise, the output prefix will be inferred form the **Input SAM/BAM file** filename. 



  ###Common Issues and Important Notes

  * The **Input SAM/BAM file** must be coordinate sorted in order to run  **GATK SetNmMdAndUqTags**. 
  * If specified, the MD and NM tags can be ignored and only the UQ tag be set. 


  ###References
  [1] [GATK SetNmMdAndUqTags home page](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.0.0.0/picard_sam_SetNmMdAndUqTags.php)
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
- id: output_prefix
  label: Output
  doc: The fixed bam or sam output prefix name.
  type: string?
  sbg:altPrefix: -O
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: sample_id.fixed.bam
- id: memory_overhead_per_job
  label: Memory Overhead Per Job
  doc: |-
    This input allows a user to set the desired overhead memory when running a tool or adding it to a workflow. This amount will be added to the Memory per job in the Memory requirements section but it will not be added to the -Xmx parameter leaving some memory not occupied which can be used as stack memory (-Xmx parameter defines heap memory). This input should be defined in MB (for both the platform part and the -Xmx part if Java tool is wrapped).
  type: int?
  sbg:category: Execution
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
- id: is_bisulfite_sequence
  label: Is bisulfite sequence
  doc: Whether the file contains bisulfite sequence (used when calculating the nm
    tag).
  type: boolean?
  inputBinding:
    prefix: --IS_BISULFITE_SEQUENCE
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
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
- id: memory_per_job
  label: Memory Per Job
  doc: |-
    This input allows a user to set the desired memory requirement when running a tool or adding it to a workflow. This value should be propagated to the -Xmx parameter too.This input should be defined in MB (for both the platform part and the -Xmx part if Java tool is wrapped).
  type: int?
  sbg:category: Execution
- id: in_alignments
  label: Input SAM/BAM file
  doc: The BAM or SAM file to fix.
  type: File
  inputBinding:
    prefix: --INPUT
    position: 4
    shellQuote: false
  sbg:altPrefix: -I
  sbg:category: Required Arguments
  sbg:fileTypes: BAM, SAM
- id: reference_sequence
  label: Reference sequence
  doc: Reference sequence FASTA file.
  type: File
  inputBinding:
    prefix: --REFERENCE_SEQUENCE
    position: 4
    shellQuote: false
  sbg:altPrefix: -R
  sbg:category: Required Arguments
  sbg:fileTypes: FASTA, FA
- id: set_only_uq
  label: Set only uq
  doc: Only set the uq tag, ignore md and nm.
  type: boolean?
  inputBinding:
    prefix: --SET_ONLY_UQ
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
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
  label: Output BAM/SAM file
  doc: Output BAM/SAM file with fixed tags.
  type: File[]
  secondaryFiles:
  - |-
    ${  
        if (inputs.create_index)
        {
            return self.nameroot + ".bai";
        }
        else {
            return ''; 
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
  valueFrom: SetNmMdAndUqTags
  shellQuote: false
- prefix: ''
  position: 4
  valueFrom: |-
    ${
        var tmp = [].concat(inputs.in_alignments);
        var ext = ""; 
        if (inputs.output_file_format) {
            ext = inputs.output_file_format;
        } else {
            ext = tmp[0].path.split('.').pop();
        }
        
        if (inputs.output_prefix) {
            return '-O ' +  inputs.output_prefix + ".fixed." + ext;
        } else if (tmp[0].metadata && tmp[0].metadata.sample_id) {
            return '-O ' +  tmp[0].metadata.sample_id + ".fixed." + ext;
        } else {
            return '-O ' +  tmp[0].path.split('/').pop().split(".")[0] + ".fixed." + ext;
        }
        
    }
  shellQuote: false
id: h-9c5a31e9/h-090ef30a/h-820dff8e/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BAM Processing
sbg:content_hash: a31d48359c8ea5e8ac91b2096488ac9e8a71d49dd3aa1a8ffbdcc09665a2c1f39
sbg:contributors:
- nens
- uros_sipetic
sbg:copyOf: veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/15
sbg:createdBy: uros_sipetic
sbg:createdOn: 1555498307
sbg:id: h-9c5a31e9/h-090ef30a/h-820dff8e/0
sbg:image_url:
sbg:latestRevision: 10
sbg:license: Open source BSD (3-clause) license
sbg:links:
- id: https://software.broadinstitute.org/gatk/
  label: Homepage
- id: https://github.com/broadinstitute/gatk/
  label: Source Code
- id: |-
    https://github.com/broadinstitute/gatk/releases/download/4.1.0.0/gatk-4.1.0.0.zip
  label: Download
- id: https://www.ncbi.nlm.nih.gov/pubmed?term=20644199
  label: Publications
- id: |-
    https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_sam_SetNmMdAndUqTags.php
  label: Documentation
sbg:modifiedBy: nens
sbg:modifiedOn: 1558518048
sbg:project: uros_sipetic/gatk-4-1-0-0-demo
sbg:projectName: GATK 4.1.0.0 - Demo
sbg:publisher: sbg
sbg:revision: 10
sbg:revisionNotes: |-
  Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/15
sbg:revisionsInfo:
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1555498307
  sbg:revision: 0
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/1
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1555582274
  sbg:revision: 1
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/5
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1556194603
  sbg:revision: 2
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/6
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557399646
  sbg:revision: 3
  sbg:revisionNotes: app info improved - perf bench needed
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557417063
  sbg:revision: 4
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/7
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557734531
  sbg:revision: 5
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/9
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000576
  sbg:revision: 6
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/10
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558100350
  sbg:revision: 7
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/11
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351574
  sbg:revision: 8
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/13
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558450064
  sbg:revision: 9
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/14
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558518048
  sbg:revision: 10
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-setnmmdanduqtags-4-1-0-0/15
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.0.0
sbg:validationErrors: []
