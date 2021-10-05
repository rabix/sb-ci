cwlVersion: v1.0
class: CommandLineTool
label: GATK MergeBamAlignment
doc: |-
  The **GATK MergeBamAlignment** tool is used for merging BAM/SAM alignment info from a third-party aligner with the data in an unmapped BAM file, producing a third BAM file that has alignment data (from the aligner) and all the remaining data from the unmapped BAM.

  Many alignment tools still require FASTQ format input. The unmapped BAM may contain useful information that will be lost in the conversion to FASTQ (meta-data like sample alias, library, barcodes, etc... as well as read-level tags.) This tool takes an unaligned BAM with meta-data, and the aligned BAM produced by calling [SamToFastq](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.1.0.0/picard_sam_SamToFastq.php) and then passing the result to an aligner. It produces a new SAM file that includes all aligned and unaligned reads and also carries forward additional read attributes from the unmapped BAM (attributes that are otherwise lost in the process of converting to FASTQ). The resulting file will be valid for use by Picard and GATK tools. The output may be coordinate-sorted, in which case the tags, NM, MD, and UQ will be calculated and populated, or query-name sorted, in which case the tags will not be calculated or populated [1].

  *A list of **all inputs and parameters** with corresponding descriptions can be found at the bottom of the page.*

  ###Common Use Cases

  * The **GATK MergeBamAlignment** tool requires a SAM or BAM file on its **Aligned BAM/SAM file** (`--ALIGNED_BAM`) input, original SAM or BAM file of unmapped reads, which must be in queryname order on its **Unmapped BAM/SAM file** (`--UNMAPPED_BAM`) input and a reference sequence on its **Reference** (`--REFERENCE_SEQUENCE`) input. The tool generates a single BAM/SAM file on its **Output merged BAM/SAM file** output.

  * Usage example:

  ```
  gatk MergeBamAlignment \\
        --ALIGNED_BAM aligned.bam \\
        --UNMAPPED_BAM unmapped.bam \\
        --OUTPUT merged.bam \\
        --REFERENCE_SEQUENCE reference_sequence.fasta
  ```

  ###Changes Introduced by Seven Bridges

  * The output file name will be prefixed using the **Output prefix** parameter. In case **Output prefix** is not provided, output prefix will be the same as the Sample ID metadata from **Input SAM/BAM file**, if the Sample ID metadata exists. Otherwise, output prefix will be inferred from the **Input SAM/BAM file** filename. This way, having identical names of the output files between runs is avoided. Moreover,  **merged** will be added before the extension of the output file name. 

  * The user has a possibility to specify the output file format using the **Output file format** argument. Otherwise, the output file format will be the same as the format of the input aligned file.

  ###Common Issues and Important Notes

  * Note:  This is not a tool for taking multiple BAM/SAM files and creating a bigger file by merging them. For that use-case, see [MergeSamFiles](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.1.0.0/picard_sam_MergeSamFiles.php).

  ###Performance Benchmarking

  Below is a table describing runtimes and task costs of **GATK MergeBamAlignment** for a couple of different samples, executed on the AWS cloud instances:

  | Experiment type |  Aligned BAM/SAM size |  Unmapped BAM/SAM size | Duration |  Cost | Instance (AWS) | 
  |:--------------:|:------------:|:--------:|:-------:|:---------:|:----------:|:------:|:------:|------:|
  |     RNA-Seq     |  1.4 GB |  1.9 GB |   9min   | ~0.06$ | c4.2xlarge (8 CPUs) | 
  |     RNA-Seq     |  4.0 GB |  5.7 GB |   20min   | ~0.13$ | c4.2xlarge (8 CPUs) | 
  |     RNA-Seq     | 6.6 GB | 9.5 GB |  32min  | ~0.21$ | c4.2xlarge (8 CPUs) | 
  |     RNA-Seq     | 13 GB | 19 GB |  1h 4min  | ~0.42$ | c4.2xlarge (8 CPUs) |

  *Cost can be significantly reduced by using **spot instances**. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*

  ###References

  [1] [GATK MergeBamAlignment](https://software.broadinstitute.org/gatk/documentation/tooldocs/4.1.0.0/picard_sam_MergeBamAlignment.php)
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
- id: add_mate_cigar
  label: Add mate CIGAR
  doc: Adds the mate CIGAR tag (MC) if true, does not if false.
  type:
  - 'null'
  - name: add_mate_cigar
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --ADD_MATE_CIGAR
    position: 4
    shellQuote: false
  sbg:altPrefix: -MC
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'true'
- id: add_pg_tag_to_reads
  label: Add PG tag to reads
  doc: Add PG tag to each read in a SAM or BAM.
  type:
  - 'null'
  - name: add_pg_tag_to_reads
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --ADD_PG_TAG_TO_READS
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'true'
- id: in_alignments
  label: Aligned BAM/SAM file
  doc: |-
    SAM or BAM file(s) with alignment data. Cannot be used in conjuction with argument(s) READ1_ALIGNED_BAM (R1_ALIGNED) READ2_ALIGNED_BAM (R2_ALIGNED).
  type: File[]
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          var arr = [].concat(inputs.in_alignments);
          if (arr.length == 1) 
          {
              return "--ALIGNED_BAM " + arr[0].path;
          }
          else
          {
              var pe_1 = [];
              var pe_2 = [];
              var se = [];
              for (var i in arr)
              {
                  if (arr[i].metadata && arr[i].metadata.paired_end && arr[i].metadata.paired_end == 1)
                  {
                      pe_1.push(arr[i].path);
                  }
                  else if (arr[i].metadata && arr[i].metadata.paired_end && arr[i].metadata.paired_end == 2)
                  {
                      pe_2.push(arr[i].path);
                  }
                  else
                  {
                      se.push(arr[i].path);
                  }
              }
              
              if (se.length > 0) 
              {
                  return "--ALIGNED_BAM " + se.join(" --ALIGNED_BAM ");
              } 
              else if (pe_1.length > 0 && pe_2.length > 0 && pe_1.length == pe_2.length) 
              {
                  return "--READ1_ALIGNED_BAM " + pe_1.join(' --READ1_ALIGNED_BAM ') + " --READ2_ALIGNED_BAM " + pe_2.join(' --READ2_ALIGNED_BAM ');
              } 
              else 
              {
                  return "";
              }
                  
          }
      }
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:fileTypes: BAM, SAM
  sbg:toolDefaultValue: 'null'
