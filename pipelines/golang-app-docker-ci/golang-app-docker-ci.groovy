#!/usr/bin/env groovy


/**
 * Jenkins Pipeline example to clone golang sources of the project, run tests inside docker container (go test) and
 * archive docker image (latest Alpine Linux) with app binary as artifacts.
 *
 * Requires jenkins version 2.249.2 or higher and Cloudbees Docker Workflow plugin installed on jenkins master node:
 * https://docs.cloudbees.com/docs/admin-resources/latest/plugins/docker-workflow
 *
 * This Source Code Form is subject to the terms of the BSD 3-Clause License.
 * If a copy of the source distributed without this file, you can obtain one at:
 * https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE
 */


import hudson.model.Result
import groovy.text.StreamingTemplateEngine


/** Pipeline parameters defaults */
final List NodesToExecute = ['domain.com']
final String DefaultGitUrl = 'https://github.com/golang/example.git'
final String DefaultGitProjectPath = 'example/outyet'
final String DefaultPostTestShellCommand = 'curl http://127.0.0.1:80'

/** Dockerfiles templates */
final String DockerFileHeadText = '''\
FROM alpine:latest
EXPOSE 80:8080
'''
// groovylint-disable GStringExpressionWithinString
final String DockerFileTestText = '''\
%s
RUN apk update && apk add --no-cache bash git make musl-dev go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV GOCACHE /go/.cache
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin ${GOPATH}/pkg && chmod -R 0777 /go
ENV PATH /go/bin:$PATH
'''
/** groovylint-disable GStringExpressionWithinString */
final String DockerFileProdTemplate = '''\
$dockerFileHeadText
WORKDIR $workDir
COPY $appBinaryName /usr/bin
RUN apk update && apk add --no-cache ca-certificates && rm -rf /var/cache/apk/* && chmod 775 /usr/bin/$appBinaryName
ENTRYPOINT ["/usr/bin/$appBinaryName"]
'''


