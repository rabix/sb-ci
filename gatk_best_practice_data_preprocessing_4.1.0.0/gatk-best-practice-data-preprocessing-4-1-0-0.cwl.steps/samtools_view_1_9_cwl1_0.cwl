cwlVersion: v1.0
class: CommandLineTool
label: Samtools View CWL1.0
doc: |-
  **SAMtools View** tool prints all alignments from a SAM, BAM, or CRAM file to an output file in SAM format (headerless). You may specify one or more space-separated region specifications to restrict output to only those alignments which overlap the specified region(s). Use of region specifications requires a coordinate-sorted and indexed input file (in BAM or CRAM format) [1].

  *A list of **all inputs and parameters** with corresponding descriptions can be found at the bottom of the page.*

  ####Regions

  Regions can be specified as: RNAME[:STARTPOS[-ENDPOS]] and all position coordinates are 1-based. 

  **Important note:** when multiple regions are given, some alignments may be output multiple times if they overlap more than one of the specified regions.

  Examples of region specifications:

  - **chr1**  - Output all alignments mapped to the reference sequence named `chr1' (i.e. @SQ SN:chr1).

  - **chr2:1000000** - The region on chr2 beginning at base position 1,000,000 and ending at the end of the chromosome.

  - **chr3:1000-2000** - The 1001bp region on chr3 beginning at base position 1,000 and ending at base position 2,000 (including both end positions).

  - **'\*'** - Output the unmapped reads at the end of the file. (This does not include any unmapped reads placed on a reference sequence alongside their mapped mates.)

  - **.** - Output all alignments. (Mostly unnecessary as not specifying a region at all has the same effect.) [1]

  ###Common Use Cases

  This tool can be used for: 

  - Filtering BAM/SAM/CRAM files - options set by the following parameters and input files: **Include reads with all of these flags** (`-f`), **Exclude reads with any of these flags** (`-F`), **Exclude reads with all of these flags** (`-G`), **Read group** (`-r`), **Minimum mapping quality** (`-q`), **Only include alignments in library** (`-l`), **Minimum number of CIGAR bases consuming query sequence** (`-m`), **Subsample fraction** (`-s`), **Read group list** (`-R`), **BED region file** (`-L`)
  - Format conversion between SAM/BAM/CRAM formats - set by the following parameters: **Output format** (`--output-fmt/-O`), **Fast bam compression** (`-1`), **Output uncompressed BAM** (`-u`)
  - Modification of the data which is contained in each alignment - set by the following parameters: **Collapse the backward CIGAR operation** (`-B`), **Read tags to strip** (`-x`)
  - Counting number of alignments in SAM/BAM/CRAM file - set by parameter **Output only count of matching records** (`-c`)

  ###Changes Introduced by Seven Bridges

  - Parameters **Output BAM** (`-b`) and **Output CRAM** (`-C`) were excluded from the wrapper since they are redundant with parameter **Output format** (`--output-fmt/-O`).
  - Parameter **Input format** (`-S`) was excluded from wrapper since it is ignored by the tool (input format is auto-detected).
  - Input file **Index file** was added to the wrapper to enable operations that require an index file for BAM/CRAM files.
  - Parameter **Number of threads** (`--threads/-@`) specifies the total number of threads instead of additional threads. Command line argument (`--threads/-@`) will be reduced by 1 to set the number of additional threads.

  ###Common Issues and Important Notes

  - When multiple regions are given, some alignments may be output multiple times if they overlap more than one of the specified regions [1].
  - Use of region specifications requires a coordinate-sorted and indexed input file (in BAM or CRAM format) [1].
  - Option **Output uncompressed BAM** (`-u`) saves time spent on compression/decompression and is thus preferred when the output is piped to another SAMtools command [1].

  ###Performance Benchmarking

  Multithreading can be enabled by setting parameter **Number of threads** (`--threads/-@`). In the following table you can find estimates of **SAMtools View** running time and cost. 

  *Cost can be significantly reduced by using **spot instances**. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*  

  | Input type | Input size | # of reads | Read length | Output format | # of threads | Duration | Cost | Instance (AWS)|
  |---------------|--------------|-----------------|---------------|------------------|-------------------|-----------------|-------------|--------|-------------|
  | BAM | 5.26 GB | 71.5M | 76 | BAM | 1 | 13min. | \$0.12 | c4.2xlarge |
  | BAM | 11.86 GB | 161.2M | 101 | BAM | 1 | 33min. | \$0.30 | c4.2xlarge |
  | BAM | 18.36 GB | 179M | 76 | BAM | 1 | 60min. | \$0.54 | c4.2xlarge |
  | BAM | 58.61 GB | 845.6M | 150 | BAM | 1 | 3h 25min. | \$1.84 | c4.2xlarge |
  | BAM | 5.26 GB | 71.5M | 76 | BAM | 8 | 5min. | \$0.04 | c4.2xlarge |
  | BAM | 11.86 GB | 161.2M | 101 | BAM | 8 | 11min. | \$0.10 | c4.2xlarge |
  | BAM | 18.36 GB | 179M | 76 | BAM | 8 | 19min. | \$0.17 | c4.2xlarge |
  | BAM | 58.61 GB | 845.6M | 150 | BAM | 8 | 61min. | \$0.55 | c4.2xlarge |
  | BAM | 5.26 GB | 71.5M | 76 | SAM | 8 | 14min. | \$0.13 | c4.2xlarge |
  | BAM | 11.86 GB | 161.2M | 101 | SAM | 8 | 23min. | \$0.21 | c4.2xlarge |
  | BAM | 18.36 GB | 179M | 76 | SAM | 8 | 35min. | \$0.31 | c4.2xlarge |
  | BAM | 58.61 GB | 845.6M | 150 | SAM | 8 | 2h 29min. | \$1.34 | c4.2xlarge |

  ###References

  [1] [SAMtools documentation](http://www.htslib.org/doc/samtools-1.9.html)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: |-
    ${
      if (inputs.cpu_per_job) {
          return inputs.cpu_per_job
      }
      else {
      if((inputs.threads)){
        return (inputs.threads)
      }
      else{
        return 1
      }
      }
    }
  ramMin: |-
    ${
      if (inputs.mem_per_job) {
          return inputs.mem_per_job
      }    
      else {
      mem_offset = 1000
      if((inputs.in_reference)){
        mem_offset = mem_offset + 3000
      }
      if((inputs.threads)){
        threads = (inputs.threads)
      }
      else{
        threads = 1
      }
      return mem_offset + threads * 500
      }
    }
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/jrandjelovic/samtools-1-9:1
- class: InitialWorkDirRequirement
  listing:
  - $(inputs.in_reference)
  - $(inputs.reference_file_list)
  - $(inputs.in_index)
  - $(inputs.in_alignments)
- class: InlineJavascriptRequirement
  expressionLib:
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
- id: in_index
  label: Index file
  doc: This tool requires index file for some use cases.
  type: File?
  sbg:category: File inputs
  sbg:fileTypes: BAI, CRAI, CSI
- id: output_format
  label: Output format
  doc: Output file format
  type:
  - 'null'
  - name: output_format
    type: enum
    symbols:
    - SAM
    - BAM
    - CRAM
  inputBinding:
    prefix: --output-fmt
    position: 1
    shellQuote: false
  sbg:altPrefix: -O
  sbg:category: Config inputs
  sbg:toolDefaultValue: SAM
- id: fast_bam_compression
  label: Fast BAM compression
  doc: Enable fast BAM compression (implies output in bam format).
  type: boolean?
  inputBinding:
    prefix: '-1'
    position: 2
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'False'
- id: uncompressed_bam
  label: Output uncompressed BAM
  doc: |-
    Output uncompressed BAM (implies output BAM format). This option saves time spent on compression/decompression and is thus preferred when the output is piped to another SAMtools command.
  type: boolean?
  inputBinding:
    prefix: -u
    position: 3
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'False'
- id: include_header
  label: Include the header in the output
  doc: Include the header in the output.
  type: boolean?
  inputBinding:
    prefix: -h
    position: 4
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'False'
- id: output_header_only
  label: Output the header only
  doc: Output the header only.
  type: boolean?
  inputBinding:
    prefix: -H
    position: 5
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'False'
- id: collapse_cigar
  label: Collapse the backward CIGAR operation
  doc: Collapse the backward CIGAR operation.
  type: boolean?
  inputBinding:
    prefix: -B
    position: 6
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'False'
- id: filter_include
  label: Include reads with all of these flags
  doc: |-
    Only output alignments with all bits set in this integer present in the FLAG field.
  type: int?
  inputBinding:
    prefix: -f
    position: 7
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: '0'
- id: filter_exclude_any
  label: Exclude reads with any of these flags
  doc: |-
    Do not output alignments with any bits set in this integer present in the FLAG field.
  type: int?
  inputBinding:
    prefix: -F
    position: 8
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: '0'
- id: filter_exclude_all
  label: Exclude reads with all of these flags
  doc: |-
    Only exclude reads with all of the bits set in this integer present in the FLAG field.
  type: int?
  inputBinding:
    prefix: -G
    position: 9
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: '0'
- id: read_group
  label: Read group
  doc: Only output reads in the specified read group.
  type: string?
  inputBinding:
    prefix: -r
    position: 10
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'null'
- id: filter_mapq
  label: Minimum mapping quality
  doc: Skip alignments with MAPQ smaller than this value.
  type: int?
  inputBinding:
    prefix: -q
    position: 11
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: '0'
- id: filter_library
  label: Only include alignments in library
  doc: Only output alignments in this library.
  type: string?
  inputBinding:
    prefix: -l
    position: 12
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'null'
- id: min_cigar_operations
  label: Minimum number of CIGAR bases consuming query sequence
  doc: |-
    Only output alignments with number of CIGAR bases consuming query sequence  ≥ INT.
  type: int?
  inputBinding:
    prefix: -m
    position: 13
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: '0'
- id: read_tag_to_strip
  label: Read tags to strip
  doc: Read tag to exclude from output (repeatable).
  type: string[]?
  inputBinding:
    prefix: ''
    position: 14
    valueFrom: |-
      ${
          if (self)
          {
              var cmd = [];
              for (var i = 0; i < self.length; i++) 
              {
                  cmd.push('-x', self[i]);
                  
              }
              return cmd.join(' ');
          }
      }
    itemSeparator: ' '
    shellQuote: false
  sbg:category: Config Inputs
- id: count_alignments
  label: Output only count of matching records
  doc: |-
    Instead of outputing the alignments, only count them and output the total number. All filter options, such as -f, -F, and -q, are taken into account.
  type: boolean?
  inputBinding:
    prefix: -c
    position: 15
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: 'False'
- id: input_fmt_option
  label: Input file format option
  doc: Specify a single input file format option in the form of OPTION or OPTION=VALUE.
  type: string?
  inputBinding:
    prefix: --input-fmt-option
    position: 16
    shellQuote: false
  sbg:category: Config Inputs
- id: output_fmt_option
  label: Output file format option
  doc: |-
    Specify a single output file format option in the form of OPTION or OPTION=VALUE.
  type: string?
  inputBinding:
    prefix: --output-fmt-option
    position: 17
    shellQuote: false
  sbg:category: Config Inputs
- id: subsample_fraction
  label: Subsample fraction
  doc: |-
    Output only a proportion of the input alignments. This subsampling acts in the same way on all of the alignment records in the same template or read pair, so it never keeps a read but not its mate. The integer and fractional parts of the INT.FRAC are used separately: the part after the decimal point sets the fraction of templates/pairs to be kept, while the integer part is used as a seed that influences which subset of reads is kept. When subsampling data that has previously been subsampled, be sure to use a different seed value from those used previously; otherwise more reads will be retained than expected.
  type: float?
  inputBinding:
    prefix: -s
    position: 18
    shellQuote: false
  sbg:category: Config Inputs
- id: threads
  label: Number of threads
  doc: |-
    Number of threads. SAMtools uses argument --threads/-@ to specify number of additional threads. This parameter sets total number of threads (and CPU cores). Command line argument will be reduced by 1 to set number of additional threads.
  type: int?
  inputBinding:
    prefix: --threads
    position: 19
    valueFrom: |-
      ${
        if((inputs.threads)){
          return (inputs.threads) - 1
        }
        else{
          return
        }
      }
    shellQuote: false
  sbg:altPrefix: -@
  sbg:category: Execution
  sbg:toolDefaultValue: '1'
- id: omitted_reads_filename
  label: Filename for reads not selected by filters
  doc: |-
    Write alignments that are not selected by the various filter options to this file. When this option is used, all alignments (or all alignments intersecting the regions specified) are written to either the output file or this file, but never both.
  type: string?
  inputBinding:
    prefix: -U
    position: 20
    shellQuote: false
  sbg:category: Config Inputs
- id: output_filename
  label: Output filename
  doc: Define a filename of the output.
  type: string?
  default: default_output_filename
  inputBinding:
    prefix: -o
    position: 21
    valueFrom: |-
      ${
        if (inputs.output_filename!="default_output_filename"){
          return (inputs.output_filename)
        }
        input_filename = [].concat(inputs.in_alignments)[0].path.split('/').pop()
        input_name_base = input_filename.split('.').slice(0,-1).join('.')
        ext = 'sam'
        if (inputs.count_alignments){
          return input_name_base + '.count.txt'
        }
        if ((inputs.uncompressed_bam) || (inputs.fast_bam_compression)){
          ext = 'bam'
        }
        if (inputs.output_format){
          ext = (inputs.output_format).toLowerCase()
        }
        if (inputs.output_header_only){
          ext = 'header.' + ext
        }
        if (inputs.subsample_fraction){
          ext = 'subsample.' + ext
        }
        if ((inputs.bed_file) || (inputs.read_group) || (inputs.read_group_list) ||
            (inputs.filter_mapq) || (inputs.filter_library) || (inputs.min_cigar_operations) ||
            (inputs.filter_include) || (inputs.filter_exclude_any) || 
            (inputs.filter_exclude_all) || (inputs.regions_array)){
          ext = 'filtered.' + ext
        }
          
        return input_name_base + '.' + ext
      }
    shellQuote: false
  sbg:category: Config Inputs
  sbg:toolDefaultValue: stdout
- id: bed_file
  label: BED region file
  doc: Only output alignments overlapping the input BED file.
  type: File?
  inputBinding:
    prefix: -L
    position: 22
    shellQuote: false
  sbg:category: File Inputs
  sbg:fileTypes: BED
- id: read_group_list
  label: Read group list
  doc: Output alignments in read groups listed in this file.
  type: File?
  inputBinding:
    prefix: -R
    position: 23
    shellQuote: false
  sbg:category: File Inputs
  sbg:fileTypes: TXT
- id: in_reference
  label: Reference file
  doc: |-
    A FASTA format reference file, optionally compressed by bgzip and ideally indexed by SAMtools Faidx. If an index is not present, one will be generated for you. This file is used for compression/decompression of CRAM files. Please provide reference file when using CRAM input/output file.
  type: File?
  inputBinding:
    prefix: --reference
    position: 24
    shellQuote: false
  sbg:altPrefix: -T
  sbg:category: File Inputs
  sbg:fileTypes: FASTA, FA, FASTA.GZ, FA.GZ, GZ
- id: reference_file_list
  label: List of reference names and lengths
  doc: |-
    A tab-delimited file. Each line must contain the reference name in the first column and the length of the reference in the second column, with one line for each distinct reference. Any additional fields beyond the second column are ignored. This file also defines the order of the reference sequences in sorting. If you run SAMtools Faidx on reference FASTA file (<ref.fa>), the resulting index file <ref.fa>.fai can be used as this file.
  type: File?
  inputBinding:
    prefix: -t
    position: 25
    shellQuote: false
  sbg:category: File Inputs
  sbg:fileTypes: FAI, TSV, TXT
- id: in_alignments
  label: Input BAM/SAM/CRAM file
  doc: Input BAM/SAM/CRAM file.
  type: File
  inputBinding:
    position: 99
    shellQuote: false
  sbg:category: File Inputs
  sbg:fileTypes: BAM, SAM, CRAM
- id: regions_array
  label: Regions array
  doc: |-
    With no options or regions specified, prints all alignments in the specified input alignment file (in SAM, BAM, or CRAM format) to output file in specified format. Use of region specifications requires a coordinate-sorted and indexed input file (in BAM or CRAM format). Regions can be specified as: RNAME[:STARTPOS[-ENDPOS]] and all position coordinates are 1-based.  Important note: when multiple regions are given, some alignments may be output multiple times if they overlap more than one of the specified regions. Examples of region specifications:  chr1 - Output all alignments mapped to the reference sequence named `chr1' (i.e. @SQ SN:chr1);  chr2:1000000 - The region on chr2 beginning at base position 1,000,000 and ending at the end of the chromosome;  chr3:1000-2000 - The 1001bp region on chr3 beginning at base position 1,000 and ending at base position 2,000 (including both end positions);  '*' - Output the unmapped reads at the end of the file (this does not include any unmapped reads placed on a reference sequence alongside their mapped mates.);  . - Output all alignments (mostly unnecessary as not specifying a region at all has the same effect).
  type: string[]?
  inputBinding:
    position: 100
    shellQuote: false
  sbg:category: Config Inputs
