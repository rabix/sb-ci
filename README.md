# Continuous integration for CWL using the SB platform

This repository contains links to code examples to show how to setup testing for
your CWL that is automatically triggered and run when you make commits to your
code. This is also known as continuous integration. 

This demonstration assumes you know how the basics of using the [git
versioning system](https://git-scm.com/docs/gittutorial). 

It also assumes some familiarity with
[`cwltool`](https://github.com/common-workflow-language/cwltool). For local
testing you will need `cwltool` installed. 

The main code is found in the following repository:
https://github.com/sevenbridges-openworkflows/uw-genesis-topmed-cwl

A good way to learn the principles outlined below will be to fork the
repository, clone it locally to experiment with running the local tests and then
make commits to test the git hooks, then push the code back to the github repo
to experiment with the actions.

# Testing basics

For each tool and workflow it is important to collect a set of small input
datasets that the CWL can run quickly to check it's operation. Ideally we would
also have a checker script that can analyze the output of the runs and verify
correctness. In the examples given we restrict ourselves to verifying that the
CWL runs without errors.

# Local testing with `cwltool`

Consider the [VCF2GDS
workflow](https://github.com/sevenbridges-openworkflows/uw-genesis-topmed-cwl/blob/master/vcftogds/vcf-to-gds-wf.cwl).
We have collected a small set of [input
data](https://github.com/sevenbridges-openworkflows/uw-genesis-topmed-cwl/tree/master/test-data/vcf).
We create a [job
file](https://github.com/sevenbridges-openworkflows/uw-genesis-topmed-cwl/blob/master/vcftogds/job-vcf-to-gds.yml)
so that we can run the workflow by invoking `cwltool` as follows:

```
cwltool --outdir exec vcf-to-gds-wf.cwl job-vcf-to-gds.yml
```

This command can be used to test the workflow.


# Using git hooks

While we can invoke this command manually each time we make a change, it is more
convenient to invoke this automatically. `git` allows us to do this with the
use of [git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks).

It is convenient to add this as a pre-commit hook to check the workflow before
the code is committed locally.

A pre-commit hook is simply a file with the required commands to run placed in a
file named `pre-commit` placed in the directory `.git/hooks`.

In our case, it simply is the command above.

A thing to note is that this causes a delay during committing the code as the
commands in the `pre-commit` file run.

# Testing with github actions and `cwltool`

github has a feature called [github
actions](https://docs.github.com/en/free-pro-team@latest/actions) that allow
sophisticated continuous integration. These actions run when code is pushed to
the repository on github. 

In our case we create a github action that checks out the code, installs
`cwltool` and then runs it with the job file we created. An example of such an
action file is found
[here](https://github.com/sevenbridges-openworkflows/uw-genesis-topmed-cwl/blob/master/.github/workflows/vcftogds.yml).


# Testing with the SB platform

Now that you are familiar with running tests locally and running tests using
github actions, we will learn how to run automated tests on a SB platform.