node(env.JENKINS_NODE) {
    wrap([$class: 'TimestamperBuildWrapper']) {
        String msgSplit = '-' * 90
        /** Serialize environment variables into map to make check with .containsKey method possible */
        // groovylint-disable-next-line UnnecessaryGetter
        Map envVars = env.getEnvironment().collectEntries { k, v -> [k, v] }
        /** Pipeline parameters injecting and error handling */
        if (!envVars.containsKey('APP_POSTTEST_COMMAND') || !envVars.containsKey('RACE_COVER_TEST_FLAGS') ||
                !envVars.containsKey('JENKINS_NODE') || !envVars.containsKey('GIT_PROJECT_PATH') ||
                !envVars.containsKey('GIT_URL')) {
            properties([
                    parameters(
                            [string(name: 'GIT_URL',
                                    description: 'Git URL of the project to build and test.',
                                    defaultValue: DefaultGitUrl,
                                    trim: true),
                             string(name: 'GIT_PROJECT_PATH',
                                     description: 'Git project inner path.',
                                     defaultValue: DefaultGitProjectPath,
                                     trim: true),
                             choice(name: 'JENKINS_NODE',
                                     description: 'List of possible jenkins nodes to execute.',
                                     choices: NodesToExecute),
                             booleanParam(name: 'RACE_COVER_TEST_FLAGS',
                                     description: String.format('%s%s',
                                             'Enable -race -cover flags for \'go test\' command execution.<br>',
                                             'Allows you to check what happens when test fails.'),
                                     defaultValue: false),
                             text(name: 'APP_POSTTEST_COMMAND',
                                     description: String.format('%s%s%s',
                                             'Post-test shell command to ensure go app is working.<br>',
                                             'On success docker image artifacts will be attached attached. ',
                                             'Leave them empty to skip post-testing.'),
                                     defaultValue: DefaultPostTestShellCommand)]
                    )
            ])
            println "Pipeline parameters was successfully injected. Select 'Build with parameters' and run again."
            // groovylint-disable-next-line UnnecessaryGetter
            currentBuild.build().getExecutor().interrupt(Result.SUCCESS)
            sleep(time: 3, unit: 'SECONDS')
        }
        if (!env.GIT_URL?.trim())
            error 'GIT_URL is not defined. Please set-up and run again.'

        /** Build docker image, clone repo and go test */
        String appBinaryName
        String appTestFlags = (env.RACE_COVER_TEST_FLAGS.toBoolean()) ? '-race -cover' : ''
        if (env.GIT_PROJECT_PATH?.trim()) {
            appBinaryName = env.GIT_PROJECT_PATH.substring(env.GIT_PROJECT_PATH.lastIndexOf('/') + 1)
        } else {
            appBinaryName = env.GIT_URL.substring(env.GIT_URL.lastIndexOf('/') + 1).replace('.git', '')
        }
        dir('test-image') {
            writeFile file: 'Dockerfile', text: String.format(DockerFileTestText, DockerFileHeadText)
        }
        println String.format('%s\nBuilding test container...', msgSplit)
        Object testImage = docker.build(String.format('test-image:%s', env.BUILD_ID), String.format('%s/test-image',
                env.WORKSPACE))
        testImage.inside {
            dir('sources') {
                stage('Download sources') {
                    sh String.format('''rm -rf *; git clone %s; cd %s; ls -lh''', env.GIT_URL, env.GIT_PROJECT_PATH)
                }
                stage('Testing') {
                    if (sh(returnStatus: true, returnStdout: true,
                            script: String.format('set -e; cd %s; ls -lha /go; go test %s',
                                    env.GIT_PROJECT_PATH, appTestFlags)) != 0)
                        error String.format('%s\nTesting failed, other stages will be skiped due of pipeline %s.',
                                msgSplit, 'termination')
                }
                println String.format('%s\nTesting ok, building and creating container with app...', msgSplit)
                stage('Build & stash binary') {
                    dir(env.GIT_PROJECT_PATH) {
                        sh 'go build; ls -lh'
                        stash allowEmpty: false, name: 'bin-stash', includes: appBinaryName
                    }
                }
            }
        }

        /** Build docker container with app */
        dir('prod-image') {
            unstash 'bin-stash'
            Map prodImageDockerfileVariableBinding = [dockerFileHeadText: DockerFileHeadText,
                                                      workDir           : env.WORKSPACE,
                                                      appBinaryName     : appBinaryName]
            String prodImageDockerfileText = new StreamingTemplateEngine().createTemplate(DockerFileProdTemplate)
                    .make(prodImageDockerfileVariableBinding)
            writeFile file: 'Dockerfile', text: prodImageDockerfileText
        }
        println String.format('%s\nBuilding app container...', msgSplit)
        Object prodImage = docker.build(String.format('prod-image:%s', env.BUILD_ID),
                String.format('%s/prod-image', env.WORKSPACE))

        /** Run post-test command to ensure app working and archive artifacts */
        stage('Post-test command & artefacts') {
            prodImage.withRun(String.format('-p 80:8080 --entrypoint /usr/bin/%s', appBinaryName)) { c ->
                println(msgSplit)
                if (env.APP_POSTTEST_COMMAND?.trim())
                    if (sh(returnStatus: true, script: env.APP_POSTTEST_COMMAND) != 0)
                        error String.format('\nPost-test command failed, no artefacts will be returned.', msgSplit)

                println String.format('\nPreparing application and container export...', msgSplit)
                String prodImageIdScript = String.format(
                        "docker ps --format '{{.ID}} {{.Image}}' | grep 'prod-image:%s' | awk '{print \$1}'",
                        env.BUILD_ID)
                String prodImageId = sh(returnStdout: true, script: prodImageIdScript).replace('sha256:', '')
                println String.format('Container ID to export: %s', prodImageId)
                dir('export') {
                    sh String.format('''rm -rf *; docker export --output="container.tar" %s''', prodImageId)
                }
            }
            archiveArtifacts allowEmptyArchive: true, artifacts: String.format('export/*.tar, %s', appBinaryName)
        }
    }
}
