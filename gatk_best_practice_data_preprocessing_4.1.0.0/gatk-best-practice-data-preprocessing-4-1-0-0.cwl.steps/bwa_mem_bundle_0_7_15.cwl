cwlVersion: v1.0
class: CommandLineTool
label: BWA MEM Bundle 0.7.15 CWL1.0
doc: |-
  BWA-MEM is an algorithm designed for aligning sequence reads onto a large reference genome. BWA-MEM is implemented as a component of BWA. The algorithm can automatically choose between performing end-to-end and local alignments. BWA-MEM is capable of outputting multiple alignments, and finding chimeric reads. It can be applied to a wide range of read lengths, from 70 bp to several megabases. 

  *A list of **all inputs and parameters** with corresponding descriptions can be found at the bottom of the page.*


  ## Common Use Cases
  In order to obtain possibilities for additional fast processing of aligned reads, **Biobambam2 sortmadup** (2.0.87) tool is embedded together into the same package with BWA-MEM (0.7.15).

  In order to obtain possibilities for additional fast processing of aligned reads, **Biobambam2** (2.0.87) is embedded together with the BWA 0.7.15 toolkit into the **BWA-MEM Bundle 0.7.15 CWL1.0**.  Two tools are used (**bamsort** and **bamsormadup**) to allow the selection of three output formats (SAM, BAM, or CRAM), different modes of sorting (Quarryname/Coordinate sorting), and Marking/Removing duplicates that can arise during sample preparation e.g. library construction using PCR. This is done by setting the **Output format** and **PCR duplicate detection** parameters.
  - Additional notes:
      - The default **Output format** is coordinate sorted BAM (option **BAM**).
      - SAM and BAM options are query name sorted, while CRAM format is not advisable for data sorted by query name.
      - Coordinate Sorted BAM file in all options and CRAM Coordinate sorted output with Marked Duplicates come with the accompanying index file. The generated index name will be the same as the output alignments file, with the extension BAM.BAI or CRAM.CRAI. However, when selecting the CRAM Coordinate sorted and CRAM Coordinate sorted output with Removed Duplicates, the generated files will not have the index file generated. This is a result of the usage of different Biobambam2 tools - **bamsort** does not have the ability to write CRAI files (only supports outputting BAI index files), while **bamsormadup** can write CRAI files.
      - Passing data from BWA-MEM to Biobambam2 tools has been done through the Linux piping which saves processing times (up to an hour of the execution time for whole-genome sample) of reading and writing of aligned reads into the hard drive. 
      - **BWA-MEM Bundle 0.7.15 CWL1** first needs to construct the FM-index  (Full-text index in Minute space) for the reference genome using the **BWA INDEX 0.7.17 CWL1.0** tool. The two BWA versions are compatible.

  ### Changes Introduced by Seven Bridges

  - **Aligned SAM/BAM/CRAM** file will be prefixed using the **Output SAM/BAM/CRAM file name** parameter. In case **Output SAM/BAM/CRAM file name** is not provided, the output prefix will be the same as the **Sample ID** metadata field from the file if the **Sample ID** metadata field exists. Otherwise, the output prefix will be inferred from the **Input reads** file names.
  -  The **Platform** metadata field for the output alignments will be automatically set to "Illumina" unless it is present in **Input reads** metadata, or given through **Read group header** or **Platform** input parameters. This will prevent possible errors in downstream analysis using the GATK toolkit.
  - If the **Read group ID** parameter is not defined, by default it will be set to ‘1’. If the tool is scattered within a workflow it will assign the **Read Group ID** according to the order of the scattered folders. This ensures a unique **Read Group ID** when processing multi-read group input data from one sample.

  ### Common Issues and Important Notes 
   
  - For input reads FASTQ files of total size less than 10 GB we suggest using the default setting for parameter **Total memory** of 15GB, for larger files we suggest using 58 GB of memory and 32 CPU cores.
  - When the desired output is a CRAM file without deduplication of the PCR duplicates, it is necessary to provide the FASTA Index file (FAI) as input.
  - Human reference genome version 38 comes with ALT contigs, a collection of diverged alleles present in some humans but not the others. Making effective use of these contigs will help to reduce mapping artifacts, however, to facilitate mapping these ALT contigs to the primary assembly, GRC decided to add to each contig long flanking sequences almost identical to the primary assembly. As a result, a naive mapping against GRCh38+ALT will lead to many mapQ-zero mappings in these flanking regions. Please use post-processing steps to fix these alignments or implement [steps](https://sourceforge.net/p/bio-bwa/mailman/message/32845712/) described by the author of the BWA toolkit.  
  - Inputs **Read group header** and **Insert string to header** need to be given in the correct format - under single-quotes.
  - BWA-MEM is not a splice aware aligner, so it is not the appropriate tool for mapping RNAseq to the genome. For RNAseq reads **Bowtie2 Aligner** and **STAR** are recommended tools. 
  - Input paired reads need to have the identical read names - if not, the tool will throw a ``[mem_sam_pe] paired reads have different names`` error.
  - This wrapper was tested and is fully compatible with cwltool v3.0.

  ### Performance Benchmarking

  Below is a table describing the runtimes and task costs on on-demand instances for a set of samples with different file sizes :

  | Input reads       | Size [GB] | Output format | Instance (AWS)           | Duration  | Cost   | Threads |
  |-------------------|-----------|---------------|--------------------------|-----------|--------|---------|
  | HG001-NA12878-30x | 2 x 23.8  | SAM           | c5.9xlarge (36CPU, 72GB) | 5h 12min  | $7.82  | 36      |
  | HG001-NA12878-30x | 2 x 23.8  | BAM           | c5.9xlarge (36CPU, 72GB) | 5h 16min  | $8.06  | 36      |
  | HG002-NA24385-50x | 2 x 66.4  | SAM           | c5.9xlarge (36CPU, 72GB) | 8h 33min  | $13.08 | 36      |


  *Cost can be significantly reduced by using **spot instances**. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: |-
    ${
        var reads_size = 0
        // Calculate suggested number of CPUs depending of the input reads size
        if (inputs.input_reads.constructor == Array) {
            if (inputs.input_reads[1]) reads_size = inputs.input_reads[0].size + inputs.input_reads[1].size;
            else reads_size = inputs.input_reads[0].size;
        } else reads_size = inputs.input_reads.size;
        
        if (!reads_size) reads_size = 0;
        
        var GB_1 = 1024 * 1024 * 1024;
        var suggested_cpus = 0;
        if (reads_size < GB_1) suggested_cpus = 1;
        else if (reads_size < 10 * GB_1) suggested_cpus = 8;
        else suggested_cpus = 31;
        
        if (inputs.reserved_threads) return inputs.reserved_threads;
        else if (inputs.threads) return inputs.threads;
        else if (inputs.sambamba_threads) return inputs.sambamba_threads;
        else return suggested_cpus;
        
    }
  ramMin: |-
    ${
        var reads_size =0;
        // Calculate suggested number of CPUs depending of the input reads size
        if (inputs.input_reads.constructor == Array) {
            if (inputs.input_reads[1]) reads_size = inputs.input_reads[0].size + inputs.input_reads[1].size;
            else reads_size = inputs.input_reads[0].size;
        } else reads_size = inputs.input_reads.size;
        if (!reads_size) reads_size = 0;

        var GB_1 = 1024 * 1024 * 1024;
        var  suggested_memory = 0;
        if (reads_size < GB_1) suggested_memory = 4;
        else if (reads_size < 10 * GB_1) suggested_memory = 15;
        else suggested_memory = 58;
        
        if (inputs.total_memory) return inputs.total_memory * 1024;
        else if (inputs.sort_memory) return inputs.sort_memory * 1024;
        else return suggested_memory * 1024;
        
    }
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/nens/bwa-0-7-15:0
- class: InitialWorkDirRequirement
  listing:
  - $(inputs.reference_index_tar)
  - $(inputs.input_reads)
  - $(inputs.fasta_index)
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

inputs:
- id: drop_chains_fraction
  label: Drop chains fraction
  doc: |-
    Drop chains shorter than a given fraction (FLOAT) of the longest overlapping chain.
  type: float?
  inputBinding:
    prefix: -D
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '0.50'
- id: verbose_level
  label: Verbose level
  doc: 'Select verbose level: 1=error, 2=warning, 3=message, 4+=debugging.'
  type:
  - 'null'
  - name: verbose_level
    type: enum
    symbols:
    - '1'
    - '2'
    - '3'
    - '4'
  inputBinding:
    prefix: -v
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
  sbg:toolDefaultValue: '3'
- id: sort_memory
  label: Memory for BAM sorting
  doc: |-
    Amount of RAM [Gb] to give to the sorting algorithm (if not provided will be set to one-third of the total memory).
  type: int?
  sbg:category: Execution
- id: wgs_hg38_mode_threads
  label: Optimize threads for HG38
  doc: Lower the number of threads if HG38 reference genome is used.
  type: int?
  sbg:category: Execution
  sbg:toolDefaultValue: 'False'
- id: band_width
  label: Band width
  doc: Band width for banded alignment.
  type: int?
  inputBinding:
    prefix: -w
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '100'
- id: smart_pairing_in_input_fastq
  label: Smart pairing in input FASTQ file
  doc: Smart pairing in input FASTQ file (ignoring in2.fq).
  type: boolean?
  inputBinding:
    prefix: -p
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: rg_library_id
  label: Library ID
  doc: |-
    Specify the identifier for the sequencing library preparation, which will be placed in RG line.
  type: string?
  sbg:category: BWA Read Group Options
  sbg:toolDefaultValue: Inferred from metadata
- id: mate_rescue_rounds
  label: Mate rescue rounds
  doc: |-
    Perform at the most a given number (INT) of rounds of mate rescues for each read.
  type: string?
  inputBinding:
    prefix: -m
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '50'
- id: reserved_threads
  label: Reserved number of threads on the instance
  doc: Reserved number of threads on the instance used by scheduler.
  type: int?
  sbg:category: Configuration
  sbg:toolDefaultValue: '1'
- id: input_reads
  label: Input reads
  doc: Input sequence reads.
  type: File[]
  inputBinding:
    position: 105
    valueFrom: |-
      ${
          /// Set input reads in the correct order depending of the paired end from metadata

          // Set output file name
          function flatten(files){
              var a = [];
              for(var i=0;i<files.length;i++){
                  if(files[i]){
                      if(files[i].constructor == Array) a = a.concat(flatten(files[i]));
                      else a = a.concat(files[i]);}}
              var b = a.filter(function (el) {return el != null;})
              return b;}
          var files1 = [].concat(inputs.input_reads);
          var in_reads=flatten(files1);

          // Read metadata for input reads
          var read_metadata = in_reads[0].metadata;
          if (!read_metadata) read_metadata = [];

          var order = 0; // Consider this as normal order given at input: pe1 pe2

          // Check if paired end 1 corresponds to the first given read
          if (read_metadata == []) order = 0;
          else if ('paired_end' in read_metadata) {
              var pe1 = read_metadata.paired_end;
              if (pe1 != 1) order = 1; // change order
          }

          // Return reads in the correct order
          if (in_reads.length == 1) return in_reads[0].path; // Only one read present
          else if (in_reads.length == 2) {
              if (order == 0) return in_reads[0].path + ' ' + in_reads[1].path;
              else return in_reads[1].path + ' ' + in_reads[0].path;
          }
      }
    shellQuote: false
  sbg:category: Input files
  sbg:fileTypes: FASTQ, FASTQ.GZ, FQ, FQ.GZ
- id: unpaired_read_penalty
  label: Unpaired read penalty
  doc: Penalty for an unpaired read pair.
  type: int?
  inputBinding:
    prefix: -U
    position: 4
    shellQuote: false
  sbg:category: BWA Scoring options
  sbg:toolDefaultValue: '17'
- id: clipping_penalty
  label: Clipping penalty
  doc: Penalty for 5'- and 3'-end clipping.
  type: int[]?
  inputBinding:
    prefix: -L
    position: 4
    separate: false
    itemSeparator: ','
    shellQuote: false
  sbg:category: BWA Scoring options
  sbg:toolDefaultValue: '[5,5]'
- id: select_seeds
  label: Select seeds
  doc: Look for internal seeds inside a seed longer than {-k} * FLOAT.
  type: float?
  inputBinding:
    prefix: -r
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '1.5'
- id: score_for_a_sequence_match
  label: Score for a sequence match
  doc: Score for a sequence match, which scales options -TdBOELU unless overridden.
  type: int?
  inputBinding:
    prefix: -A
    position: 4
    shellQuote: false
  sbg:category: BWA Scoring options
  sbg:toolDefaultValue: '1'
- id: dropoff
  label: Dropoff
  doc: Off-diagonal X-dropoff.
  type: int?
  inputBinding:
    prefix: -d
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '100'
- id: num_input_bases_in_each_batch
  label: Number of input bases to process
  doc: |-
    Process a given number (INT) of input bases in each batch regardless of nThreads (for reproducibility).
  type: int?
  inputBinding:
    prefix: -K
    position: 4
    shellQuote: false
- id: total_memory
  label: Total memory
  doc: |-
    Total memory to be used by the tool in GB. It's the sum of BWA and BIOBAMBAM2 processes. For FASTQ files of a total size less than 10GB, we suggest using the default setting of 15GB, for larger files, we suggest using 58GB of memory (and 32CPU cores).
  type: int?
  sbg:category: Execution
  sbg:toolDefaultValue: '15'
- id: gap_extension_penalties
  label: Gap extension
  doc: |-
    Gap extension penalty; a gap of size k cost '{-O} + {-E}*k'. 
    This array can't have more than two values.
  type: int[]?
  inputBinding:
    prefix: -E
    position: 4
    separate: false
    itemSeparator: ','
    shellQuote: false
  sbg:category: BWA Scoring options
  sbg:toolDefaultValue: '[1,1]'
- id: deduplication
  label: PCR duplicate detection
  doc: Use Biobambam2 for finding duplicates on sequence reads.
  type:
  - 'null'
  - name: deduplication
    type: enum
    symbols:
    - None
    - MarkDuplicates
    - RemoveDuplicates
  sbg:category: Biobambam2 parameters
  sbg:toolDefaultValue: MarkDuplicates
- id: ignore_alt_file
  label: Ignore ALT file
  doc: |-
    Treat ALT contigs as part of the primary assembly (i.e. ignore <idxbase>.alt file).
  type: boolean?
  inputBinding:
    prefix: -j
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: rg_id
  label: Read group ID
  doc: Set read group ID.
  type: string?
  sbg:category: Configuration
  sbg:toolDefaultValue: '1'
- id: use_soft_clipping
  label: Use soft clipping
  doc: Use soft clipping for supplementary alignments.
  type: boolean?
  inputBinding:
    prefix: -Y
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: output_in_xa
  label: Output in XA
  doc: |-
    If there are < number (INT) of hits with a score >80% of the max score, output all in XA. 
    This array should have no more than two values.
  type: int[]?
  inputBinding:
    prefix: -h
    position: 4
    separate: false
    itemSeparator: ','
    shellQuote: false
  sbg:category: BWA Input/output options
  sbg:toolDefaultValue: '[5, 200]'
- id: rg_platform
  label: Platform
  doc: |-
    Specify the version of the technology that was used for sequencing, which will be placed in RG line.
  type:
  - 'null'
  - name: rg_platform
    type: enum
    symbols:
    - '454'
    - Helicos
    - Illumina
    - Solid
    - IonTorrent
  sbg:category: BWA Read Group Options
  sbg:toolDefaultValue: Inferred from metadata
- id: threads
  label: Threads
  doc: |-
    The number of threads for BWA and Biobambam2 sort processes (both will use the given number).
  type: int?
  sbg:category: Execution
  sbg:toolDefaultValue: '8'
- id: skip_pairing
  label: Skip pairing
  doc: Skip pairing; mate rescue performed unless -S also in use.
  type: boolean?
  inputBinding:
    prefix: -P
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
- id: insert_string_to_header
  label: Insert string to header
  doc: Insert STR to output header if it starts with "@".
  type: string?
  inputBinding:
    prefix: -H
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: output_header
  label: Output header
  doc: Output the reference FASTA header in the XR tag.
  type: boolean?
  inputBinding:
    prefix: -V
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: seed_occurrence_for_the_3rd_round
  label: Seed occurrence
  doc: Seed occurrence for the 3rd round seeding.
  type: int?
  inputBinding:
    prefix: -y
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '20'
- id: read_type
  label: Sequencing technology-specific settings
  doc: |-
    Sequencing technology-specific settings; Setting -x changes multiple parameters unless overridden. 
    pacbio: -k17 -W40 -r10 -A1 -B1 -O1 -E1 -L0  (PacBio reads to ref). 
    ont2d: -k14 -W20 -r10 -A1 -B1 -O1 -E1 -L0  (Oxford Nanopore 2D-reads to ref).
    intractg: -B9 -O16 -L5  (intra-species contigs to ref).
  type:
  - 'null'
  - name: read_type
    type: enum
    symbols:
    - pacbio
    - ont2d
    - intractg
  inputBinding:
    prefix: -x
    position: 4
    shellQuote: false
  sbg:category: BWA Scoring options
- id: reference_index_tar
  label: Reference Index TAR
  doc: Reference fasta file with its BWA index files packed in a TAR archive.
  type: File
  sbg:category: Input files
  sbg:fileTypes: TAR
- id: mark_shorter
  label: Mark shorter
  doc: Mark shorter split hits as secondary.
  type: boolean?
  inputBinding:
    prefix: -M
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: speficy_distribution_parameters
  label: Specify distribution parameters
  doc: |-
    Specify the mean, standard deviation (10% of the mean if absent), max (4 sigma from the mean if absent), and min of the insert size distribution. 
    FR orientation only. 
    This array can have maximum of four values, where the first two should be specified as FLOAT and the last two as INT.
  type: float[]?
  inputBinding:
    prefix: -I
    position: 4
    valueFrom: |-
      ${
          var out = "";
          for (var i = 0; i < [].concat(self).length; i++ ){
              out += " -I" + [].concat(self)[i];
          }    
          return out
      }
    separate: false
    itemSeparator: ' -I'
    shellQuote: false
  sbg:category: BWA Input/output options
- id: minimum_output_score
  label: Minimum alignment score for a read to be output in SAM/BAM
  doc: Minimum alignment score for a read to be output in SAM/BAM.
  type: int?
  inputBinding:
    prefix: -T
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
  sbg:toolDefaultValue: '30'
- id: output_format
  label: Output format
  doc: Coordinate sorted BAM file (option BAM) is the default output.
  type:
  - 'null'
  - name: output_format
    type: enum
    symbols:
    - SAM
    - BAM
    - CRAM
    - Queryname Sorted BAM
    - Queryname Sorted SAM
  sbg:category: Execution
  sbg:toolDefaultValue: Coordinate Sorted BAM
- id: skip_mate_rescue
  label: Skip mate rescue
  doc: Skip mate rescue.
  type: boolean?
  inputBinding:
    prefix: -S
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
- id: skip_seeds
  label: Skip seeds
  doc: Skip seeds with more than a given number (INT) of occurrences.
  type: int?
  inputBinding:
    prefix: -c
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '500'
- id: output_name
  label: Output alignements file name
  doc: Name for the output alignments (SAM, BAM, or CRAM) file.
  type: string?
  sbg:category: Configuration
- id: minimum_seed_length
  label: Minimum seed length
  doc: Minimum seed length for BWA MEM.
  type: int?
  inputBinding:
    prefix: -k
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '19'
- id: gap_open_penalties
  label: Gap open penalties
  doc: |-
    Gap open penalties for deletions and insertions. 
    This array can't have more than two values.
  type: int[]?
  inputBinding:
    prefix: -O
    position: 4
    separate: false
    itemSeparator: ','
    shellQuote: false
  sbg:category: BWA Scoring options
  sbg:toolDefaultValue: '[6,6]'
- id: rg_median_fragment_length
  label: Median fragment length
  doc: Specify the median fragment length for RG line.
  type: string?
  sbg:category: BWA Read Group Options
- id: mismatch_penalty
  label: Mismatch penalty
  doc: Penalty for a mismatch.
  type: int?
  inputBinding:
    prefix: -B
    position: 4
    shellQuote: false
  sbg:category: BWA Scoring options
  sbg:toolDefaultValue: '4'
- id: output_alignments
  label: Output alignments
  doc: Output all alignments for SE or unpaired PE.
  type: boolean?
  inputBinding:
    prefix: -a
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: discard_exact_matches
  label: Discard exact matches
  doc: Discard full-length exact matches.
  type: boolean?
  inputBinding:
    prefix: -e
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
- id: rg_platform_unit_id
  label: Platform unit ID
  doc: |-
    Specify the platform unit (lane/slide) for RG line - An identifier for lanes (Illumina), or for slides (SOLiD) in the case that a library was split and ran over multiple lanes on the flow cell or slides.
  type: string?
  sbg:category: BWA Read Group Options
  sbg:toolDefaultValue: Inferred from metadata
- id: mapQ_of_suplementary
  label: Don't modify mapQ
  doc: Don't modify mapQ of supplementary alignments.
  type: boolean?
  inputBinding:
    prefix: -q
    position: 4
    shellQuote: false
- id: rg_sample_id
  label: Sample ID
  doc: |-
    Specify the sample ID for RG line - A human readable identifier for a sample or specimen, which could contain some metadata information. A sample or specimen is material taken from a biological entity for testing, diagnosis, propagation, treatment, or research purposes, including but not limited to tissues, body fluids, cells, organs, embryos, body excretory products, etc.
  type: string?
  sbg:category: BWA Read Group Options
  sbg:toolDefaultValue: Inferred from metadata
- id: rg_data_submitting_center
  label: Data submitting center
  doc: Specify the data submitting center for RG line.
  type: string?
  sbg:category: BWA Read Group Options
- id: discard_chain_length
  label: Discard chain length
  doc: Discard a chain if seeded bases are shorter than a given number (INT).
  type: int?
  inputBinding:
    prefix: -W
    position: 4
    shellQuote: false
  sbg:category: BWA Algorithm options
  sbg:toolDefaultValue: '0'
- id: split_alignment_primary
  label: Split alignment - smallest coordinate as primary
  doc: for split alignment, take the alignment with the smallest coordinate as primary.
  type: boolean?
  inputBinding:
    prefix: '-5'
    position: 4
    shellQuote: false
- id: append_comment
  label: Append comment
  doc: Append FASTA/FASTQ comment to the output file.
  type: boolean?
  inputBinding:
    prefix: -C
    position: 4
    shellQuote: false
  sbg:category: BWA Input/output options
- id: read_group_header
  label: Read group header
  doc: |-
    Read group header line such as '@RG\tID:foo\tSM:bar'.  This value takes precedence over per-attribute parameters.
  type: string?
  sbg:category: BWA Read Group Options
  sbg:toolDefaultValue: Constructed from per-attribute parameters or inferred from
    metadata.
- id: ignore_default_rg_id
  label: Ignore default RG ID
  doc: Ignore default RG ID ('1').
  type: boolean?
  sbg:category: BWA Read Group Options
- id: fasta_index
  label: Fasta Index file for CRAM output
  doc: |-
    Fasta index file is required for CRAM output when no PCR Deduplication is selected.
  type: File?
  inputBinding:
    position: 4
    valueFrom: "${\n    return \"\";\n}"
    shellQuote: false
  sbg:category: Input files
  sbg:fileTypes: FAI

outputs:
- id: aligned_reads
  label: Aligned SAM/BAM
  doc: Aligned reads.
  type: File?
  secondaryFiles:
  - .bai
  - ^.bai
  - .crai
  - ^.crai
  outputBinding:
    glob: "${ \n    return [\"*.sam\", \"*.bam\", \"*.cram\"] \n}"
    outputEval: |-
      ${  
          /// Set metadata from input parameters, metadata or default value

          function flatten(files){
              var a = []
              for(var i=0;i<files.length;i++){
                  if(files[i]){
                      if(files[i].constructor == Array) a = a.concat(flatten(files[i]));
                      else a = a.concat(files[i]);}}
              var b = a.filter(function (el) {return el != null});
              return b;
          }
          function sharedStart(array){
              var A= array.concat().sort(), 
              a1= A[0], a2= A[A.length-1], L= a1.length, i= 0;
              while(i<L && a1.charAt(i)=== a2.charAt(i)) i++;
              return a1.substring(0, i);
          }
          /// Key-setting functions
          // Reference genome 
          var add_metadata_key_reference_genome = function(self, inputs) {
              var reference_file = inputs.reference_index_tar.basename;
              var ref_list = reference_file.split('.');
              var  a = '';
              a = ref_list.pop();
              a = ref_list.pop();
              a = ref_list.pop();
              a = ref_list.pop(); // strip '.bwa-mem2-2.1-index-archive.tar'
              return ref_list.join('.');
          };
          // Platform 
          var add_metadata_key_platform = function(self, inputs) {
              /// Set platform from input parameters/input metadata/default value
              var platform = '';
              var pl = '';
              // Find PL from header
              if (inputs.read_group_header){
                  var header = inputs.read_group_header;
                  header = header.split("'").join("") //remove single quotes
                  var a = header.split('\\t');
                  for (var i = 0; i < a.length; i++){ //find PL field
                      if (a[i].includes("PL:")) pl= a[i];
                      else;
                  }}
              else;
              
              if (pl) platform = pl.split(':')[1];
              else if (inputs.rg_platform) platform = inputs.rg_platform;
              else if (read_metadata.platform) platform = read_metadata.platform;
              else platform = 'Illumina';
              
              return platform
          };
          // Sample ID 
          var add_metadata_key_sample_id = function(self, inputs) {
              /// Set sample ID from input parameters/input metadata/default value from input reads file names
              var sample_id = '';
              var sm = '';
              // Find SM from header
              if (inputs.read_group_header){
                  var header = inputs.read_group_header;
                  header = header.split("'").join("") //remove single quotes
                  var a = header.split('\\t');
                  for (var i = 0; i < a.length; i++){ //find SM field
                      if (a[i].includes("SM:")) var sm= a[i];
                      else;
                  }}
              else;
              
              if (sm) sample_id = sm.split(':')[1];
              else if (inputs.rg_sample_id) sample_id = inputs.rg_sample_id;
              else if (read_metadata.sample_id) sample_id = read_metadata.sample_id;
              else {
                  var read_names = [];
                  var files1 = [].concat(inputs.input_reads);
                  var files=flatten(files1);
                  
                  for (var i=0;i<files.length;i++) {
                      var file_ext=files[i].nameext;
                      var file_base=files[i].basename;
                      
                      if (file_ext === '.gz' || file_ext === '.GZ')
                          file_base = file_base.slice(0, -3);
                          file_ext= '.'+ file_base.split('.').pop();
                      if (file_ext === '.fq' || file_ext === '.FQ')
                          file_base = file_base.slice(0, -3);
                      if (file_ext === '.fastq' || file_ext === '.FASTQ')
                          file_base = file_base.slice(0, -6);
                      
                      read_names.push(file_base.replace(/pe1|pe2|pe\.1|pe\.2|pe\_1|pe\_2|\_pe1|\_pe2|\_pe\.1|\_pe\.2|\_pe\_1|\_pe\_2|\.pe1|\.pe2|\.pe\.1|\.pe\.2|\.pe\_1|\.pe\_2/,''));
                    }
                    ////strip out any trailing dashes/dots/underscores...
                    var unique_prefix = sharedStart(read_names).replace( /\-$|\_$|\.$/, '');
                    var tmp_prefix = unique_prefix.replace( /^\_|\.pe$|\.R$|\_pe$|\_R$/,'');
                    var final_prefix = tmp_prefix.replace( /^_\d(\d)?_/, '' );
                    
                    var fname=final_prefix;
                  sample_id = fname;
              }
              return sample_id
          };
          
         
          var files1 = [].concat(inputs.input_reads);
          var files=flatten(files1);
          var read_metadata = files[0].metadata;
          if (!read_metadata) read_metadata = [];
          
          self = inheritMetadata(self, files);

          for (var i = 0; i < self.length; i++) {
              var out_metadata = {
                  'reference_genome': add_metadata_key_reference_genome(self[i], inputs),
                  'platform': add_metadata_key_platform(self[i], inputs),
                  'sample_id': add_metadata_key_sample_id(self[i], inputs)
              };
              self[i] = setMetadata(self[i], out_metadata);
          }

          return self;

      }
  sbg:fileTypes: SAM, BAM, CRAM
- id: dups_metrics
  label: Sormadup metrics
  doc: Metrics file for biobambam mark duplicates
  type: File?
  outputBinding:
    glob: '*.sormadup_metrics.log'
  sbg:fileTypes: LOG

baseCommand: []
arguments:
- prefix: ''
  position: -1
  valueFrom: |-
    ${
        /// Check number of input FASTQ files ///
        
        function flatten(files){
        var a = []
        for(var i=0;i<files.length;i++){
            if(files[i]){
                if(files[i].constructor == Array) a = a.concat(flatten(files[i]));
                else a = a.concat(files[i])}}
            var b = a.filter(function (el) {return el != null})
            return b
        }
        
        var files1 = [].concat(inputs.input_reads);
        var in_reads=flatten(files1);
        
        if ( in_reads.length > 2 ) return 'ERROR: Number of input FASTQ files needs to be one (if single-end/interleaved file) or two (if paired-end files)';
        else return '';
    }
  shellQuote: false
- prefix: ''
  position: 0
  valueFrom: |-
    ${
        var cmd = "/bin/bash -c \"";
        return cmd + " export REF_CACHE=${PWD} && ";
    }
  shellQuote: false
- prefix: ''
  position: 1
  valueFrom: |-
    ${
        /// Unpack Reference TAR archive ///
        
        var in_index=[].concat(inputs.reference_index_tar)[0];
        var reference_file = in_index.basename;
        return 'tar -tvf ' + reference_file + ' 1>&2 && tar -xf ' + reference_file + ' && ';
        
    }
  shellQuote: false
- prefix: ''
  position: 2
  valueFrom: bwa mem
  shellQuote: false
- prefix: ''
  position: 5
  valueFrom: |-
    ${
        /// Set RG header ///

        function add_param(key, val) {
            if (!val) return;
            param_list.push(key + ':' + val);}
            
        function flatten(files){
            var a = [];
            for(var i=0;i<files.length;i++){
                if(files[i]){
                    if(files[i].constructor == Array) a = a.concat(flatten(files[i]));
                    else a = a.concat(files[i]);}}
            var b = a.filter(function (el) {return el != null;});
            return b;}
            
        function sharedStart(array){
            var A= array.concat().sort(), 
            a1= A[0], a2= A[A.length-1], L= a1.length, i= 0;
            while(i<L && a1.charAt(i)=== a2.charAt(i)) i++;
            return a1.substring(0, i);}

        
        /// If it exists - return input read group header from input parameter
        if (inputs.read_group_header) return '-R ' + inputs.read_group_header;

        // Flatten input reads
        var in_reads1 = [].concat(inputs.input_reads);
        var in_reads = flatten(in_reads1)
        var input_1=in_reads[0];

        var param_list = [];
        //Read metadata for input reads
        var read_metadata = input_1.metadata;
        if (!read_metadata) read_metadata = [];

        // Set CN
        if (inputs.rg_data_submitting_center) add_param('CN', inputs.rg_data_submitting_center);
        else if ('data_submitting_center' in read_metadata) add_param('CN', read_metadata.data_submitting_center);
        else;

        // Set LB
        if (inputs.rg_library_id) add_param('LB', inputs.rg_library_id);
        else if ('library_id' in read_metadata) add_param('LB', read_metadata.library_id);
        else;

        // Set PI
        if (inputs.rg_median_fragment_length) add_param('PI', inputs.rg_median_fragment_length);
        else;

        // Set PL (default Illumina)
        var rg_platform = '';
        if (inputs.rg_platform) add_param('PL', inputs.rg_platform);
        else if ('platform' in read_metadata) {
            if (read_metadata.platform == 'HiSeq X Ten') rg_platform = 'Illumina';
            else rg_platform = read_metadata.platform;
            add_param('PL', rg_platform);}
        else add_param('PL', 'Illumina');

        // Set PU
        if (inputs.rg_platform_unit_id) add_param('PU', inputs.rg_platform_unit_id);
        else if ('platform_unit_id' in read_metadata) add_param('PU', read_metadata.platform_unit_id);
        else;
        
        // Set RG_ID
        var folder = input_1.path.split('/').slice(-2,-1).toString();
        var suffix = "_s";
        
        if (inputs.rg_id) add_param('ID', inputs.rg_id);
        else if (folder.indexOf(suffix, folder.length - suffix.length) !== -1){/// Set unique RG_ID when in scatter mode
            var rg = folder.split("_").slice(-2)[0];
            if (parseInt(rg)) add_param('ID', rg);
            else add_param('ID', 1);}
        else  add_param('ID', 1);

        // Set SM from input/metadata/filename
        if (inputs.rg_sample_id) add_param('SM', inputs.rg_sample_id);
        else if ('sample_id' in read_metadata) add_param('SM', read_metadata.sample_id);
        else {
            var read_names = [];
            for (var i=0;i<in_reads.length;i++) {
                var file_ext=in_reads[i].nameext;
                var file_base=in_reads[i].basename;
                
                if (file_ext === '.gz' || file_ext === '.GZ')
                    file_base = file_base.slice(0, -3);
                    file_ext= '.'+ file_base.split('.').pop();
                if (file_ext === '.fq' || file_ext === '.FQ')
                    file_base = file_base.slice(0, -3);
                if (file_ext === '.fastq' || file_ext === '.FASTQ')
                    file_base = file_base.slice(0, -6);
                
                read_names.push(file_base.replace(/pe1|pe2|pe\.1|pe\.2|pe\_1|pe\_2|\_pe1|\_pe2|\_pe\.1|\_pe\.2|\_pe\_1|\_pe\_2|\.pe1|\.pe2|\.pe\.1|\.pe\.2|\.pe\_1|\.pe\_2/,''));}
              
            ////strip out any trailing dashes/dots/underscores...
            var unique_prefix = sharedStart(read_names).replace( /\-$|\_$|\.$/, '');
            var tmp_prefix = unique_prefix.replace( /^\_|\.pe$|\.R$|\_pe$|\_R$/,'');
            var final_prefix = tmp_prefix.replace( /^_\d(\d)?_/, '' );
          
            var sample_id=final_prefix;
            add_param('SM', sample_id);
        };
        
        if (!inputs.ignore_default_rg_id) {
          return "-R '@RG\\t" + param_list.join('\\t') + "'";
        } else {
          return '';
        }

    }
  shellQuote: false
- prefix: -t
  position: 6
  valueFrom: |-
    ${
        /// Set BWA2 threads ///

        var  MAX_THREADS = 36;
        var  suggested_threads = 8;
        var threads  = 0;
      
        if (inputs.threads) threads = inputs.threads;
        else if (inputs.wgs_hg38_mode_threads) {
            var ref_name = inputs.reference_index_tar.basename;
            if (ref_name.search('38') >= 0) threads = inputs.wgs_hg38_mode_threads;
            else threads = MAX_THREADS;
        } else threads = suggested_threads;
        
        return threads;
    }
  shellQuote: false
- prefix: ''
  position: 14
  valueFrom: |-
    ${
        /// Extract common prefix for Index files ///
        
        var reference_tar = [].concat(inputs.reference_index_tar)[0];
        
        var prefix = "$(tar -tf " + reference_tar.basename + " --wildcards '*.bwt' | rev | cut -c 5- | rev)";
        return prefix;

    }
  shellQuote: false
- prefix: ''
  position: 116
  valueFrom: |-
    ${
        ///  BIOBAMBAM2  ///
          
         // Get shared start and flatten input reads
        function sharedStart(array){
            var A= array.concat().sort(), 
            a1= A[0], a2= A[A.length-1], L= a1.length, i= 0;
            while(i<L && a1.charAt(i)=== a2.charAt(i)) i++;
            return a1.substring(0, i);
        }
        function flatten(files){
            var a = [];
            for(var i=0;i<files.length;i++){
                if(files[i]){
                    if(files[i].constructor == Array) a = a.concat(flatten(files[i]));
                    else a = a.concat(files[i]);}}
            var b = a.filter(function (el) {return el != null;});
            return b;}
       
        var input_reads = [].concat(inputs.input_reads);
        var files=flatten(input_reads);

        // Set output file name
        var fname = '';
        
        /// from given prefix
        if (inputs.output_name) fname = inputs.output_name;
        /// from sample_id metadata
        else if (files[0].metadata && files[0].metadata['sample_id']) fname=files[0].metadata['sample_id'];
        /// from common prefix, and strip out any unnecessary characters
        else {
            var read_names = [];
            for (var i=0;i<files.length;i++) {
                var file_ext=files[i].nameext;
                var file_base=files[i].basename;
                
                if (file_ext === '.gz' || file_ext === '.GZ')
                    file_base = file_base.slice(0, -3);
                    file_ext= '.'+ file_base.split('.').pop();
                if (file_ext === '.fq' || file_ext === '.FQ')
                    file_base = file_base.slice(0, -3);
                if (file_ext === '.fastq' || file_ext === '.FASTQ')
                    file_base = file_base.slice(0, -6);
                
                read_names.push(file_base.replace(/pe1|pe2|pe\.1|pe\.2|pe\_1|pe\_2|\_pe1|\_pe2|\_pe\.1|\_pe\.2|\_pe\_1|\_pe\_2|\.pe1|\.pe2|\.pe\.1|\.pe\.2|\.pe\_1|\.pe\_2/,''));
                  
              }
              ////strip out any trailing dashes/dots/underscores...
              var unique_prefix = sharedStart(read_names).replace( /\-$|\_$|\.$/, '');
              var tmp_prefix = unique_prefix.replace( /^\_|\.pe$|\.R$|\_pe$|\_R$/,'');
              var final_prefix = tmp_prefix.replace( /^_\d(\d)?_/, '' );
              
              fname=final_prefix;}


        // Read number of threads if defined
        var threads = 0;
        var MAX_THREADS = 0;
        var ref_name = '';
        if (inputs.threads) threads = inputs.threads;
        else if (inputs.wgs_hg38_mode_threads) {
            MAX_THREADS = 36;
            ref_name = inputs.reference_index_tar.basename;
            if (ref_name.search('38') >= 0) threads = inputs.wgs_hg38_mode_threads;
            else threads = MAX_THREADS;
            } 
        else threads = 8;

        var tool = '';
        var dedup = '';
        if (inputs.deduplication == "MarkDuplicates") {
            tool = 'bamsormadup';
            dedup = ' markduplicates=1';
        } else {
            if (inputs.output_format == 'CRAM') tool = 'bamsort index=0';
            else tool = 'bamsort index=1';
            if (inputs.deduplication == "RemoveDuplicates") dedup = ' rmdup=1';
            else dedup = '';
        }
        var sort_path = tool + dedup;

        var indexfilename = '';
        var out_format = '';
        var extension  = '';
        // Coordinate Sorted BAM is default
        if (inputs.output_format == 'CRAM') {
            out_format = ' outputformat=cram SO=coordinate';
            ref_name = inputs.reference_index_tar.basename.split('.tar')[0];
            out_format += ' reference=' + ref_name;
            if (sort_path != 'bamsort index=0') indexfilename = ' indexfilename=' + fname + '.cram.crai';
            extension = '.cram';
        } else if (inputs.output_format == 'SAM') {
            out_format = ' outputformat=sam SO=coordinate';
            extension = '.sam';
        } else if (inputs.output_format == 'Queryname Sorted BAM') {
            out_format = ' outputformat=bam SO=queryname';
            extension = '.bam';
        } else if (inputs.output_format == 'Queryname Sorted SAM') {
            out_format = ' outputformat=sam SO=queryname';
            extension = '.sam';
        } else {
            out_format = ' outputformat=bam SO=coordinate';
            indexfilename = ' indexfilename=' + fname + '.bam.bai';
            extension = '.bam';
        }
        var cmd = " | " + sort_path + " threads=" + threads + " level=1 tmplevel=-1 inputformat=sam";
        cmd += out_format;
        cmd += indexfilename;
        // capture metrics file
        cmd += " M=" + fname + ".sormadup_metrics.log";

        if (inputs.output_format == 'SAM') cmd = '';
        
        return cmd + ' > ' + fname + extension;
        
    }
  separate: false
  shellQuote: false
- prefix: ''
  position: 10004
  valueFrom: |-
    ${
        /// Get pipe status ///
        
        var  cmd = ";declare -i pipe_statuses=(\\${PIPESTATUS[*]});len=\\${#pipe_statuses[@]};declare -i tot=0;echo \\${pipe_statuses[*]};for (( i=0; i<\\${len}; i++ ));do if [ \\${pipe_statuses[\\$i]} -ne 0 ];then tot=\\${pipe_statuses[\\$i]}; fi;done;if [ \\$tot -ne 0 ]; then >&2 echo Error in piping. Pipe statuses: \\${pipe_statuses[*]};fi; if [ \\$tot -ne 0 ]; then false;fi\"";
        return cmd;
    }
  shellQuote: false
id: h-0d346887/h-635fc694/h-7bf69f0f/0
sbg:appVersion:
- v1.0
sbg:categories:
- Genomics
- Alignment
- CWL1.0
sbg:cmdPreview: |-
  /bin/bash -c " export REF_CACHE=${PWD} ;  tar -tvf reference.HG38.fasta.gz.tar 1>&2; tar -xf reference.HG38.fasta.gz.tar ;  bwa mem  -R '@RG\tID:1\tPL:Illumina\tSM:dnk_sample' -t 10  reference.HG38.fasta.gz  /path/to/LP6005524-DNA_C01_lane_7.sorted.converted.filtered.pe_2.gz /path/to/LP6005524-DNA_C01_lane_7.sorted.converted.filtered.pe_1.gz  | bamsormadup threads=8 level=1 tmplevel=-1 inputformat=sam outputformat=cram SO=coordinate reference=reference.HG38.fasta.gz indexfilename=LP6005524-DNA_C01_lane_7.sorted.converted.filtered.cram.crai M=LP6005524-DNA_C01_lane_7.sorted.converted.filtered.sormadup_metrics.log > LP6005524-DNA_C01_lane_7.sorted.converted.filtered.cram  ;declare -i pipe_statuses=(\${PIPESTATUS[*]});len=\${#pipe_statuses[@]};declare -i tot=0;echo \${pipe_statuses[*]};for (( i=0; i<\${len}; i++ ));do if [ \${pipe_statuses[\$i]} -ne 0 ];then tot=\${pipe_statuses[\$i]}; fi;done;if [ \$tot -ne 0 ]; then >&2 echo Error in piping. Pipe statuses: \${pipe_statuses[*]};fi; if [ \$tot -ne 0 ]; then false;fi"
sbg:content_hash: a4965586211232dc4651281d3de154eac59adbbe47becb0c3a5f73560b751f560
sbg:contributors:
- nens
- ana_stankovic
- uros_sipetic
sbg:createdBy: uros_sipetic
sbg:createdOn: 1555689212
sbg:expand_workflow: false
sbg:id: h-0d346887/h-635fc694/h-7bf69f0f/0
sbg:image_url:
sbg:latestRevision: 21
sbg:license: |-
  BWA: GNU Affero General Public License v3.0, MIT License; Biobambam2: GNU General Public License v3.0
sbg:links:
- id: http://bio-bwa.sourceforge.net/
  label: Homepage
- id: https://github.com/lh3/bwa
  label: Source code
- id: http://bio-bwa.sourceforge.net/bwa.shtml
  label: Wiki
- id: http://sourceforge.net/projects/bio-bwa/
  label: Download
- id: http://arxiv.org/abs/1303.3997
  label: Publication
- id: http://www.ncbi.nlm.nih.gov/pubmed/19451168
  label: Publication BWA Algorithm
sbg:modifiedBy: nens
sbg:modifiedOn: 1611175341
sbg:project: nens/bwa-0-7-15-cwl1-0-demo
sbg:projectName: BWA 0.7.15 CWL1.0 - Demo
sbg:publisher: sbg
sbg:revision: 21
sbg:revisionNotes: added ignore_rg_id
sbg:revisionsInfo:
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1555689212
  sbg:revision: 0
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/1
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1556035789
  sbg:revision: 1
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/3
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1556037315
  sbg:revision: 2
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/4
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1556192655
  sbg:revision: 3
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/5
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1556193727
  sbg:revision: 4
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/6
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000453
  sbg:revision: 5
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/9
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558002186
  sbg:revision: 6
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/10
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558021975
  sbg:revision: 7
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/12
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558023132
  sbg:revision: 8
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/13
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558085159
  sbg:revision: 9
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/15
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558349205
  sbg:revision: 10
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/16
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351490
  sbg:revision: 11
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/17
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558427784
  sbg:revision: 12
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/18
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558441939
  sbg:revision: 13
  sbg:revisionNotes: Copy of nens/bwa-0-7-15-cwl1-dev/bwa-mem-bundle-0-7-15/22
- sbg:modifiedBy: ana_stankovic
  sbg:modifiedOn: 1579532841
  sbg:revision: 14
  sbg:revisionNotes: Bug fix for CRAM output with no PCR deduplication
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1581075318
  sbg:revision: 15
  sbg:revisionNotes: dev - v25; var added
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1581350490
  sbg:revision: 16
  sbg:revisionNotes: |-
    Add platform read group to the BAM even when no_rg_information parameter is specified, based on the input BAM platform metadata.
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1581359515
  sbg:revision: 17
  sbg:revisionNotes: Remove the default PL RG bit
- sbg:modifiedBy: ana_stankovic
  sbg:modifiedOn: 1592998681
  sbg:revision: 18
  sbg:revisionNotes: Updated JS to assign a unique Read group ID when the tool is
    scattered
- sbg:modifiedBy: ana_stankovic
  sbg:modifiedOn: 1609141711
  sbg:revision: 19
  sbg:revisionNotes: |-
    JavaScript cleanup; Default setting of Platform and Sample ID; Description update
- sbg:modifiedBy: ana_stankovic
  sbg:modifiedOn: 1609169898
  sbg:revision: 20
  sbg:revisionNotes: filter_out_secondary_alignments parameter removed
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1611175341
  sbg:revision: 21
  sbg:revisionNotes: added ignore_rg_id
sbg:sbgMaintained: false
sbg:toolAuthor: Heng Li
sbg:toolkit: BWA
sbg:toolkitVersion: 0.7.15
sbg:validationErrors: []
