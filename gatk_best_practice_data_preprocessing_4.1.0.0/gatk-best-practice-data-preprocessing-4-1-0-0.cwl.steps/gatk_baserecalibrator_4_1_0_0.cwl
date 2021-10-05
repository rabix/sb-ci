cwlVersion: v1.0
class: CommandLineTool
label: GATK BaseRecalibrator CWL1.0
doc: |-
  **GATK BaseRecalibrator** generates a recalibration table based on various covariates for input mapped read data [1]. It performs the first pass of the Base Quality Score Recalibration (BQSR) by assessing base quality scores of the input data.

  *A list of **all inputs and parameters** with corresponding descriptions can be found at the bottom of the page.*

  ###Common Use Cases

  * The **GATK BaseRecalibrator** tool requires the input mapped read data whose quality scores need to be assessed on its **Input alignments** (`--input`) input, the database of known polymorphic sites to skip over on its **Known sites** (`--known-sites`) input and a reference file on its **Reference** (`--reference`) input. On its **Output recalibration report** output, the tool generates a GATK report file with many tables: the list of arguments, the quantized qualities table, the recalibration table by read group, the recalibration table by quality score,
  the recalibration table for all the optional covariates [1].

  * Usage example:

  ```
  gatk --java-options "-Xmx2048M" BaseRecalibrator \
     --input my_reads.bam \
     --reference reference.fasta \
     --known-sites sites_of_variation.vcf \
     --known-sites another/optional/setOfSitesToMask.vcf \
     --output recal_data.table

  ```

  ###Changes Introduced by Seven Bridges

  * The output file will be prefixed using the **Output name prefix** parameter. If this value is not set, the output name will be generated based on the **Sample ID** metadata value from the input alignment file. If the **Sample ID** value is not set, the name will be inherited from the input alignment file name. In case there are multiple files on the **Input alignments** input, the files will be sorted by name and output file name will be generated based on the first file in the sorted file list, following the rules defined in the previous case. Moreover,  **recal_data** will be added before the extension of the output file name which is **CSV** by default.

  * **Include intervals** (`--intervals`) option is divided into **Include intervals string** and **Include intervals file** options.

  * **Exclude intervals** (`--exclude-intervals`) option is divided into **Exclude intervals string** and **Exclude intervals file** options.

  * The following GATK parameters were excluded from the tool wrapper: `--add-output-sam-program-record`, `--add-output-vcf-command-line`, `--arguments_file`, `--cloud-index-prefetch-buffer`, `--cloud-prefetch-buffer`, `--create-output-bam-index`, `--create-output-bam-md5`, `--create-output-variant-index`, `--create-output-variant-md5`, `--gatk-config-file`, `--gcs-max-retries`, `--gcs-project-for-requester-pays`, `--help`, `--lenient`, `--QUIET`, `--sites-only-vcf-output`, `--showHidden`, `--tmp-dir`, `--use-jdk-deflater`, `--use-jdk-inflater`, `--verbosity`, `--version`



  ###Common Issues and Important Notes

  *  **Memory per job** (`mem_per_job`) input allows a user to set the desired memory requirement when running a tool or adding it to a workflow. This input should be defined in MB. It is propagated to the Memory requirements part and “-Xmx” parameter of the tool. The default value is 2048MB.
  * **Memory overhead per job** (`mem_overhead_per_job`) input allows a user to set the desired overhead memory when running a tool or adding it to a workflow. This input should be defined in MB. This amount will be added to the Memory per job in the Memory requirements section but it will not be added to the “-Xmx” parameter. The default value is 100MB. 
  * Note: GATK tools that take in mapped read data expect a BAM file as the primary format [2]. More on GATK requirements for mapped sequence data formats can be found [here](https://gatk.broadinstitute.org/hc/en-us/articles/360035890791-SAM-or-BAM-or-CRAM-Mapped-sequence-data-formats).
  * Note: **Known sites**, **Input alignments** should have corresponding index files in the same folder. 
  * Note: **Reference** FASTA file should have corresponding .fai (FASTA index) and .dict (FASTA dictionary) files in the same folder. 
  * Note: These **Read Filters** (`--read-filter`) are automatically applied to the data by the Engine before processing by **BaseRecalibrator** [1]: **NotSecondaryAlignmentReadFilter**, **PassesVendorQualityCheckReadFilter**, **MappedReadFilter**, **MappingQualityAvailableReadFilter**, **NotDuplicateReadFilter**, **MappingQualityNotZeroReadFilter**, **WellformedReadFilter**
  * Note: If the **Read filter** (`--read-filter`) option is set to "LibraryReadFilter", the **Library** (`--library`) option must be set to some value.
  * Note: If the **Read filter** (`--read-filter`) option is set to "PlatformReadFilter", the **Platform filter name** (`--platform-filter-name`) option must be set to some value.
  * Note: If the **Read filter** (`--read-filter`) option is set to"PlatformUnitReadFilter", the **Black listed lanes** (`--black-listed-lanes`) option must be set to some value. 
  * Note: If the **Read filter** (`--read-filter`) option is set to "ReadGroupBlackListReadFilter", the **Read group black list** (`--read-group-black-list`) option must be set to some value.
  * Note: If the **Read filter** (`--read-filter`) option is set to "ReadGroupReadFilter", the **Keep read group** (`--keep-read-group`) option must be set to some value.
  * Note: If the **Read filter** (`--read-filter`) option is set to "ReadLengthReadFilter", the **Max read length** (`--max-read-length`) option must be set to some value.
  * Note: If the **Read filter** (`--read-filter`) option is set to "ReadNameReadFilter", the **Read name** (`--read-name`) option must be set to some value.
  * Note: If the **Read filter** (`--read-filter`) option is set to "ReadStrandFilter", the **Keep reverse strand only** (`--keep-reverse-strand-only`) option must be set to some value.
  * Note: If the **Read filter** (`--read-filter`) option is set to "SampleReadFilter", the **Sample** (`--sample`) option must be set to some value.
  * Note: The following options are valid only if the appropriate **Read filter** (`--read-filter`) is specified: **Ambig filter bases** (`--ambig-filter-bases`), **Ambig filter frac** (`--ambig-filter-frac`), **Max fragment length** (`--max-fragment-length`), **Maximum mapping quality** (`--maximum-mapping-quality`), **Minimum mapping quality** (`--minimum-mapping-quality`),  **Do not require soft clips** (`--dont-require-soft-clips-both-ends`), **Filter too short** (`--filter-too-short`), **Min read length** (`--min-read-length`). See the description of each parameter for information on the associated **Read filter**.
  * Note: The wrapper has not been tested for the SAM file type on the **Input alignments** input port, nor for the BCF file type on the **Known sites** input port.

  ###Performance Benchmarking

  Below is a table describing runtimes and task costs of **GATK BaseRecalibrator** for a couple of different samples, executed on AWS cloud instances:

  | Experiment type |  Input size | Duration |  Cost (on-demand) | Instance (AWS) | 
  |:--------------:|:------------:|:--------:|:-------:|:---------:|
  |     RNA-Seq     |  2.2 GB |   9min   | ~0.08$ | c4.2xlarge (8 CPUs) | 
  |     RNA-Seq     |  6.6 GB |   19min   | ~0.17$ | c4.2xlarge (8 CPUs) | 
  |     RNA-Seq     | 11 GB |  27min  | ~0.24$ | c4.2xlarge (8 CPUs) | 
  |     RNA-Seq     | 22 GB |  46min  | ~0.41$ | c4.2xlarge (8 CPUs) |

  *Cost can be significantly reduced by using **spot instances**. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*

  ###References

  [1] [GATK BaseRecalibrator](https://gatk.broadinstitute.org/hc/en-us/articles/360036726891-BaseRecalibrator)

  [2] [GATK Mapped sequence data formats](https://gatk.broadinstitute.org/hc/en-us/articles/360035890791-SAM-or-BAM-or-CRAM-Mapped-sequence-data-formats)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: "${\n    return inputs.cpu_per_job ? inputs.cpu_per_job : 1;\n}"
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
- id: ambig_filter_bases
  label: Ambig filter bases
  doc: |-
    Valid only if "AmbiguousBaseReadFilter" is specified:
    Threshold number of ambiguous bases. If null, uses threshold fraction; otherwise, overrides threshold fraction. Cannot be used in conjuction with argument(s) ambig-filter-frac.
  type: int?
  inputBinding:
    prefix: --ambig-filter-bases
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: 'null'
- id: ambig_filter_frac
  label: Ambig filter frac
  doc: |-
    Valid only if "AmbiguousBaseReadFilter" is specified:
    Threshold fraction of ambiguous bases. Cannot be used in conjuction with argument(s) ambig-filter-bases.
  type: float?
  inputBinding:
    prefix: --ambig-filter-frac
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: '0.05'
- id: binary_tag_name
  label: Binary tag name
  doc: The binary tag covariate name if using it.
  type: string?
  inputBinding:
    prefix: --binary-tag-name
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: black_listed_lanes
  label: Black listed lanes
  doc: |-
    Valid only if "PlatformUnitReadFilter" is specified:
    Platform unit (PU) to filter out. This argument must be specified at least once. Required.
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          if (inputs.black_listed_lanes)
          {
              var bl_lanes = [].concat(inputs.black_listed_lanes);
              var cmd = [];
              for (var i = 0; i < bl_lanes.length; i++) 
              {
                  cmd.push('--black-listed-lanes', bl_lanes[i]);
              }
              return cmd.join(' ');
          }
          return '';
      }
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
- id: bqsr_baq_gap_open_penalty
  label: BQSR BAQ gap open penalty
  doc: |-
    BQSR BAQ gap open penalty (Phred Scaled). Default value is 40. 30 is perhaps better for whole genome call sets.
  type: float?
  inputBinding:
    prefix: --bqsr-baq-gap-open-penalty
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '40'
- id: default_base_qualities
  label: Default base qualities
  doc: Assign a default base quality.
  type: int?
  inputBinding:
    prefix: --default-base-qualities
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '-1'
- id: deletions_default_quality
  label: Deletions default quality
  doc: Default quality for the base deletions covariate.
  type: int?
  inputBinding:
    prefix: --deletions-default-quality
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '45'
- id: disable_read_filter
  label: Disable read filter
  doc: |-
    Read filters to be disabled before analysis. This argument may be specified 0 or more times.
  type:
  - 'null'
  - type: array
    items:
      name: disable_read_filter
      type: enum
      symbols:
      - MappedReadFilter
      - MappingQualityAvailableReadFilter
      - MappingQualityNotZeroReadFilter
      - NotDuplicateReadFilter
      - NotSecondaryAlignmentReadFilter
      - PassesVendorQualityCheckReadFilter
      - WellformedReadFilter
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
                  cmd.push('--disable-read-filter', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:altPrefix: -DF
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: disable_sequence_dictionary_validation
  label: Disable sequence dictionary validation
  doc: |-
    If specified, do not check the sequence dictionaries from our inputs for compatibility. Use at your own risk!
  type: boolean?
  inputBinding:
    prefix: --disable-sequence-dictionary-validation
    position: 4
    shellQuote: false
  sbg:altPrefix: -disable-sequence-dictionary-validation
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: disable_tool_default_read_filters
  label: Disable tool default read filters
  doc: |-
    Disable all tool default read filters (WARNING: many tools will not function correctly without their default read filters on).
  type: boolean?
  inputBinding:
    prefix: --disable-tool-default-read-filters
    position: 4
    shellQuote: false
  sbg:altPrefix: -disable-tool-default-read-filters
  sbg:category: Advanced Arguments
  sbg:toolDefaultValue: 'false'
- id: dont_require_soft_clips_both_ends
  label: Dont require soft clips both ends
  doc: |-
    Valid only if "OverclippedReadFilter" is specified:
    Allow a read to be filtered out based on having only 1 soft-clipped block. By default, both ends must have a soft-clipped block, setting this flag requires only 1 soft-clipped block.
  type: boolean?
  inputBinding:
    prefix: --dont-require-soft-clips-both-ends
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: 'false'
- id: exclude_intervals_file
  label: Exclude intervals file
  doc: One or more genomic intervals to exclude from processing.
  type: File?
  inputBinding:
    prefix: --exclude-intervals
    position: 4
    shellQuote: false
  sbg:altPrefix: -XL
  sbg:category: Optional Arguments
  sbg:fileTypes: BED, LIST, INTERVAL_LIST
  sbg:toolDefaultValue: 'null'
- id: exclude_intervals_string
  label: Exclude intervals string
  doc: |-
    One or more genomic intervals to exclude from processing. This argument may be specified 0 or more times.
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |+
      ${
          if (inputs.exclude_intervals_string)
          {
              var exclude_string = [].concat(inputs.exclude_intervals_string);
              var cmd = [];
              for (var i = 0; i < exclude_string.length; i++) 
              {
                  cmd.push('--exclude-intervals', exclude_string[i]);
              }
              return cmd.join(' ');
          }
          return '';
      }


    shellQuote: false
  sbg:altPrefix: -XL
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: filter_too_short
  label: Filter too short
  doc: |-
    Valid only if "OverclippedReadFilter" is specified:
    Minimum number of aligned bases.
  type: int?
  inputBinding:
    prefix: --filter-too-short
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: '30'
- id: indels_context_size
  label: Indels context size
  doc: Size of the k-mer context to be used for base insertions and deletions.
  type: int?
  inputBinding:
    prefix: --indels-context-size
    position: 4
    shellQuote: false
  sbg:altPrefix: -ics
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '3'
- id: in_alignments
  label: Input alignments
  doc: |-
    BAM/SAM/CRAM file containing reads. This argument must be specified at least once.
  type: File[]
  secondaryFiles:
  - |-
    ${
        var in_alignments = self;
        if (in_alignments.nameext == '.bam' || in_alignments.nameext == '.BAM') {
            return [in_alignments.basename + ".bai", in_alignments.nameroot + ".bai"];
        }
        else if (in_alignments.nameext == '.cram' || in_alignments.nameext == '.CRAM') {
            return [in_alignments.basename + ".crai", in_alignments.nameroot + ".crai", in_alignments.basename + ".bai"];     
        }
        return '';
    }
  inputBinding:
    position: 4
    valueFrom: |
      ${
          if (inputs.in_alignments) {
              var alignments = [].concat(inputs.in_alignments);
              var cmd = [];
              for (var i=0; i<alignments.length; i++) {
                  cmd.push('--input', alignments[i].path);
              }
              return cmd.join(' ');
          } 
          return '';
      }
    shellQuote: false
  sbg:altPrefix: -I
  sbg:category: Required Arguments
  sbg:fileTypes: BAM, CRAM
- id: insertions_default_quality
  label: Insertions default quality
  doc: Default quality for the base insertions covariate.
  type: int?
  inputBinding:
    prefix: --insertions-default-quality
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '45'
- id: interval_exclusion_padding
  label: Interval exclusion padding
  doc: Amount of padding (in bp) to add to each interval you are excluding.
  type: int?
  inputBinding:
    prefix: --interval-exclusion-padding
    position: 4
    shellQuote: false
  sbg:altPrefix: -ixp
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '0'
- id: interval_merging_rule
  label: Interval merging rule
  doc: Interval merging rule for abutting intervals.
  type:
  - 'null'
  - name: interval_merging_rule
    type: enum
    symbols:
    - ALL
    - OVERLAPPING_ONLY
  inputBinding:
    prefix: --interval-merging-rule
    position: 4
    shellQuote: false
  sbg:altPrefix: -imr
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: ALL
- id: interval_padding
  label: Interval padding
  doc: Amount of padding (in bp) to add to each interval you are including.
  type: int?
  inputBinding:
    prefix: --interval-padding
    position: 4
    shellQuote: false
  sbg:altPrefix: -ip
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '0'
- id: interval_set_rule
  label: Interval set rule
  doc: Set merging approach to use for combining interval inputs.
  type:
  - 'null'
  - name: interval_set_rule
    type: enum
    symbols:
    - UNION
    - INTERSECTION
  inputBinding:
    prefix: --interval-set-rule
    position: 4
    shellQuote: false
  sbg:altPrefix: -isr
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: UNION
- id: include_intervals_file
  label: Include intervals file
  doc: One or more genomic intervals over which to operate.
  type: File?
  inputBinding:
    prefix: --intervals
    position: 4
    shellQuote: false
  sbg:altPrefix: -L
  sbg:category: Optional Arguments
  sbg:fileTypes: BED, LIST, INTERVAL_LIST
  sbg:toolDefaultValue: 'null'
- id: include_intervals_string
  label: Include intervals string
  doc: |-
    One or more genomic intervals over which to operate. This argument may be specified 0 or more times.
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |+
      ${
          if (inputs.include_intervals_string)
          {
              var include_string = [].concat(inputs.include_intervals_string);
              var cmd = [];
              for (var i = 0; i < include_string.length; i++) 
              {
                  cmd.push('--intervals', include_string[i]);
              }
              return cmd.join(' ');
          }
          return '';
      }


    shellQuote: false
  sbg:altPrefix: -L
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: keep_read_group
  label: Keep read group
  doc: |-
    Valid only if "ReadGroupReadFilter" is specified:
    The name of the read group to keep. Required.
  type: string?
  inputBinding:
    prefix: --keep-read-group
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
- id: keep_reverse_strand_only
  label: Keep reverse strand only
  doc: |-
    Valid only if "ReadStrandFilter" is specified:
    Keep only reads on the reverse strand. Required.
  type:
  - 'null'
  - name: keep_reverse_strand_only
    type: enum
    symbols:
    - 'true'
    - 'false'
  inputBinding:
    prefix: --keep-reverse-strand-only
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
- id: known_sites
  label: Known sites
  doc: |-
    One or more databases of known polymorphic sites used to exclude regions around known polymorphisms from analysis.  This argument must be specified at least once.
  type: File[]
  secondaryFiles:
  - |-
    ${
        var in_sites = self;
        if (in_sites.nameext == ".gz" || in_sites.nameext == '.GZ') {
                var tmp = in_sites.basename.slice(-7);
                if(tmp.toLowerCase() == '.vcf.gz') {
                    return in_sites.basename + ".tbi";  
                }
        }
        else if (in_sites.nameext == '.vcf' || in_sites.nameext == '.VCF' || in_sites.nameext == '.bed' || in_sites.nameext == '.BED') {
            return in_sites.basename + ".idx";
        }
        return in_sites.basename + ".idx";
    }
  inputBinding:
    position: 5
    valueFrom: |-
      ${
          if (inputs.known_sites)
          {
              var sites = [].concat(inputs.known_sites);
              var cmd = [];
              for (var i = 0; i < sites.length; i++) 
              {
                  cmd.push('--known-sites', sites[i].path);
              }
              return cmd.join(' ');
          }
          return '';
      }
    shellQuote: false
  sbg:category: Required Arguments
  sbg:fileTypes: VCF, VCF.GZ, BED
- id: library
  label: Library
  doc: |-
    Valid only if "LibraryReadFilter" is specified:
    Name of the library to keep. This argument must be specified at least once. Required.
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          if (inputs.library)
          {
              var lib = [].concat(inputs.library);
              var cmd = [];
              for (var i = 0; i < lib.length; i++) 
              {
                  cmd.push('--library', lib[i]);
              }
              return cmd.join(' ');
          }
          return '';
      }
    shellQuote: false
  sbg:altPrefix: -library
  sbg:category: Conditional Arguments for readFilter
- id: low_quality_tail
  label: Low quality tail
  doc: Minimum quality for the bases in the tail of the reads to be considered.
  type: int?
  inputBinding:
    prefix: --low-quality-tail
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '2'
- id: max_fragment_length
  label: Max fragment length
  doc: |-
    Valid only if "FragmentLengthReadFilter" is specified:
    Maximum length of fragment (insert size).
  type: int?
  inputBinding:
    prefix: --max-fragment-length
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: '1000000'
- id: max_read_length
  label: Max read length
  doc: |-
    Valid only if "ReadLengthReadFilter" is specified:
    Keep only reads with length at most equal to the specified value. Required.
  type: int?
  inputBinding:
    prefix: --max-read-length
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
- id: maximum_cycle_value
  label: Maximum cycle value
  doc: The maximum cycle value permitted for the Cycle covariate.
  type: int?
  inputBinding:
    prefix: --maximum-cycle-value
    position: 4
    shellQuote: false
  sbg:altPrefix: -max-cycle
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '500'
- id: maximum_mapping_quality
  label: Maximum mapping quality
  doc: |-
    Valid only if "MappingQualityReadFilter" is specified:
    Maximum mapping quality to keep (inclusive).
  type: int?
  inputBinding:
    prefix: --maximum-mapping-quality
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: 'null'
- id: mem_overhead_per_job
  label: Memory overhead per job
  doc: |-
    It allows a user to set the desired overhead memory (in MB) when running a tool or adding it to a workflow.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '100'
- id: mem_per_job
  label: Memory per job
  doc: |-
    It allows a user to set the desired memory requirement (in MB) when running a tool or adding it to a workflow.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '2048'
- id: min_read_length
  label: Min read length
  doc: |-
    Valid only if "ReadLengthReadFilter" is specified:
    Keep only reads with length at least equal to the specified value.
  type: int?
  inputBinding:
    prefix: --min-read-length
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: '1'
- id: minimum_mapping_quality
  label: Minimum mapping quality
  doc: |-
    Valid only if "MappingQualityReadFilter" is specified:
    Minimum mapping quality to keep (inclusive).
  type: int?
  inputBinding:
    prefix: --minimum-mapping-quality
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
  sbg:toolDefaultValue: '10'
- id: mismatches_context_size
  label: Mismatches context size
  doc: Size of the k-mer context to be used for base mismatches.
  type: int?
  inputBinding:
    prefix: --mismatches-context-size
    position: 4
    shellQuote: false
  sbg:altPrefix: -mcs
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '2'
- id: mismatches_default_quality
  label: Mismatches default quality
  doc: Default quality for the base mismatches covariate.
  type: int?
  inputBinding:
    prefix: --mismatches-default-quality
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '-1'
- id: platform_filter_name
  label: Platform filter name
  doc: |-
    Valid only if "PlatformReadFilter" is specified:
    Platform attribute (PL) to match. This argument must be specified at least once. Required.
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          if (inputs.platform_filter_name)
          {
              var pfn = [].concat(inputs.platform_filter_name);
              var cmd = [];
              for (var i = 0; i < pfn.length; i++) 
              {
                  cmd.push('--platform-filter-name', pfn[i]);
              }
              return cmd.join(' ');
          }
          return '';
      }
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
- id: preserve_qscores_less_than
  label: Preserve qscores less than
  doc: |-
    Don't recalibrate bases with quality scores less than this threshold (with -bqsr).
  type: int?
  inputBinding:
    prefix: --preserve-qscores-less-than
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '6'
- id: quantizing_levels
  label: Quantizing levels
  doc: Number of distinct quality scores in the quantized output.
  type: int?
  inputBinding:
    prefix: --quantizing-levels
    position: 4
    shellQuote: false
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '16'
- id: read_filter
  label: Read filter
  doc: |-
    Read filters to be applied before analysis. This argument may be specified 0 or more times.
  type:
  - 'null'
  - type: array
    items:
      name: read_filter
      type: enum
      symbols:
      - AlignmentAgreesWithHeaderReadFilter
      - AllowAllReadsReadFilter
      - AmbiguousBaseReadFilter
      - CigarContainsNoNOperator
      - FirstOfPairReadFilter
      - FragmentLengthReadFilter
      - GoodCigarReadFilter
      - HasReadGroupReadFilter
      - LibraryReadFilter
      - MappedReadFilter
      - MappingQualityAvailableReadFilter
      - MappingQualityNotZeroReadFilter
      - MappingQualityReadFilter
      - MatchingBasesAndQualsReadFilter
      - MateDifferentStrandReadFilter
      - MateOnSameContigOrNoMappedMateReadFilter
      - MetricsReadFilter
      - NonChimericOriginalAlignmentReadFilter
      - NonZeroFragmentLengthReadFilter
      - NonZeroReferenceLengthAlignmentReadFilter
      - NotDuplicateReadFilter
      - NotOpticalDuplicateReadFilter
      - NotSecondaryAlignmentReadFilter
      - NotSupplementaryAlignmentReadFilter
      - OverclippedReadFilter
      - PairedReadFilter
      - PassesVendorQualityCheckReadFilter
      - PlatformReadFilter
      - PlatformUnitReadFilter
      - PrimaryLineReadFilter
      - ProperlyPairedReadFilter
      - ReadGroupBlackListReadFilter
      - ReadGroupReadFilter
      - ReadLengthEqualsCigarLengthReadFilter
      - ReadLengthReadFilter
      - ReadNameReadFilter
      - ReadStrandFilter
      - SampleReadFilter
      - SecondOfPairReadFilter
      - SeqIsStoredReadFilter
      - ValidAlignmentEndReadFilter
      - ValidAlignmentStartReadFilter
      - WellformedReadFilter
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
                  cmd.push('--read-filter', self[i]);
              }
              return cmd.join(' ');
          }
          
      }
    shellQuote: false
  sbg:altPrefix: -RF
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'null'
- id: read_group_black_list
  label: Read group black list
  doc: |-
    Valid only if "ReadGroupBlackListReadFilter" is specified:
    The name of the read group to filter out. This argument must be specified at least once. Required.
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          if (inputs.read_group_black_list)
          {
              var rgbl = [].concat(inputs.read_group_black_list);
              var cmd = [];
              for (var i = 0; i < rgbl.length; i++) 
              {
                  cmd.push('--read-group-black-list', rgbl[i]);
              }
              return cmd.join(' ');
          }
          return '';
      }
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
- id: read_name
  label: Read name
  doc: |-
    Valid only if "ReadNameReadFilter" is specified:
    Keep only reads with this read name. Required.
  type: string?
  inputBinding:
    prefix: --read-name
    position: 4
    shellQuote: false
  sbg:category: Conditional Arguments for readFilter