- id: aligned_reads_only
  label: Aligned reads only
  doc: Whether to output only aligned reads.
  type: boolean?
  inputBinding:
    prefix: --ALIGNED_READS_ONLY
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: aligner_proper_pair_flags
  label: Aligner proper pair flags
  doc: |-
    Use the aligner's idea of what a proper pair is rather than computing in this program.
  type: boolean?
  inputBinding:
    prefix: --ALIGNER_PROPER_PAIR_FLAGS
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: attributes_to_remove
  label: Attributes to remove
  doc: |-
    Attributes from the alignment record that should be removed when merging. This overrides ATTRIBUTES_TO_RETAIN if they share common tags.
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          if (self)
          {
              var cmd = [];
              for (var i = 0; i < self.length; i++) 
              {
                  cmd.push('--ATTRIBUTES_TO_REMOVE', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: attributes_to_retain
  label: Attributes to retain
  doc: |-
    Reserved alignment attributes (tags starting with X, Y, or Z) that should be brought over from the alignment data when merging.
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          if (self)
          {
              var cmd = [];
              for (var i = 0; i < self.length; i++) 
              {
                  cmd.push('--ATTRIBUTES_TO_RETAIN', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: attributes_to_reverse
  label: Attributes to reverse
  doc: Attributes on negative strand reads that need to be reversed.
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          if (self)
          {
              var cmd = [];
              for (var i = 0; i < self.length; i++) 
              {
                  cmd.push('--ATTRIBUTES_TO_REVERSE', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:altPrefix: -RV
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '[OQ,U2]'
- id: attributes_to_reverse_complement
  label: Attributes to reverse complement
  doc: Attributes on negative strand reads that need to be reverse complemented.
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          if (self)
          {
              var cmd = [];
              for (var i = 0; i < self.length; i++) 
              {
                  cmd.push('--ATTRIBUTES_TO_REVERSE_COMPLEMENT', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:altPrefix: -RC
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '[E2,SQ]'
- id: clip_adapters
  label: Clip adapters
  doc: Whether to clip adapters where identified.
  type:
  - 'null'
  - name: clip_adapters
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --CLIP_ADAPTERS
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'true'
- id: clip_overlapping_reads
  label: Clip overlapping reads
  doc: |-
    For paired reads, soft clip the 3' end of each read if necessary so that it does not extend past the 5' end of its mate.
  type:
  - 'null'
  - name: clip_overlapping_reads
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --CLIP_OVERLAPPING_READS
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'true'
- id: compression_level
  label: Compression level
  doc: Compression level for all compressed files created (e.g. BAM and VCF).
  type: int?
  inputBinding:
    prefix: --COMPRESSION_LEVEL
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '2'
- id: create_index
  label: Create index
  doc: Whether to create a BAM index when writing a coordinate-sorted BAM file.
  type: boolean?
  inputBinding:
    prefix: --CREATE_INDEX
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: expected_orientations
  label: Expected orientations
  doc: |-
    The expected orientation of proper read pairs. Replaces JUMP_SIZE. Cannot be used in conjuction with argument(s) JUMP_SIZE (JUMP).
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          if (self)
          {
              var cmd = [];
              for (var i = 0; i < self.length; i++) 
              {
                  cmd.push('--EXPECTED_ORIENTATIONS', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:altPrefix: -ORIENTATIONS
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: include_secondary_alignments
  label: Include secondary alignments
  doc: If false, do not write secondary alignments to output.
  type:
  - 'null'
  - name: include_secondary_alignments
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --INCLUDE_SECONDARY_ALIGNMENTS
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'true'
- id: is_bisulfite_sequence
  label: Is bisulfite sequence
  doc: Whether the lane is bisulfite sequence (used when calculating the NM tag).
  type: boolean?
  inputBinding:
    prefix: --IS_BISULFITE_SEQUENCE
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: jump_size
  label: Jump size
  doc: |-
    The expected jump size (required if this is a jumping library). Deprecated. Use EXPECTED_ORIENTATIONS instead. Cannot be used in conjuction with argument(s) EXPECTED_ORIENTATIONS (ORIENTATIONS).
  type: int?
  inputBinding:
    prefix: --JUMP_SIZE
    position: 4
    shellQuote: false
  sbg:altPrefix: -JUMP
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: matching_dictionary_tags
  label: Matching dictionary tags
  doc: |-
    List of Sequence Records tags that must be equal (if present) in the reference dictionary and in the aligned file. Mismatching tags will cause an error if in this list, and a warning otherwise.
  type: string[]?
  inputBinding:
    prefix: ''
    position: 4
    valueFrom: |-
      ${
          if (self)
          {
              var cmd = [];
              for (var i = 0; i < self.length; i++) 
              {
                  cmd.push('--MATCHING_DICTIONARY_TAGS', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '[M5,LN]'
- id: max_insertions_or_deletions
  label: Max insertions or deletions
  doc: |-
    The maximum number of insertions or deletions permitted for an alignment to be included. Alignments with more than this many insertions or deletions will be ignored. Set to -1 to allow any number of insertions or deletions.
  type: int?
  inputBinding:
    prefix: --MAX_INSERTIONS_OR_DELETIONS
    position: 4
    shellQuote: false
  sbg:altPrefix: -MAX_GAPS
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '1'
- id: max_records_in_ram
  label: Max records in RAM
  doc: |-
    When writing files that need to be sorted, this will specify the number of records stored in RAM before spilling to disk. Increasing this number reduces the number of file handles needed to sort the file, and increases the amount of RAM needed.
  type: int?
  inputBinding:
    prefix: --MAX_RECORDS_IN_RAM
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '500000'
- id: memory_overhead_per_job
  label: Memory overhead per job
  doc: |-
    This input allows a user to set the desired overhead memory when running a tool or adding it to a workflow. This amount will be added to the Memory per job in the Memory requirements section but it will not be added to the -Xmx parameter leaving some memory not occupied which can be used as stack memory (-Xmx parameter defines heap memory). This input should be defined in MB (for both the platform part and the -Xmx part if Java tool is wrapped).
  type: int?
  sbg:category: Platform Options
- id: memory_per_job
  label: Memory per job
  doc: |-
    This input allows a user to set the desired memory requirement when running a tool or adding it to a workflow. This value should be propagated to the -Xmx parameter too.This input should be defined in MB (for both the platform part and the -Xmx part if Java tool is wrapped).
  type: int?
  sbg:category: Platform Options
- id: min_unclipped_bases
  label: Min unclipped bases
  doc: |-
    If UNMAP_CONTAMINANT_READS is set, require this many unclipped bases or else the read will be marked as contaminant.
  type: int?
  inputBinding:
    prefix: --MIN_UNCLIPPED_BASES
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '32'
- id: paired_run
  label: Paired run
  doc: DEPRECATED. This argument is ignored and will be removed.
  type:
  - 'null'
  - name: paired_run
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --PAIRED_RUN
    position: 4
    shellQuote: false
  sbg:altPrefix: -PE
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'true'
- id: primary_alignment_strategy
  label: Primary alignment strategy
  doc: |-
    Strategy for selecting primary alignment when the aligner has provided more than one alignment for a pair or fragment, and none are marked as primary, more than one is marked as primary, or the primary alignment is filtered out for some reason. For all strategies, ties are resolved arbitrarily. Possible values: { BestMapq (expects that multiple alignments will be correlated with HI tag, and prefers the pair of alignments with the largest MAPQ, in the absence of a primary selected by the aligner.) EarliestFragment (prefers the alignment which maps the earliest base in the read. Note that EarliestFragment may not be used for paired reads.) BestEndMapq (appropriate for cases in which the aligner is not pair-aware, and does not output the HI tag. It simply picks the alignment for each end with the highest MAPQ, and makes those alignments primary, regardless of whether the two alignments make sense together.) MostDistant (appropriate for a non-pair-aware aligner. Picks the alignment pair with the largest insert size. If all alignments would be chimeric, it picks the alignments for each end with the best MAPQ. ) }.
  type:
  - 'null'
  - name: primary_alignment_strategy
    type: enum
    symbols:
    - BestMapq
    - EarliestFragment
    - BestEndMapq
    - MostDistant
  inputBinding:
    prefix: --PRIMARY_ALIGNMENT_STRATEGY
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: BestMapq
- id: program_group_command_line
  label: Program group command line
  doc: The command line of the program group (if not supplied by the aligned file).
  type: string?
  inputBinding:
    prefix: --PROGRAM_GROUP_COMMAND_LINE
    position: 4
    shellQuote: false
  sbg:altPrefix: -PG_COMMAND
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: program_group_name
  label: Program group name
  doc: The name of the program group (if not supplied by the aligned file).
  type: string?
  inputBinding:
    prefix: --PROGRAM_GROUP_NAME
    position: 4
    shellQuote: false
  sbg:altPrefix: -PG_NAME
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: program_group_version
  label: Program group version
  doc: The version of the program group (if not supplied by the aligned file).
  type: string?
  inputBinding:
    prefix: --PROGRAM_GROUP_VERSION
    position: 4
    shellQuote: false
  sbg:altPrefix: -PG_VERSION
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: program_record_id
  label: Program record id
  doc: The program group ID of the aligner (if not supplied by the aligned file).
  type: string?
  inputBinding:
    prefix: --PROGRAM_RECORD_ID
    position: 4
    shellQuote: false
  sbg:altPrefix: -PG
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: read1_trim
  label: Read1 trim
  doc: The number of bases trimmed from the beginning of read 1 prior to alignment.
  type: int?
  inputBinding:
    prefix: --READ1_TRIM
    position: 4
    shellQuote: false
  sbg:altPrefix: -R1_TRIM
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '0'
- id: read2_trim
  label: Read2 trim
  doc: The number of bases trimmed from the beginning of read 2 prior to alignment.
  type: int?
  inputBinding:
    prefix: --READ2_TRIM
    position: 4
    shellQuote: false
  sbg:altPrefix: -R2_TRIM
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '0'
- id: in_reference
  label: Reference
  doc: Reference sequence file.
  type: File
  secondaryFiles:
  - .fai
  - ^.dict
  inputBinding:
    prefix: --REFERENCE_SEQUENCE
    position: 4
    shellQuote: false
  sbg:altPrefix: -R
  sbg:category: Required Arguments
  sbg:fileTypes: FASTA, FA
- id: sort_order
  label: Sort order
  doc: The order in which the merged reads should be output.
  type:
  - 'null'
  - name: sort_order
    type: enum
    symbols:
    - unsorted
    - queryname
    - coordinate
    - duplicate
    - unknown
  inputBinding:
    prefix: --SORT_ORDER
    position: 4
    shellQuote: false
  sbg:altPrefix: -SO
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: coordinate
- id: unmap_contaminant_reads
  label: Unmap contaminant reads
  doc: |-
    Detect reads originating from foreign organisms (e.g. bacterial DNA in a non-bacterial sample), and unmap + label those reads accordingly.
  type: boolean?
  inputBinding:
    prefix: --UNMAP_CONTAMINANT_READS
    position: 4
    shellQuote: false
  sbg:altPrefix: -UNMAP_CONTAM
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: unmapped_bam
  label: Unmapped BAM/SAM file
  doc: Original SAM or BAM file of unmapped reads, which must be in queryname order.
  type: File
  inputBinding:
    prefix: --UNMAPPED_BAM
    position: 4
    shellQuote: false
  sbg:altPrefix: -UNMAPPED
  sbg:category: Required Arguments
  sbg:fileTypes: BAM, SAM
- id: unmapped_read_strategy
  label: Unmapped read strategy
  doc: |-
    How to deal with alignment information in reads that are being unmapped (e.g. due to cross-species contamination.) Currently ignored unless UNMAP_CONTAMINANT_READS = true
  type:
  - 'null'
  - name: unmapped_read_strategy
    type: enum
    symbols:
    - COPY_TO_TAG
    - DO_NOT_CHANGE
    - MOVE_TO_TAG
  inputBinding:
    prefix: --UNMAPPED_READ_STRATEGY
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: DO_NOT_CHANGE
- id: validation_stringency
  label: Validation stringency
  doc: |-
    Validation stringency for all SAM files read by this program. Setting stringency to SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded.
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
  label: Output prefix
  doc: Output file name prefix.
  type: string?
  sbg:category: Optional Parameters
- id: output_file_format
  label: Output file format
  doc: Output file format
  type:
  - 'null'
  - name: output_file_format
    type: enum
    symbols:
    - bam
    - sam
  sbg:category: Optional parameters
- id: cpu_per_job
  label: CPU per job
  doc: CPU per job.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '1'

outputs:
- id: out_alignments
  label: Output merged SAM or BAM file
  doc: Output merged SAM or BAM file.
  type: File
  secondaryFiles:
  - |-
    ${
        if (self.nameext == ".bam" && inputs.create_index)
        {
            return [self.basename + ".bai", self.nameroot + ".bai"];
        }
        else {
            return []; 
        }
    }
  outputBinding:
    glob: '*am'
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: SAM, BAM

baseCommand: []
arguments:
- prefix: ''
  position: 0
  valueFrom: /opt/gatk
  shellQuote: false
- prefix: ''
  position: 1
  valueFrom: |-
    ${
        if (inputs.memory_per_job)
        {
            return "--java-options";
        }
        else {
            return '';
        }
    }
  shellQuote: false
- prefix: ''
  position: 2
  valueFrom: |-
    ${
        if (inputs.memory_per_job) {
            return '\"-Xmx'.concat(inputs.memory_per_job, 'M') + '\"';
        }
        else {
            return ''; 
            
        }
    }
  shellQuote: false
- position: 3
  valueFrom: MergeBamAlignment
  shellQuote: false
- prefix: ''
  position: 4
  valueFrom: |-
    ${
        var in_alignments = [].concat(inputs.in_alignments);
        var output_ext = inputs.output_file_format ? inputs.output_file_format : in_alignments[0].path.split('.').pop();
        var output_prefix = '';
        var file1_name = ''; 
        var file2_name = ''; 
        if (inputs.output_prefix)
        {
            output_prefix = inputs.output_prefix;
        }
        else 
        {
            if (in_alignments.length > 1)
            {
                in_alignments.sort(function(file1, file2) {
                    file1_name = file1.path.split('/').pop().toUpperCase();
                    file2_name = file2.path.split('/').pop().toUpperCase();
                    if (file1_name < file2_name) {
                        return -1;
                    }
                    if (file1_name > file2_name) {
                        return 1;
                    }
                    // names must be equal
                    return 0;
                });
            }
            
            var in_alignments_first =  in_alignments[0];
            if (in_alignments_first.metadata && in_alignments_first.metadata.sample_id)
            {
                output_prefix = in_alignments_first.metadata.sample_id;
            }
            else 
            {
                output_prefix = in_alignments_first.path.split('/').pop().split('.')[0];
            }
            
            if (in_alignments.length > 1)
            {
                output_prefix = output_prefix + "." + in_alignments.length;
            }
        }
        
        return "--OUTPUT " + output_prefix + ".merged." + output_ext;
    }
  shellQuote: false
id: h-7f6bd0bb/h-8863b1ef/h-fcb32ecd/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BAM Processing
sbg:content_hash: a758b43167e957642f45a0aad07716ff3b8c8c6a379cf76b35f10b0a3f5a121b8
sbg:contributors:
- uros_sipetic
- nemanja.vucic
- nens
- veliborka_josipovic
sbg:copyOf: veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/37
sbg:createdBy: uros_sipetic
sbg:createdOn: 1552666475
sbg:id: h-7f6bd0bb/h-8863b1ef/h-fcb32ecd/0
sbg:image_url:
sbg:latestRevision: 14
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
    https://software.broadinstitute.org/gatk/documentation/tooldocs/4.1.0.0/picard_sam_MergeSamFiles.php
  label: Documentation
sbg:modifiedBy: nens
sbg:modifiedOn: 1560336165
sbg:project: uros_sipetic/gatk-4-1-0-0-demo
sbg:projectName: GATK 4.1.0.0 - Demo
sbg:publisher: sbg
sbg:revision: 14
sbg:revisionNotes: |-
  Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/37
sbg:revisionsInfo:
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1552666475
  sbg:revision: 0
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/12
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1554492767
  sbg:revision: 1
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/23
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1554720890
  sbg:revision: 2
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/24
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1554999266
  sbg:revision: 3
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/25
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557734540
  sbg:revision: 4
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/26
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000585
  sbg:revision: 5
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/27
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558017849
  sbg:revision: 6
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/28
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351570
  sbg:revision: 7
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/29
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558370509
  sbg:revision: 8
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/30
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558427482
  sbg:revision: 9
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/31
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558448356
  sbg:revision: 10
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/32
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558453788
  sbg:revision: 11
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/33
- sbg:modifiedBy: nemanja.vucic
  sbg:modifiedOn: 1559750464
  sbg:revision: 12
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/34
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1560335266
  sbg:revision: 13
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/36
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1560336165
  sbg:revision: 14
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-mergebamalignment-4-1-0-0/37
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.0.0
sbg:validationErrors: []