- id: multi_region_iterator
  label: Use the multi-region iterator
  doc: |-
    Use the multi-region iterator on the union of the BED file and command-line region arguments.
  type: boolean?
  inputBinding:
    prefix: -M
    position: 22
    shellQuote: false
  sbg:category: Config inputs
  sbg:toolDefaultValue: 'False'
- id: mem_per_job
  label: Memory per job
  doc: Memory per job in MB.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '1500'
- id: cpu_per_job
  label: CPU per job
  doc: Number of CPUs per job.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '1'

outputs:
- id: out_alignments
  label: Output BAM, SAM, or CRAM file
  doc: The output file.
  type: File?
  outputBinding:
    glob: |-
      ${
        if ((inputs.output_filename!="default_output_filename")){
          return (inputs.output_filename)
        }
        input_filename = [].concat((inputs.in_alignments))[0].path.split('/').pop()
        input_name_base = input_filename.split('.').slice(0,-1). join('.')
        ext = 'sam'
        if ((inputs.count_alignments)){
          return 
        }
        if ((inputs.uncompressed_bam) || (inputs.fast_bam_compression)){
          ext = 'bam'
        }
        if ((inputs.output_format)){
          ext = (inputs.output_format).toLowerCase()
        }
        if ((inputs.output_header_only)){
          ext = 'header.' + ext
        }
        if ((inputs.subsample_fraction)){
          ext = 'subsample.' + ext
        }
        if ((inputs.bed_file) || (inputs.read_group) || (inputs.read_group_list) ||
            (inputs.filter_mapq) || (inputs.filter_library) || (inputs.min_cigar_operations) ||
            (inputs.filter_include) || (inputs.filter_exclude_any) || 
            (inputs.filter_exclude_all) || (inputs.regions_array)){
          ext = 'filtered.' + ext
        }
          
        return input_name_base + '.' + ext
      }
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: BAM, SAM, CRAM
- id: reads_not_selected_by_filters
  label: Reads not selected by filters
  doc: File containing reads that are not selected by filters.
  type: File?
  outputBinding:
    glob: |-
      ${
        if ((inputs.omitted_reads_filename)){
          return (inputs.omitted_reads_filename)
        }
      }
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: BAM, SAM, CRAM
- id: alignement_count
  label: Alignment count
  doc: File containing number of alignments.
  type: File?
  outputBinding:
    glob: |-
      ${
        input_filename = [].concat((inputs.in_alignments))[0].path.split('/').pop()
        input_name_base = input_filename.split('.').slice(0,-1). join('.')
        return input_name_base + '.count.txt'
      }
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
  sbg:fileTypes: TXT

