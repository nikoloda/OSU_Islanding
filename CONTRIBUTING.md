# Contributing Guide

Done code is fully commented, concise, well organized, has a detailed commit message, and correctly updates the JIRA board

## Code of Conduct

Update the Jira board whenever the status changes so that the status is always up to date.

## Getting Started

To run app locally, clone the repo, then open the terminal and run Julia, then using IJulia run notebook(). From here, navigate to the repo and run the code in the notebook form.

## Branching & Workflow

Select a task from Jira, create branch with the name and id of the ticket, push and create a pull request when ready to merge. If necessary,
a rebase can be made (might be needed if working on several tickets at the same time)

## Issues & Planning

Issues are to be filed with an Jira ticket (Bug vs story) with a story points estimation. 

## Commit Messages

Commit messages directly correspond to the changes made and are detailed enough for someone who did not work on the code to understand the changes. The name of the branch should begin with the JIRA id and share the same title.


## Code Style, Linting & Formatting

Keep functions, case files, and documentation in seperate directories.

Use Julia.lint.run on Jupyter Notebook to use the Julia linter on Jupyter Notebook.

## Testing

In the future, a test will be created to validate the ability of a function to run against the Poland Matpower case.

We will have to consult with Dr.ECS as to what would be a good test set for the github action

## Pull Requests & Reviews

PR requirements: A well documented description of the code and titled with the Jira ticket which it corresponds to 

Currently, approval is not needed to commit, if more members are added, a new rule should be created.

## CI/CD

A blank CI/CD pipeline has been created, tests are to be created and ran on Pull Request towards the main branch. All tests must pass
before the merge is permitted.

We will create tests which import a case file and test if our functions provide a reasonable output.

## Security & Secrets

Reoports and vulnerabilities are to be communicated by email or during our meetings, alongside the creation of a Jira ticket which corresponds to the issue.

## Documentation Expectations

Comments should be concise and live on the line above the code they reference. 

All imported libraries should be at the top of the file where they are located.

Update Jira tickets to correspond to the task's status.

The README should be updated large structural changes are made 

## Release Process

No commits should be directly pushed onto main, branch protection is established to ensure that a new branch must be made and merged onto main.

Since we are using GitHub, we can rollback if necessary. This should be utilised if something was mistakenly commited to main, although branch protection should prevent this. 

## Support & Contact

Daniel Nikolov -  Primary Undergraduate Researcher 
Cotact nikoloda@oregonstate.edu and expect a response within 24 hours