- id: read_validation_stringency
  label: Read validation stringency
  doc: |-
    Validation stringency for all SAM/BAM/CRAM/SRA files read by this program. The default stringency value SILENT can improve performance when processing a BAM file in which variable-length data (read, qualities, tags) do not otherwise need to be decoded.
  type:
  - 'null'
  - name: read_validation_stringency
    type: enum
    symbols:
    - STRICT
    - LENIENT
    - SILENT
  inputBinding:
    prefix: --read-validation-stringency
    position: 4
    shellQuote: false
  sbg:altPrefix: -VS
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: SILENT
- id: in_reference
  label: Reference
  doc: Reference sequence file.
  type: File
  secondaryFiles:
  - .fai
  - ^.dict
  inputBinding:
    prefix: --reference
    position: 4
    shellQuote: false
  sbg:altPrefix: -R
  sbg:category: Required Arguments
  sbg:fileTypes: FASTA, FA
- id: sample
  label: Sample
  doc: |-
    Valid only if "SampleReadFilter" is specified:
    The name of the sample(s) to keep, filtering out all others. This argument must be specified at least once. Required.
  type: string[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          if (inputs.sample)
          {
              var samp = [].concat(inputs.sample);
              var cmd = [];
              for (var i = 0; i < samp.length; i++) 
              {
                  cmd.push('--sample', samp[i]);
              }
              return cmd.join(' ');
          }
          return '';
      }
    shellQuote: false
  sbg:altPrefix: -sample
  sbg:category: Conditional Arguments for readFilter