baseCommand:
- /opt/samtools-1.9/samtools
- view
id: h-ba837119/h-8e5d61a4/h-6e7ff44b/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BAM Processing
- CWL1.0
sbg:content_hash: ab372090457bac69a1b2bd8deff4ef40ca29052f82dd4850241d8d9e1096eed34
sbg:contributors:
- lea_lenhardt_ackovic
sbg:createdBy: lea_lenhardt_ackovic
sbg:createdOn: 1572600501
sbg:id: h-ba837119/h-8e5d61a4/h-6e7ff44b/0
sbg:image_url:
sbg:latestRevision: 6
sbg:license: MIT License
sbg:links:
- id: http://www.htslib.org/
  label: Homepage
- id: https://github.com/samtools/samtools
  label: Source Code
- id: https://github.com/samtools/samtools/wiki
  label: Wiki
- id: https://sourceforge.net/projects/samtools/files/samtools/
  label: Download
- id: http://www.ncbi.nlm.nih.gov/pubmed/19505943
  label: Publication
- id: http://www.htslib.org/doc/samtools-1.9.html
  label: Documentation
sbg:modifiedBy: lea_lenhardt_ackovic
sbg:modifiedOn: 1578571408
sbg:project: lea_lenhardt_ackovic/samtools-1-9-cwl1-0-demo
sbg:projectName: SAMtools 1.9 - CWL1.0 - Demo
sbg:publisher: sbg
sbg:revision: 6
sbg:revisionNotes: Added file requirements for in_index and in_alignments
sbg:revisionsInfo:
- sbg:modifiedBy: lea_lenhardt_ackovic
  sbg:modifiedOn: 1572600501
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: lea_lenhardt_ackovic
  sbg:modifiedOn: 1572600525
  sbg:revision: 1
  sbg:revisionNotes: Final version
