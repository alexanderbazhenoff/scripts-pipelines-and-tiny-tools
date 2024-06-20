# Dockerized Jenkins CI for Golang app (Jenkins pipeline)

Jenkins Pipeline written on groovy as an example to clone golang sources of the project, run tests inside
docker container and archive the latest Alpine Linux docker image with application binary as artifacts.

## Requirements

1. Jenkins version 2.190.2 or higher.
2. [Linux jenkins node](https://www.jenkins.io/doc/book/installing/linux/) to run pipeline.
3. [Cloudbees Docker Workflow Jenkins plugin](https://docs.cloudbees.com/docs/admin-resources/latest/plugins/docker-workflow).
4. [Install docker](https://docs.docker.com/compose/install/linux/).
5. This pipeline may require groovy methods approve. If you see a message like:
   'Scripts not permitted to use staticMethod ... Administrators can decide whether to approve or reject this signature'
   that means you need to allow them to execute. Navigate to `Jenkins -> Manage Jenkins -> In-process script
   approval`, find a blocked method (the newest one is usually at the bottom) then click 'Approve'. Or refactor this
   pipeline and move all these methods to
   [jenkins share library](https://www.jenkins.io/doc/book/pipeline/shared-libraries/).
6. Internet access on Jenkins node(s) to download docker image and golang project.

## Usage

1. Create jenkins pipeline with 'Pipeline script from SCM', set-up SCM, Branch Specifier as `*/main` and Script Path as
   `golang-app-docker-ci/golang-app-docker-ci.groovy`.
2. Specify defaults for jenkins pipeline parameters in a global variables of pipeline code, or do it later in Jenkins
   GUI after the first pipeline run.
3. Install
   [Cloudbees Docker Workflow Jenkins plugin](https://docs.cloudbees.com/docs/admin-resources/latest/plugins/docker-workflow).
4. [Install docker](https://docs.docker.com/compose/install/linux/) on your jenkins node(s).
5. Add jenkins user to docker group: `usermod -aG docker jenkins`.
6. Make sure you have installed all packages to post-test command execution (**APP_POSTTEST_COMMAND** jenkins
   pipeline parameter).
7. Run pipeline twice. The first run injects jenkins pipeline parameters with your defaults which was specified on
   step 2.

## Pipeline parameters

- **GIT_URL**: Git URL of golang project.
- **GIT_PROJECT_PATH**: Project inner path, e.g. `folder/subfolder/app_name`.
- **JENKINS_NODE**: List of possible jenkins nodes to execute.
- **RACE_COVER_TEST_FLAGS**: Enable `-race` and `-cover` flags for `go test` command execution.
- **APP_POSTTEST_COMMAND**: Post-test shell command to ensure go app is working. On success docker image artifacts will
  be attached. Leave them empty to skip post-testing. E.g: `curl http://127.0.0.1:80` to check web app is up.
