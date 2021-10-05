cwlVersion: v1.0
class: CommandLineTool
label: SBG Lines to Interval List
doc: |-
  This tools is used for splitting GATK sequence grouping file into subgroups.

  ### Common Use Cases

  Each subgroup file contains intervals defined on single line in grouping file. Grouping file is output of GATKs **CreateSequenceGroupingTSV** script which is used in best practice workflows sush as **GATK Best Practice Germline Workflow**.
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: 1
  ramMin: 1000
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/uros_sipetic/sci-python:2.7
- class: InitialWorkDirRequirement
  listing:
  - entryname: lines_to_intervals.py
    writable: false
    entry: |
      import sys
      import hashlib
      import os
      import json

      obj_template = {
          'basename': '',
          'checksum': '',
          'class': 'File',
          'dirname': '',
          'location': '',
          'nameext': 'intervals',
          'nameroot': '',
          'path': '',
          'size': '',
      }

      with open(sys.argv[1], 'r') as f:

          obj_list = []
          sys.stderr.write('Reading file {}\n'.format(sys.argv[1]))
          nameroot = '.'.join(sys.argv[1].split('/')[-1].split('.')[:-1])
          for i, line in enumerate(f):
              out_file_name = '{}.group.{}.intervals'.format(nameroot, i+1)
              out_file = open(out_file_name, 'a')
              for interval in line.split():
                  out_file.write(interval + '\n')
              out_file.close()
              sys.stderr.write('Finished writing to file {}\n'.format(out_file_name))

              obj = dict(obj_template)
              obj['basename'] = out_file_name
              obj['checksum'] = 'sha1$' + hashlib.sha1(open(out_file_name, 'r').read()).hexdigest()
              obj['dirname'] = os.getcwd()
              obj['location'] = '/'.join([os.getcwd(), out_file_name])
              obj['nameroot'] = '.'.join(out_file_name.split('.')[:-1])
              obj['path'] = '/'.join([os.getcwd(), out_file_name])
              obj['size'] = os.path.getsize('/'.join([os.getcwd(), out_file_name]))

              obj_list.append(obj)

          out_json = {'out_intervals': obj_list}

          json.dump(out_json, open('cwl.output.json', 'w'), indent=1)
          sys.stderr.write('Job done.\n')
- class: InlineJavascriptRequirement

inputs:
- id: input_tsv
  label: Input group file
  doc: This file is output of GATKs CreateSequenceGroupingTSV script.
  type: File
  inputBinding:
    position: 1
    shellQuote: false
  sbg:category: Required Arguments
  sbg:fileTypes: TSV, TXT

outputs:
- id: out_intervals
  label: Intervals
  doc: GATK Intervals files.
  type: File[]
  sbg:fileTypes: INTERVALS, BED

baseCommand:
- python
- lines_to_intervals.py
id: h-5776a0cb/h-7ef9c5f0/h-bafddde6/0
sbg:appVersion:
- v1.0
sbg:content_hash: a7c4b064a52abdea428818baaba8fdc326902195b3a61fdfdd774c657825c5cc6
sbg:contributors:
- nens
sbg:createdBy: nens
sbg:createdOn: 1566809066
sbg:id: h-5776a0cb/h-7ef9c5f0/h-bafddde6/0
sbg:image_url:
sbg:latestRevision: 3
sbg:modifiedBy: nens
sbg:modifiedOn: 1611663678
sbg:project: sevenbridges/sbgtools-cwl1-0-demo
sbg:projectName: SBGTools - CWL1.x - Demo
sbg:publisher: sbg
sbg:revision: 3
sbg:revisionNotes: docker image
sbg:revisionsInfo:
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1566809066
  sbg:revision: 0
  sbg:revisionNotes:
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1566809311
  sbg:revision: 1
  sbg:revisionNotes: v1 - dev
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1611663319
  sbg:revision: 2
  sbg:revisionNotes: v2 - dev
- sbg:modifiedBy: nens
  sbg:modifiedOn: 1611663678
  sbg:revision: 3
  sbg:revisionNotes: docker image
sbg:sbgMaintained: false
sbg:toolAuthor: Stefan Stojanovic
sbg:toolkit: SBG Tools
sbg:toolkitVersion: '1.0'
sbg:validationErrors: []
