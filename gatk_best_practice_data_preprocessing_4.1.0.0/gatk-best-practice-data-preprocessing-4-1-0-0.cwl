cwlVersion: v1.0
class: Workflow
label: GATK Best Practice Data Pre-processing 4.1.0.0
doc: |-
  **Note:** This version of the GATK Best Practice Data Pre-processing 4.1.0.0 workflow was created for testing purposes regarding github actions and CI/CD only. Changes vs the public tool are purely to run tests and should't affect functionality, but this version is not supported by SBG in production.
  
  **BROAD Best Practice Data Pre-processing Workflow 4.1.0.0**  is used to prepare data for variant calling analysis. 

  It can be divided into two major segments: alignment to reference genome and data cleanup operations that correct technical biases [1].

  *A list of all inputs and parameters with corresponding descriptions can be found at the bottom of this page.*

  ***Please note that any cloud infrastructure costs resulting from app and pipeline executions, including the use of public apps, are the sole responsibility of you as a user. To avoid excessive costs, please read the app description carefully and set the app parameters and execution settings accordingly.***

  ### Common Use Cases

  * **BROAD Best Practice Data Pre-processing Workflow 4.1.0.0**  is designed to operate on individual samples.
  * Resulting BAM files are ready for variant calling analysis and can be further processed by other BROAD best practice pipelines, like **Generic germline short variant per-sample calling workflow** [2], **Somatic CNVs workflow** [3] and **Somatic SNVs+Indel workflow** [4].


  ### Changes Introduced by Seven Bridges

  This pipeline represents the CWL implementation of BROADs [original WDL file](https://github.com/gatk-workflows/gatk4-data-processing/pull/14) available on github. Minor differences are introduced in order to successfully adapt to the Seven Bridges Platform. These differences are listed below:
  * **SamToFastqAndBwaMem** step is divided into elementary steps: **SamToFastq** - converting unaligned BAM file to interleaved  FASTQ file, **BWA Mem** - performing alignment and **Samtools View** - used for converting SAM file to BAM.
  *  A boolean parameter **Ignore default RG ID** is added to **BWA MEM Bundle** tool. When used, this parameter ensures that **BWA MEM Bundle** does not add read group information (RG) in the BAM file. Instead, RG ID information obtained from uBAM is added by **GATK MergeBamAlignment** afterwards. 
  * **SortAndFixTags** is divided into elementary steps: **SortSam** and **SetNmMdAndUqTags**
  * Added **SBG Lines to Interval List**: this tool is used to adapt results obtained with **CreateSequenceGroupingTSV**  for platform execution, more precisely for scattering.



  ### Common Issues and Important Notes

  * **BROAD Best Practice Data Pre-processing Workflow 4.1.0.0**  expects unmapped BAM (uBAM) file format as the main input. One or more read groups, one per uBAM file, all belonging to a single sample (SM).
  * **Input Alignments** (`--in_alignments`) - provided uBAM file should be in query-sorted order and all reads must have RG tags. Also, input uBAM files must pass validation by **ValidateSamFile**.
  * For each tool in the workflow, equivalent parameter settings to the one listed in the corresponding WDL file are set as defaults. 

  ### Performance Benchmarking
  Since this CWL implementation is meant to be equivalent to GATKs original WDL, there are no additional optimisation steps beside instance and storage definition. 
  The c5.9xlarge AWS instance hint is used for WGS inputs and attached storage is set to 1.5TB.
  In the table given below one can find results of test runs for WGS and WES samples. All calculations are performed with reference files corresponding to assembly 38.

  *Cost can be significantly reduced by spot instance usage. Visit the [knowledge center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*

  | Input Size | Experimental Strategy | Coverage| Duration | Cost (spot) | AWS Instance Type |
  | --- | --- | --- | --- | --- | --- | 
  | 6.6 GiB | WES | 70 |1h 19min | $2.61 | c5.9 |
  |3.4 GiB | WES |  40 | 42min   | $1.40 | c5.9 |
  | 111.3 GiB| WGS | 30 |22h 41min | $43.86 | c5.9 |
  | 37.2 GiB  | WGS | 10 | 4h 21min | $14.21 | c5.9 |



  ### API Python Implementation
  The app's draft task can also be submitted via the **API**. In order to learn how to get your **Authentication token** and **API endpoint** for corresponding platform visit our [documentation](https://github.com/sbg/sevenbridges-python#authentication-and-configuration).

  ```python
  # Initialize the SBG Python API
  from sevenbridges import Api
  api = Api(token="enter_your_token", url="enter_api_endpoint")
  # Get project_id/app_id from your address bar. Example: https://igor.sbgenomics.com/u/your_username/project/app
  project_id = "your_username/project"
  app_id = "your_username/project/app"
  # Replace inputs with appropriate values
  inputs = {
  	"in_alignments": list(api.files.query(project=project_id, names=["<unaligned_bam>"])), 
  	"reference_index_tar": api.files.query(project=project_id, names=["Homo_sapiens_assembly38.fasta.tar"])[0], 
  	"in_reference": api.files.query(project=project_id, names=["Homo_sapiens_assembly38.fasta"])[0], 
  	"ref_dict": api.files.query(project=project_id, names=["Homo_sapiens_assembly38.dict"])[0],
  	"known_snps": api.files.query(project=project_id, names=["Homo_sapiens_assembly38.dbsnp.vcf"])[0],
          "known_sites": list(api.files.query(project=project_id, names=["Homo_sapiens_assembly38.known_indels.vcf", “Mills_and_1000G_gold_standard.indels.hg38.vcf”, “Homo_sapiens_assembly38.dbsnp.vcf”
  ]))}
  # Creates draft task
  task = api.tasks.create(name="BROAD Best Practice Data Pre-processing Workflow 4.1.0.0 - API Run", project=project_id, app=app_id, inputs=inputs, run=False)
  ```

  Instructions for installing and configuring the API Python client, are provided on [github](https://github.com/sbg/sevenbridges-python#installation). For more information about using the API Python client, consult [the client documentation](http://sevenbridges-python.readthedocs.io/en/latest/). **More examples** are available [here](https://github.com/sbg/okAPI).

  Additionally, [API R](https://github.com/sbg/sevenbridges-r) and [API Java](https://github.com/sbg/sevenbridges-java) clients are available. To learn more about using these API clients please refer to the [API R client documentation](https://sbg.github.io/sevenbridges-r/), and [API Java client documentation](https://docs.sevenbridges.com/docs/java-library-quickstart).


  ### References

  [1] [Data Pre-processing](https://software.broadinstitute.org/gatk/best-practices/workflow?id=11165)
  [2] [Generic germline short variant per-sample calling](https://software.broadinstitute.org/gatk/best-practices/workflow?id=11145)
  [3] [Somatic CNVs](https://software.broadinstitute.org/gatk/best-practices/workflow?id=11147)
  [4] [Somatic SNVs+Indel pipeline ](https://software.broadinstitute.org/gatk/best-practices/workflow?id=11146)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ScatterFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement

inputs:
- id: in_alignments
  label: Input alignments
  doc: Input alignments files in unmapped BAM format.
  type: File[]
  sbg:fileTypes: SAM, BAM
  sbg:x: -648.1359252929688
  sbg:y: 25.01337432861328
- id: reference_index_tar
  label: BWA index archive
  doc: FASTA reference or BWA index archive.
  type: File
  sbg:fileTypes: TAR
  sbg:suggestedValue:
    name: GRCh38_primary_assembly_plus_ebv_alt_decoy_hla.fasta.tar
    class: File
    path: 5b6ace6e7550b4c330563856
  sbg:x: -583.3368530273438
  sbg:y: 259.1632995605469
- id: in_reference
  label: FASTA reference
  doc: Input reference in FASTA format.
  type: File
  secondaryFiles:
  - .fai
  - ^.dict
  sbg:fileTypes: FASTA, FA
  sbg:suggestedValue:
    name: Homo_sapiens_assembly38.fasta
    class: File
    path: 5772b6c7507c1752674486d1
  sbg:x: -447.3492126464844
  sbg:y: 555
- id: ref_dict
  label: DICT file
  doc: DICT file corresponding to the FASTA reference.
  type: File
  sbg:fileTypes: DICT
  sbg:suggestedValue:
    name: Homo_sapiens_assembly38.dict
    class: File
    path: 5c9ce4687369c402ac8a3c41
  sbg:x: 599.5844116210938
  sbg:y: -34.96286392211914
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
  sbg:fileTypes: VCF, VCF.GZ, BED
  sbg:x: 867.6756591796875
  sbg:y: 580.4737548828125

outputs:
- id: out_alignments
  label: Output BAM file
  doc: Output BAM file.
  type: File?
  outputSource:
  - gatk_gatherbamfiles_4_1_0_0/out_alignments
  sbg:fileTypes: BAM
  sbg:x: 2052.86767578125
  sbg:y: 289.4576416015625
- id: out_md5
  label: MD5 file
  doc: MD5 sum of the output BAM file.
  type: File?
  outputSource:
  - gatk_gatherbamfiles_4_1_0_0/out_md5
  sbg:fileTypes: MD5
  sbg:x: 2048
  sbg:y: 114.24113464355469
- id: out_duplication_metrics
  label: Duplication metrics
  doc: Duplication metrics file produced by GATK MarkDuplicates.
  type: File
  outputSource:
  - gatk_markduplicates_4_1_0_0/output_metrics
  sbg:fileTypes: METRICS
  sbg:x: 457.1893615722656
  sbg:y: -51.47343826293945

steps:
- id: gatk_markduplicates_4_1_0_0
  label: GATK MarkDuplicates
  in:
  - id: assume_sort_order
    default: queryname
  - id: in_alignments
    source:
    - gatk_mergebamalignment_4_1_0_0/out_alignments
  - id: optical_duplicate_pixel_distance
    default: 2500
  - id: validation_stringency
    default: SILENT
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_markduplicates_4_1_0_0.cwl
  out:
  - id: out_alignments
  - id: output_metrics
  sbg:x: 252.3874969482422
  sbg:y: 88.93749237060547
- id: bwa_mem_bundle_0_7_15
  label: BWA MEM Bundle
  in:
  - id: verbose_level
    default: '3'
  - id: smart_pairing_in_input_fastq
    default: true
  - id: input_reads
    source:
    - gatk_samtofastq_4_1_0_0/out_reads
  - id: num_input_bases_in_each_batch
    default: 100000000
  - id: use_soft_clipping
    default: true
  - id: threads
    default: 16
  - id: output_header
    default: false
  - id: reference_index_tar
    source: reference_index_tar
  - id: output_format
    default: SAM
  - id: mapQ_of_suplementary
    default: false
  - id: ignore_default_rg_id
    default: true
  scatter:
  - input_reads
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/bwa_mem_bundle_0_7_15.cwl
  out:
  - id: aligned_reads
  - id: dups_metrics
  sbg:x: -334.3309020996094
  sbg:y: 257.5992736816406
- id: gatk_mergebamalignment_4_1_0_0
  label: GATK MergeBamAlignment
  in:
  - id: add_mate_cigar
    default: 'true'
  - id: in_alignments
    valueFrom: $([self])
    source:
    - samtools_view_1_9_cwl1_0/out_alignments
  - id: aligner_proper_pair_flags
    default: true
  - id: attributes_to_retain
    default:
    - X0
  - id: clip_adapters
    default: 'false'
  - id: expected_orientations
    default:
    - FR
  - id: max_insertions_or_deletions
    default: -1
  - id: max_records_in_ram
    default: 2000000
  - id: paired_run
    default: 'true'
  - id: primary_alignment_strategy
    default: MostDistant
  - id: program_group_command_line
    default: '"bwa mem -K 100000000 -p -v 3 -t 16 -Y ref_fasta"'
  - id: program_group_name
    default: bwamem
  - id: program_group_version
    default: 0.7.15
  - id: program_record_id
    default: bwamem
  - id: in_reference
    source: in_reference
  - id: sort_order
    default: unsorted
  - id: unmap_contaminant_reads
    default: true
  - id: unmapped_bam
    source: in_alignments
  - id: unmapped_read_strategy
    default: COPY_TO_TAG
  - id: validation_stringency
    default: SILENT
  scatter:
  - in_alignments
  - unmapped_bam
  scatterMethod: dotproduct
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_mergebamalignment_4_1_0_0.cwl
  out:
  - id: out_alignments
  sbg:x: -9
  sbg:y: 53.96965026855469
- id: gatk_samtofastq_4_1_0_0
  label: GATK SamToFastq
  in:
  - id: include_non_pf_reads
    default: true
  - id: in_alignments
    source: in_alignments
  - id: interleave
    default: true
  scatter:
  - in_alignments
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_samtofastq_4_1_0_0.cwl
  out:
  - id: out_reads
  - id: unmapped_reads
  sbg:x: -444.0947265625
  sbg:y: 120.06857299804688
- id: gatk_sortsam_4_1_0_0
  label: GATK SortSam
  in:
  - id: in_alignments
    source: gatk_markduplicates_4_1_0_0/out_alignments
  - id: sort_order
    default: coordinate
  run: gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_sortsam_4_1_0_0.cwl
  out:
  - id: out_alignments
  sbg:x: 434.41656494140625
  sbg:y: 186.55223083496094
- id: gatk_setnmmdanduqtags_4_1_0_0
  label: GATK SetNmMdAndUqTags
  in:
  - id: create_index
    default: true
  - id: in_alignments
    source: gatk_sortsam_4_1_0_0/out_alignments
  - id: reference_sequence
    source: in_reference
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_setnmmdanduqtags_4_1_0_0.cwl
  out:
  - id: out_alignments
  sbg:x: 675.0732421875
  sbg:y: 260.1669006347656
- id: gatk_baserecalibrator_4_1_0_0
  label: GATK BaseRecalibrator
  in:
  - id: in_alignments
    source:
    - gatk_setnmmdanduqtags_4_1_0_0/out_alignments
  - id: include_intervals_file
    source: sbg_lines_to_interval_list_br/out_intervals
  - id: known_sites
    source:
    - known_sites
  - id: in_reference
    source: in_reference
  - id: use_original_qualities
    default: true
  scatter:
  - include_intervals_file
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_baserecalibrator_4_1_0_0.cwl
  out:
  - id: out_bqsr_report
  sbg:x: 1241.2686767578125
  sbg:y: 307.5648193359375
- id: gatk_createsequencegroupingtsv_4_1_0_0
  label: GATK CreateSequenceGroupingTSV
  in:
  - id: ref_dict
    source: ref_dict
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_createsequencegroupingtsv_4_1_0_0.cwl
  out:
  - id: sequence_grouping
  - id: sequence_grouping_with_unmapped
  sbg:x: 767.7706909179688
  sbg:y: 6.801900386810303
- id: gatk_gatherbqsrreports_4_1_0_0
  label: GATK GatherBQSRReports
  in:
  - id: in_bqsr_reports
    source:
    - gatk_baserecalibrator_4_1_0_0/out_bqsr_report
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_gatherbqsrreports_4_1_0_0.cwl
  out:
  - id: out_gathered_bqsr_report
  sbg:x: 1494.5830078125
  sbg:y: 330
- id: gatk_applybqsr_4_1_0_0
  label: GATK ApplyBQSR
  in:
  - id: add_output_sam_program_record
    default: 'true'
  - id: bqsr_recal_file
    source: gatk_gatherbqsrreports_4_1_0_0/out_gathered_bqsr_report
  - id: in_alignments
    source:
    - gatk_setnmmdanduqtags_4_1_0_0/out_alignments
  - id: include_intervals_file
    source: sbg_lines_to_interval_list_abr/out_intervals
  - id: in_reference
    source: in_reference
  - id: static_quantized_quals
    default:
    - 10
    - 20
    - 30
  - id: use_original_qualities
    default: true
  scatter:
  - include_intervals_file
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_applybqsr_4_1_0_0.cwl
  out:
  - id: out_alignments
  sbg:x: 1615.560546875
  sbg:y: 207.82618713378906
- id: gatk_gatherbamfiles_4_1_0_0
  label: GATK GatherBamFiles
  in:
  - id: create_index
    default: true
  - id: in_alignments
    source:
    - gatk_applybqsr_4_1_0_0/out_alignments
  - id: create_md5_file
    default: true
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/gatk_gatherbamfiles_4_1_0_0.cwl
  out:
  - id: out_alignments
  - id: out_md5
  sbg:x: 1867.5662841796875
  sbg:y: 208.6806640625
- id: samtools_view_1_9_cwl1_0
  label: Samtools View
  in:
  - id: output_format
    default: BAM
  - id: fast_bam_compression
    default: true
  - id: include_header
    default: false
  - id: in_alignments
    source: bwa_mem_bundle_0_7_15/aligned_reads
  scatter:
  - in_alignments
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/samtools_view_1_9_cwl1_0.cwl
  out:
  - id: out_alignments
  - id: reads_not_selected_by_filters
  - id: alignement_count
  sbg:x: -106.09046173095703
  sbg:y: 247.76466369628906
- id: sbg_lines_to_interval_list_abr
  label: SBG Lines to Interval List
  in:
  - id: input_tsv
    source: gatk_createsequencegroupingtsv_4_1_0_0/sequence_grouping_with_unmapped
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/sbg_lines_to_interval_list_abr.cwl
  out:
  - id: out_intervals
  sbg:x: 981.438232421875
  sbg:y: -67.39484405517578
- id: sbg_lines_to_interval_list_br
  label: SBG Lines to Interval List
  in:
  - id: input_tsv
    source: gatk_createsequencegroupingtsv_4_1_0_0/sequence_grouping
  run: |-
    gatk-best-practice-data-preprocessing-4-1-0-0.cwl.steps/sbg_lines_to_interval_list_br.cwl
  out:
  - id: out_intervals
  sbg:x: 979.7381591796875
  sbg:y: 135.31478881835938

hints:
- class: sbg:AWSInstanceType
  value: c5.9xlarge;ebs-gp2;3000
sbg:appVersion:
- v1.0
sbg:categories:
- Genomics
- Alignment
- CWL1.0
- GATK
sbg:content_hash: a5994ea3859dedf1b3e91475b419e6da1d47682fbbb9bb25c1b9a54a39428af9e
sbg:contributors:
- jeffrey.grover
sbg:createdBy: jeffrey.grover
sbg:createdOn: 1632777702
sbg:expand_workflow: false
sbg:id: |-
  jeffrey.grover/local-cwl-development-ci-cd-example/broad-best-practice-data-pre-processing-workflow-4-1-0-0/1
sbg:image_url: |-
  https://cgc.sbgenomics.com/ns/brood/images/jeffrey.grover/local-cwl-development-ci-cd-example/broad-best-practice-data-pre-processing-workflow-4-1-0-0/1.png
sbg:latestRevision: 1
sbg:license: BSD 3-Clause License
sbg:links:
- id: https://software.broadinstitute.org/gatk/best-practices/workflow?id=11165
  label: Homepage
- id: https://github.com/gatk-workflows/gatk4-data-processing
  label: Source Code
- id: |-
    https://github.com/broadinstitute/gatk/releases/download/4.1.0.0/gatk-4.1.0.0.zip
  label: Download
- id: https://www.ncbi.nlm.nih.gov/pubmed?term=20644199
  label: Publications
- id: https://software.broadinstitute.org/gatk/documentation/tooldocs/current/
  label: Documentation
sbg:modifiedBy: jeffrey.grover
sbg:modifiedOn: 1632777868
sbg:original_source: |-
  https://cgc-api.sbgenomics.com/v2/apps/jeffrey.grover/local-cwl-development-ci-cd-example/broad-best-practice-data-pre-processing-workflow-4-1-0-0/1/raw/
sbg:project: jeffrey.grover/local-cwl-development-ci-cd-example
sbg:projectName: Local CWL Development CI/CD Example
sbg:publisher: sbg
sbg:revision: 1
sbg:revisionNotes: Description changed to stop automatic updates of app for testing
  purposes
sbg:revisionsInfo:
- sbg:modifiedBy: jeffrey.grover
  sbg:modifiedOn: 1632777702
  sbg:revision: 0
  sbg:revisionNotes: |-
    Copy of admin/sbg-public-data/broad-best-practice-data-pre-processing-workflow-4-1-0-0/28
- sbg:modifiedBy: jeffrey.grover
  sbg:modifiedOn: 1632777868
  sbg:revision: 1
  sbg:revisionNotes: Description changed to stop automatic updates of app for testing
    purposes
sbg:sbgMaintained: false
sbg:toolAuthor: BROAD
sbg:validationErrors: []
sbg:wrapperAuthor: Seven Bridges