- id: sequence_dictionary
  label: Sequence dictionary
  doc: |-
    Use the given sequence dictionary as the master/canonical sequence dictionary. Must be a .dict file.
  type: File?
  inputBinding:
    prefix: --sequence-dictionary
    position: 4
    shellQuote: false
  sbg:altPrefix: -sequence-dictionary
  sbg:category: Optional Arguments
  sbg:fileTypes: DICT
  sbg:toolDefaultValue: '10.0'
- id: use_original_qualities
  label: Use original qualities
  doc: Use the base quality scores from the OQ tag.
  type: boolean?
  inputBinding:
    prefix: --use-original-qualities
    position: 4
    shellQuote: false
  sbg:altPrefix: -OQ
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: prefix
  label: Output name prefix
  doc: Output file name prefix.
  type: string?
  sbg:category: Config Inputs
- id: cpu_per_job
  label: CPU per job
  doc: CPU per job.
  type: int?
  sbg:category: Platform Options
  sbg:toolDefaultValue: '1'
- id: disable_bam_index_caching
  label: Disable BAM index caching
  doc: |-
    If true, don't cache BAM indexes, this will reduce memory requirements but may harm performance if many intervals are specified. Caching is automatically disabled if there are no intervals specified.
  type: boolean?
  inputBinding:
    prefix: --disable-bam-index-caching
    position: 4
    shellQuote: false
  sbg:altPrefix: -DBIC
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: 'false'
- id: seconds_between_progress_updates
  label: Seconds between progress updates
  doc: Output traversal statistics every time this many seconds elapse.
  type: float?
  inputBinding:
    prefix: --seconds-between-progress-updates
    position: 4
    shellQuote: false
  sbg:altPrefix: -seconds-between-progress-updates
  sbg:category: Optional Arguments
  sbg:toolDefaultValue: '10.00'
