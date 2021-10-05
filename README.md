# Local Development and Continuous Integration For CWL Using the SB Platform

This repository contains code examples to show how to set up testing for your
CWL that is automatically triggered when you make commits to your code in a
github repository. It also shows how to set-up automated pushing of updated
workflows to a Seven Bridges Platform. These processes are also known as
continuous integration and deployment, respectively. 

This development model of local -> github -> Seven Bridges is geared toward
advanced users. It enables combining Seven Bridges' interface, CWL execution
advantages, and scalability with best practices in automated testing and version
control. This also helps enable collaborative development through git across
teams all contributing to the same workflows and tools.

This demonstration assumes you know how the basics of using the [git
versioning system](https://git-scm.com/docs/gittutorial). 

It also assumes some familiarity with Unix-like command line usage (BASH, zsh,
etc.), [cwl](https://www.commonwl.org/), [Docker](https://www.docker.com/),
installing Python packages, and running bioinformatics software.

**Note:** This guide is *one* way of doing local develop and CI/CD. If you have
a preferred development model that differs from this, you're welcome to use what
you're comfortable with.

This repository takes inspiration from a previously-written
[tutorial](https://sb-biodatacatalyst.readme.io/docs/maintaining-and-versioning-cwl-on-external-tool-repositories)
and work by [Kaushik Ghose](https://github.com/kghose).

## Requirements

1. [Docker](https://www.docker.com/)
2. [cwltool](https://github.com/common-workflow-language/cwltool)
3. [sbpack](https://github.com/rabix/sbpack)
4. [git](https://git-scm.com/) and a [github](https://github.com/) repository
5. [Benten](https://github.com/rabix/benten) (optional, but recommended)
6. [VSCode](https://code.visualstudio.com/) (or your favorite Benten-compatible text editor)

## Repository organization

This repository is composed of several folders, for organization purposes. The
follow descriptions may prove helpful.

- `.github/workflows` - [Github Actions](https://docs.github.com/en/actions) configuration for `sbpack`.
- `fastqc_tool_cwl1.0` - Single-tool example workflow for [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) and available in the [CGC Public Apps Gallery](https://cgc.sbgenomics.com/public/apps/admin/sbg-public-data/fastqc-0-11-9).
- `gatk_best_practice_data_preprocessing_4.1.0.0` - Multi-step example from the [Data pre-processing for variant discovery](https://gatk.broadinstitute.org/hc/en-us/articles/360035535912-Data-pre-processing-for-variant-discovery) workflow. Also available in the [CGC Public Apps Gallery](https://cgc.sbgenomics.com/public/apps/admin/sbg-public-data/broad-best-practice-data-pre-processing-workflow-4-1-0-0) and [Seven Bridges Openworkflows](https://github.com/sevenbridges-openworkflows/Broad-Best-Practice-Data-pre-processing-CWL1.0-workflow) repository.
- `test_data` - Contains small test data files.
- `test_scripts` - Script examples to automate testing your cwl

## Setting up a Github repository for developing CWL workflows for a Seven Bridges Platform

General steps to create a Github repository that you can use to develop CWL
for later deployment to a Seven Bridges Platform.

0. Install all required software
1. Create a project on one of Seven Bridges' platforms
    - [Cancer Genomics Cloud](https://cgc.sbgenomics.com)
    - [Cavatica](https://pgc-accounts.sbgenomics.com/)
    - [BioData Catalyst Powered by Seven Bridges](https://accounts.sb.biodatacatalyst.nhlbi.nih.gov/)
    - [Seven Bridges Commercial Platform](https://igor.sbgenomics.com)
    - [Seven Bridges EU](https://eu.sbgenomics.com)
2. Create or copy an app (tools and/or workflows)
    - If developing your own from scratch you can start with a blank tool/workflow
    - If you're just getting started or want to modify an app start with something from the [Public Apps Gallery (CGC Link)](https://cgc.sbgenomics.com/public/apps)
3. Create a Github repository
    - Either with `git init` locally or
    - Via the web-UI and `git clone` to your local machine
4. Use `sbpull` to "pull" your app to your github repo
    - Recommended: Create a single repo for each workflow, or create sub-directories for each
    - Recommended: Use the `--unpack` option to "explode" your individual steps into separate .cwl files for easier editing
    - Starting on the platform and pulling to your local machine ensures that
    the tools and workflows contain the appropriate reference to link to your
    on-platform project and apps

# Local CWL Development Using Benten

Many advanced bioinformaticians and software developers have **STRONG** opinions
about their favorite code/text editor. They also like the flexibility of writing
code on their local machine, where they customize their environment to their
liking. To accomodate this, the [Benten](https://github.com/rabix/benten)
language server provides code intelligence features for many popular editors.
This includes a plugin for [Microsoft VSCode](https://code.visualstudio.com/).

Writing CWL with Benten can reduce the chances of writing invalid CWL due to its
atuocompletion and built-in workflow visualization abilities.

# Tool/Workflow Testing

## Manual testing of individual tools using small input files

For each tool and workflow it is important to collect a set of small input
datasets that the CWL can run quickly to check it's operation. Ideally we would
also have a checker script that can analyze the output of the runs and verify
correctness.

You can find an example of a script that runs a single tool in the
[test_scripts/run_fastqc_tool_cwl1.0.sh](https://github.com/rabix/sb-ci/blob/master/test_scripts/run_fastqc_tool_cwl1.0.sh)
file. The [test_data](https://github.com/rabix/sb-ci/blob/master/test_data/H06HDADXX130110.1.ATCACGAT.1_read_1.fastq)
for this single-tool execution is a single-read fastq file. It is small, but
still valid.

## Automated pre-commit testing cwl with `cwltool --validate`

For large workflows with many steps, running the complete workflow each time a
change is made can take a very long time. Therefore, testing each step
separately is preferred. Additionally, `cwltool` includes a `--validate` option.
This enables checking the validity of cwl code without running the steps. We
will take advantage of this functionality for our automated testing. The 
[gatk_best_practice_data_preprocessing_4.1.0.0](https://github.com/rabix/sb-ci/tree/master/gatk_best_practice_data_preprocessing_4.1.0.0)
workflow is an example of such a complicated app.

Git supports [pre-commit hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks).
This allows configuration of scripts to run at predefined times. In this case,
we have created the script [pre-commit](https://github.com/rabix/sb-ci/blob/master/test_scripts/pre-commit)
which runs [check-changed.sh](https://github.com/rabix/sb-ci/blob/master/test_scripts/check-changed.sh).
The `pre-commit` script must be copied to the repository's `.git/hooks/`
directory. It is provided here as the `.git/hooks/` directory is untracked.

The `check-changed.sh` script includes a clever use of git commands and BASH to
list only the .cwl files which have changed in your latest commit and runs
`cwltool --validate` on them. This doesn't waste time by running it on files
which have not changed, and on files that are not cwl in your repository.

**Note** This **WILL** run `cwltool --validate` **every** time you execute a
`git commit` including when you may have committed partial changes, causing 
`cwltool` to throw validation errors. You can commit without running the hook
with `git commit --no-verify`.

## Automating deployment to a Seven Bridges Platform with [Github Actions](https://docs.github.com/en/actions)

By following the explanations above, you can develop your CWL locally using git
and have automated validating your workflows. However, we can also automate
deployment to a Seven Bridges Platform. Github Actions is a powerful way to
execute code after pushing to your repository. You can set it up to run programs
on Github's servers according to predetermined rules.

You are welcome to set-up your own Github actions with `sbpack`. In fact, there
is one available created by a developer in the
[INCLUDE Data Coordinating Center](https://github.com/include-dcc). This action
can be found [here](https://github.com/include-dcc/sbpack-action), or in the
[actions marketplace](https://github.com/marketplace/actions/sbpack-push).

The [.github/workflows](https://github.com/rabix/sb-ci/tree/master/.github/workflows)
directory in this repository contains two .yml files. These configure two github
actions to update the two supplied example workflowsupon pushing from your local
machine. These two .yml files also show how the action can be configured to run
only when certain files within your repository are pushed. Reducing unnecessary
executions of the action.

One important point of consideration here is that `sbpack` requires the use of
your Seven Bridges Platform Authentication Token. This token is stored as a
[Github Secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets).
The authentication token is accessed in the configuration .yml files with
`${{ secrets.SBG_AUTH_TOKEN }}` (**Note:** `SBG_AUTH_TOKEN` must match the name
assigned to the secret). After acquiring an authentication token from the
"Developer" tab on a Seven Bridges Platform you can create a Github Secret to
store it by navigating to the "Settings" menu for your repository, clicking on
"Secrets" on the left side of the navigation menu and creating a "New Repository
Secret" with the appropriate button. There you can input your token and it is
encrypted. It will not be printed in any log files, nor can it be retrieved by
other users. Also, keep in mind that these tokens expire after a period of time.

# Testing on the Seven Bridges platform

After running tests locally and using github actions to deploy your tools and
workflows you should run your apps on a SB platform. Since the CWL of your apps
is linked to the platform where you began development, if everything has been
working well so far, your updated versions have now been pushed to your project.

From this point, you should run the app through the Seven Bridges Platform
web-UI, using the API through the [R](https://bioconductor.org/packages/release/bioc/html/sevenbridges.html)
or [Python](https://pypi.org/project/sevenbridges-python/) libraries, or through
the [Seven Bridges command line interface](https://docs.sevenbridges.com/docs/command-line-interface).

When testing on the platform you should use a set of test files that represent
"real" data. In contrast with the micro-sized files which we used for local
validation.
