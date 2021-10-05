cwlVersion: v1.0
class: CommandLineTool
label: GATK GatherBamFiles
doc: |-
  **GATK GatherBamFiles** concatenates one or more BAM files resulted form scattered paralel anaysis. 


  ### Common Use Cases 

  * **GATK GatherBamFiles**  tool performs a rapid "gather" or concatenation on BAM files into single BAM file. This is often needed in operations that have been run in parallel across genomics regions by scattering their execution across computing nodes and cores thus resulting in smaller BAM files.
  * Usage example:
  ```

  java -jar picard.jar GatherBamFiles
        --INPUT=input1.bam
        --INPUT=input2.bam
  ```

  ### Common Issues and Important Notes
  * **GATK GatherBamFiles** assumes that the list of BAM files provided as input are in the order that they should be concatenated and simply links the bodies of the BAM files while retaining the header from the first file. 
  *  Operates by copying the gzip blocks directly for speed but also supports the generation of an MD5 in the output file and the indexing of the output BAM file.
  * This tool only support BAM files. It does not support SAM files.

  ###Changes Intorduced by Seven Bridges
  * Generated output BAM file will be prefixed using the **Output prefix** parameter. In case the **Output prefix** is not provided, the output prefix will be the same as the **Sample ID** metadata from the **Input alignments**, if the **Sample ID** metadata exists. Otherwise, the output prefix will be inferred from the **Input alignments** filename. This way, having identical names of the output files between runs is avoided.
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
- id: memory_overhead_per_job
  label: Memory Overhead Per Job
  doc: Memory overhead which will be allocated for one job.
  type: int?
  sbg:category: Execution
- id: max_records_in_ram
  label: Max records in ram
  doc: |-
    When writing files that need to be sorted, this will specify the number of records stored in ram before spilling to disk. Increasing this number reduces the number of file handles needed to sort the file, and increases the amount of ram needed.
  type: int?
  inputBinding:
    prefix: --MAX_RECORDS_IN_RAM
    position: 20
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '500000'
- id: memory_per_job
  label: Memory Per Job
  doc: Memory which will be allocated for execution.
  type: int?
  sbg:category: Execution
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
- id: in_reference
  label: Reference sequence
  doc: Reference sequence file.
  type: File?
  inputBinding:
    prefix: --REFERENCE_SEQUENCE
    position: 7
    shellQuote: false
  sbg:altPrefix: -R
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: output_prefix
  label: Output prefix
  doc: Name of the output bam file to write to.
  type: string?
  sbg:category: Optional Arguments
- id: in_alignments
  label: Input alignments
  doc: |-
    Two or more bam files or text files containing lists of bam files (one per line). This argument must be specified at least once.
  type: File[]
  inputBinding:
    position: 3
    valueFrom: |-
      ${
         if (self)
         {
             var cmd = [];
             for (var i = 0; i < self.length; i++)
             {
                 cmd.push('--INPUT', self[i].path);
             }
             return cmd.join(' ');
         }

      }
    shellQuote: false
  sbg:altPrefix: -I
  sbg:category: Required Arguments
  sbg:fileTypes: BAM
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
- id: create_md5_file
  label: Create MD5 file
  doc: Whether to create an MD5 digest for any BAM or FASTQ files created.
  type: boolean?
  inputBinding:
    prefix: --CREATE_MD5_FILE
    position: 5
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'FALSE'
- id: cpu_per_job
  label: CPU per job
  doc: |-
    This input allows a user to set the desired CPU requirement when running a tool or adding it to a workflow.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '1'

outputs:
- id: out_alignments
  label: Output BAM file
  doc: Output BAM file obtained by merging input BAM files.
  type: File?
  secondaryFiles:
  - |-
    ${
        if (inputs.create_index)
        {
            return [self.basename + ".bai", self.nameroot + ".bai"];
        }
        else {
            return ''; 
        }
    }
  outputBinding:
    glob: '*.bam'
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: BAM
- id: out_md5
  label: MD5 file
  doc: MD5 ouput BAM file.
  type: File?
  outputBinding:
    glob: '*.md5'
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: MD5

baseCommand: []
arguments:
- position: 0
  valueFrom: /opt/gatk --java-options
  shellQuote: false
- position: 2
  valueFrom: |-
    ${
        if (inputs.memory_per_job) {
            return '\"-Xmx'.concat(inputs.memory_per_job, 'M') + '\"';
        }
        return '\"-Xmx2048M\"';
    }
  shellQuote: false
- position: 4
  valueFrom: |-
    ${
        var tmp = [].concat(inputs.in_alignments);
            
        if (inputs.output_prefix) {
            return '-O ' +  inputs.output_prefix + ".bam";
            
        }else if (tmp[0].metadata && tmp[0].metadata.sample_id) {
            
            return '-O ' +  tmp[0].metadata.sample_id + ".bam";
        } else {
             
            return '-O ' +  tmp[0].path.split('/').pop().split(".")[0] + ".bam";
        }
        
        
    }
  shellQuote: false
- position: 3
  valueFrom: GatherBamFiles
  shellQuote: false
id: h-593cd3ec/h-6fb9a20d/h-1a33c401/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BAM Processing
sbg:content_hash: adc3fdd806bf7e70cfd29e650f70e8bdc6477baa1d0dc7ef7792f2f8806bcd064
sbg:contributors:
- nens
sbg:copyOf: veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/23
sbg:createdBy: nens
sbg:createdOn: 1554894822
sbg:id: h-593cd3ec/h-6fb9a20d/h-1a33c401/0
sbg:image_url:
sbg:latestRevision: 9
sbg:license: Open source BSD (3-clause) license
sbg:links:
- id: https://software.broadinstitute.org/gatk/
  label: Homepage
- id: |-
    https://software.broadinstitute.org/gatk/documentation/tooldocs/4.1.0.0/picard_sam_GatherBamFiles.php
  label: Documentation
- id: https://www.ncbi.nlm.nih.gov/pubmed?term=20644199
  label: Publications
- id: https://github.com/broadinstitute/gatk/
  label: Source
sbg:modifiedBy: nens
sbg:modifiedOn: 1558531990
sbg:project: uros_sipetic/gatk-4-1-0-0-demo
sbg:projectName: GATK 4.1.0.0 - Demo
sbg:publisher: sbg
sbg:revision: 9
sbg:revisionNotes: |-
  Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/23
sbg:revisionsInfo:
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1554894822
  sbg:revision: 0
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/11
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557734548
  sbg:revision: 1
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/14
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557914509
  sbg:revision: 2
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/16
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000604
  sbg:revision: 3
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/17
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351555
  sbg:revision: 4
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/18
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558451620
  sbg:revision: 5
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/19
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558525775
  sbg:revision: 6
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/20
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558526183
  sbg:revision: 7
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/21
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558528334
  sbg:revision: 8
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/22
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558531990
  sbg:revision: 9
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-gatherbamfiles-4-1-0-0/23
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.0.0
sbg:validationErrors: []