- id: read_index
  label: Read index
  doc: |-
    Indices to use for the read inputs. If specified, an index must be provided for every read input and in the same order as the read inputs. If this argument is not specified, the path to the index for each input will be inferred automatically. This argument may be specified 0 or more times.
  type: File[]?
  inputBinding:
    position: 4
    valueFrom: |-
      ${
          if (inputs.read_index)
          {
              var r_index = [].concat(inputs.read_index);
              var cmd = [];
              for (var i = 0; i < r_index.length; i++) 
              {
                  cmd.push('--read-index', r_index[i].path);
              }
              return cmd.join(' ');
          }
          return '';
      }
    shellQuote: false
  sbg:altPrefix: -read-index
  sbg:category: Optional Arguments
  sbg:fileTypes: BAI, CRAI

outputs:
- id: out_bqsr_report
  label: Output recalibration report
  doc: The output recalibration table file to create.
  type: File?
  outputBinding:
    glob: '*.csv'
    outputEval: $(inheritMetadata(self, inputs.in_alignments))
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
  valueFrom: BaseRecalibrator
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
        var in_num = [].concat(inputs.in_alignments).length;
        var in_align = [].concat(inputs.in_alignments);
        
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
                if(in_align[0].metadata && in_align[0].metadata.sample_id) {
                    output_prefix = in_align[0].metadata.sample_id;
                // if sample_id is not defined
                } else {
                    output_prefix = in_align[0].path.split('/').pop().split('.')[0];
                }
            }
            //if there are more than 1 input files
            //sort list of input file objects alphabetically by file name 
            //take the first element from that list, and generate output file name as if that file is the only file on the input. 
            else if(in_num > 1) {
                //sort list of input files by nameroot
                in_align.sort(sortNameroot);
                //take the first alphabetically sorted file
                var first_file = in_align[0];
                //check if the sample_id metadata value is defined for the input file
                if(first_file.metadata && first_file.metadata.sample_id) {
                    output_prefix = first_file.metadata.sample_id + '.' + in_num;
                // if sample_id is not defined
                } else {
                    output_prefix = first_file.path.split('/').pop().split('.')[0] + '.' + in_num;
                }
            }
        }
        var output_full = output_prefix + '.recal_data.csv';
        return output_full;
    }
  shellQuote: false