- sbg:modifiedBy: lea_lenhardt_ackovic
  sbg:modifiedOn: 1575029042
  sbg:revision: 2
  sbg:revisionNotes: Edited description, tag, default values.
- sbg:modifiedBy: lea_lenhardt_ackovic
  sbg:modifiedOn: 1575042426
  sbg:revision: 3
  sbg:revisionNotes: mem_per_job default value set
- sbg:modifiedBy: lea_lenhardt_ackovic
  sbg:modifiedOn: 1576241025
  sbg:revision: 4
  sbg:revisionNotes: Description edited - references put before full stop
- sbg:modifiedBy: lea_lenhardt_ackovic
  sbg:modifiedOn: 1576242427
  sbg:revision: 5
  sbg:revisionNotes: Categories edited
- sbg:modifiedBy: lea_lenhardt_ackovic
  sbg:modifiedOn: 1578571408
  sbg:revision: 6
  sbg:revisionNotes: Added file requirements for in_index and in_alignments
sbg:sbgMaintained: false
sbg:toolAuthor: |-
  Heng Li (Sanger Institute), Bob Handsaker (Broad Institute), Jue Ruan (Beijing Genome Institute), Colin Hercus, Petr Danecek
sbg:toolkit: samtools
sbg:toolkitVersion: '1.9'
sbg:validationErrors: []
