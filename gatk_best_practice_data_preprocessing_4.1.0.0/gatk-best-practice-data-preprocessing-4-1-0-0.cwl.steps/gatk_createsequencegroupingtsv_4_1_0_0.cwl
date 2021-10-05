cwlVersion: v1.0
class: CommandLineTool
label: GATK CreateSequenceGroupingTSV
doc: |-
  **CreateSequenceGroupingTSV** tool generate sets of intervals for scatter-gathering over chromosomes.

  It takes **Reference dictionary** file (`--ref_dict`) as an input and creates files which contain chromosome names grouped based on their sizes.


  ###**Common Use Cases**

  The tool has only one input (`--ref_dict`) which is required and has no additional arguments. **CreateSequenceGroupingTSV** tool results are **Sequence Grouping** file which is a text file containing chromosome groups, and **Sequence Grouping with Unmapped**, a text file which has the same content as **Sequence Grouping** with additional line containing "unmapped" string.


  * Usage example


  ```
  python CreateSequenceGroupingTSV.py 
        --ref_dict example_reference.dict

  ```



  ###**Changes Introduced by Seven Bridges**

  Python code provided within WGS Germline WDL was adjusted to be called as a script (`CreateSequenceGroupingTSV.py`).


  ###**Common Issues and Important Notes**

  None.


  ### Reference
  [1] [CreateSequenceGroupingTSV](https://github.com/gatk-workflows/broad-prod-wgs-germline-snps-indels/blob/master/PairedEndSingleSampleWf-fc-hg38.wdl)
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: 1
  ramMin: 1000
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/stefan_stojanovic/gatk:4.1.0.0
- class: InitialWorkDirRequirement
  listing:
  - entryname: CreateSequenceGroupingTSV.py
    writable: false
    entry: |-
      import argparse

      args = argparse.ArgumentParser(description='This tool takes reference dictionary file as an input'
                                                   ' and creates files which contain chromosome names grouped'
                                                   ' based on their sizes.')

      args.add_argument('--ref_dict', help='Reference dictionary', required=True)
      parsed = args.parse_args()
      ref_dict = parsed.ref_dict

      with open(ref_dict, 'r') as ref_dict_file:
          sequence_tuple_list = []
          longest_sequence = 0
          for line in ref_dict_file:
              if line.startswith("@SQ"):
                  line_split = line.split("\t")
                  # (Sequence_Name, Sequence_Length)
                  sequence_tuple_list.append((line_split[1].split("SN:")[1], int(line_split[2].split("LN:")[1])))
          longest_sequence = sorted(sequence_tuple_list, key=lambda x: x[1], reverse=True)[0][1]
      # We are adding this to the intervals because hg38 has contigs named with embedded colons and a bug in GATK strips off
      # the last element after a :, so we add this as a sacrificial element.
      hg38_protection_tag = ":1+"
      # initialize the tsv string with the first sequence
      tsv_string = sequence_tuple_list[0][0] + hg38_protection_tag
      temp_size = sequence_tuple_list[0][1]
      for sequence_tuple in sequence_tuple_list[1:]:
          if temp_size + sequence_tuple[1] <= longest_sequence:
              temp_size += sequence_tuple[1]
              tsv_string += "\t" + sequence_tuple[0] + hg38_protection_tag
          else:
              tsv_string += "\n" + sequence_tuple[0] + hg38_protection_tag
              temp_size = sequence_tuple[1]
      # add the unmapped sequences as a separate line to ensure that they are recalibrated as well
      with open("./sequence_grouping.txt", "w") as tsv_file:
          tsv_file.write(tsv_string)
          tsv_file.close()

      tsv_string += '\n' + "unmapped"

      with open("./sequence_grouping_with_unmapped.txt", "w") as tsv_file_with_unmapped:
          tsv_file_with_unmapped.write(tsv_string)
          tsv_file_with_unmapped.close()
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
- id: ref_dict
  label: Reference Dictionary
  doc: |-
    Reference dictionary containing information about chromosome names and their lengths.
  type: File
  inputBinding:
    prefix: --ref_dict
    position: 0
    shellQuote: false
  sbg:fileTypes: DICT

outputs:
- id: sequence_grouping
  label: Sequence Grouping
  doc: |-
    Each line of the file represents one group of chromosomes which are processed together in later steps of the GATK Germline workflow. The groups are determined based on the chromosomes sizes.
  type: File?
  outputBinding:
    glob: sequence_grouping.txt
    outputEval: $(inheritMetadata(self, inputs.ref_dict))
  sbg:fileTypes: TXT
- id: sequence_grouping_with_unmapped
  label: Sequence Grouping with Unmapped
  doc: |-
    The file has the same content as "Sequence Grouping" file, with an additional, last line containing "unmapped" string.
  type: File?
  outputBinding:
    glob: sequence_grouping_with_unmapped.txt
    outputEval: $(inheritMetadata(self, inputs.ref_dict))
  sbg:fileTypes: TXT

baseCommand:
- python
- CreateSequenceGroupingTSV.py
id: h-c4cc4d91/h-ce015b9b/h-2176f951/0
sbg:appVersion:
- v1.0
sbg:categories:
- Utilities
- BED Processing
sbg:content_hash: a9afa170a339934c60906ff616a6f2155426a9df80067bfc64f4140593aeffda6
sbg:contributors:
- nens
- uros_sipetic
sbg:copyOf: veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/createsequencegroupingtsv/6
sbg:createdBy: uros_sipetic
sbg:createdOn: 1555580154
sbg:id: h-c4cc4d91/h-ce015b9b/h-2176f951/0
sbg:image_url:
sbg:latestRevision: 4
sbg:license: BSD 3-clause
sbg:links:
- id: https://github.com/gatk-workflows/broad-prod-wgs-germline-snps-indels
  label: GATK Germline GitHub
sbg:modifiedBy: nens
sbg:modifiedOn: 1558351560
sbg:project: uros_sipetic/gatk-4-1-0-0-demo
sbg:projectName: GATK 4.1.0.0 - Demo
sbg:publisher: sbg
sbg:revision: 4
sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/createsequencegroupingtsv/6
sbg:revisionsInfo:
- sbg:modifiedBy: uros_sipetic
  sbg:modifiedOn: 1555580154
  sbg:revision: 0
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/createsequencegroupingtsv/1
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557734537
  sbg:revision: 1
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/createsequencegroupingtsv/3
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1557914517
  sbg:revision: 2
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/createsequencegroupingtsv/4
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558000609
  sbg:revision: 3
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/createsequencegroupingtsv/5
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1558351560
  sbg:revision: 4
  sbg:revisionNotes: Copy of veliborka_josipovic/gatk-4-1-0-0-toolkit-dev/createsequencegroupingtsv/6
sbg:sbgMaintained: false
sbg:toolAuthor: Broad Institute
sbg:toolkit: GATK
sbg:toolkitVersion: 4.1.0.0
sbg:validationErrors: []