id: h-d53fb045/h-0bc61d63/h-f4b31a36/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BAM Processing
- CWL1.0
sbg:content_hash: af89c0ecbd011d6f1e94510e1c0947c9cce2b6d5d05713be641ff8cbc7de1d6af
sbg:contributors:
- nens
- veliborka_josipovic
- uros_sipetic
- marijeta_slavkovic
sbg:createdBy: uros_sipetic
sbg:createdOn: 1552922094
sbg:id: h-d53fb045/h-0bc61d63/h-f4b31a36/0
sbg:image_url:
sbg:latestRevision: 22
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
- id: https://gatk.broadinstitute.org/hc/en-us/articles/360036726891-BaseRecalibrator
  label: Documentation
sbg:modifiedBy: marijeta_slavkovic
sbg:modifiedOn: 1603296363
sbg:project: uros_sipetic/gatk-4-1-0-0-demo
sbg:projectName: GATK 4.1.0.0 - Demo
sbg:publisher: sbg
sbg:revision: 22
sbg:revisionNotes: |-
  secondary files known_sites (return basename.idx instead of '' when not VCF or VCF.GZ), small description
sbg:revisionsInfo:
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1552922094
  sbg:revision: 0
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/11
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1554492924
  sbg:revision: 1
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/14
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1554492998
  sbg:revision: 2
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/15
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1554720866
  sbg:revision: 3
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/17
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1554999207
  sbg:revision: 4
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/18
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1556030757
  sbg:revision: 5
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/19
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557735256
  sbg:revision: 6
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/20
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000594
  sbg:revision: 7
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/21
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351546
  sbg:revision: 8
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/23
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558450805
  sbg:revision: 9
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/24
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558517350
  sbg:revision: 10
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/25
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558518057
  sbg:revision: 11
  sbg:revisionNotes: |-
    Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/gatk-baserecalibrator-4-1-0-0/26
- sbg:modifiedBy: veliborka_josipovic
  sbg:modifiedOn: 1571321280
  sbg:revision: 12
  sbg:revisionNotes: known_snps null handled
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1593698771
  sbg:revision: 13
  sbg:revisionNotes: New wrapper
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1593699523
  sbg:revision: 14
  sbg:revisionNotes: Description review suggestions added
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1593699583
  sbg:revision: 15
  sbg:revisionNotes: Description review suggestions added
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1594047999
  sbg:revision: 16
  sbg:revisionNotes: naming description and benchmarking price review
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1594725435
  sbg:revision: 17
  sbg:revisionNotes: added CRAM and SAM to suggested types for in_alignments
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1594725563
  sbg:revision: 18
  sbg:revisionNotes: removed SAM as file suggestion
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1597669945
  sbg:revision: 19
  sbg:revisionNotes: changed default mem_per_job to 2048
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1598131454
  sbg:revision: 20
  sbg:revisionNotes: added [].concat to arrays
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1603199349
  sbg:revision: 21
  sbg:revisionNotes: description edited (usage example Xmx, memory in description
    etc)
- sbg:modifiedBy: marijeta_slavkovic
  sbg:modifiedOn: 1603296363
  sbg:revision: 22
  sbg:revisionNotes: |-
    secondary files known_sites (return basename.idx instead of '' when not VCF or VCF.GZ), small description
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.0.0
sbg:validationErrors: []
