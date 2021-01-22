#!groovy
pipeline { 
    agent any

    options {
       timeout(time: 5, unit: 'MINUTES')  // timeout all agents on pipeline if not complete in 5 minutes or less.

    }

    parameters {
        gitParameter(branchFilter: 'origin/(.*)', defaultValue: 'master', name: 'source_branch', type: 'PT_BRANCH', description: 'Select a branch to build from')
        choice(name: 'target_environment',
            choices: getSFEvnParams(),
            description: 'Select a Salesforce Org to build against')
        booleanParam(name: 'validate_only_deploy',
            defaultValue: true,
            description: 'Check this to run a validate only deploy')
        choice(name: 'test_level',
            choices: 'NoTestRun\nRunSpecifiedTests\nRunLocalTests',
            description: 'Set the Test Level for this Build')
        string(name: 'specified_tests',
            defaultValue: 'ex: ClassTest,Class2Test',
            description: 'If Test Level is "RunSpecifiedTests" then specify a comma seperated list of test classes to run. Ex: "AccountTriggerHandlerTest,LeadTriggerHandlerTest"')
    }
    
    stages {
        stage('Initializing') {
            steps {
                echo "Initializing"
                // determine if the build was trigger from a git event or manually built with parameters
                echo "${currentBuild.buildCauses}"
                // all current build environment variables
                echo sh(returnStdout: true, script: 'env')
            }
        }
        stage('Bitbucket Sync Target Branch') {
            steps {  
                echo "Bitbucket Sync Target Branch"
                bitbucketCheckout()
            }
        }
        stage('SFDX Auth Target Org') {
            steps {
                authSF()
            }
        }
        stage('SFDX Deploy Target Org') {
            steps {  
                echo "Deploy Running ${env.BUILD_ID} on ${env.JENKINS_URL}"
                salesforceDeploy()
            }
        }
    }
}

def salesforceDeploy() {
    
    def varsfdx = tool 'sfdx'
    rc2 = command "${varsfdx}/sfdx force:auth:sfdxurl:store -f authjenkinsci.txt -a targetEnvironment"
    if (rc2 != 0) {
       echo " 'SFDX CLI Authorization to target env has failed.'"
    }

    def TEST_LEVEL='NoTestRun'
    def VALIDATE_ONLY = false
    def deployBranchURL = ""
    if("${env.BRANCH_NAME}".contains("/")) {
        deployBranchURL = "${env.BRANCH_NAME}".replace("/", "_")
    }
    else {
        deployBranchURL = "${env.BRANCH_NAME}"
    }
    def DEPLOYDIR="/var/lib/jenkins/workspace/parambuild_${deployBranchURL}/bitbucket-checkout/force-app/main/default"
    echo DEPLOYDIR
    def SF_INSTANCE_URL = "https://login.salesforce.com"

    dir("${DEPLOYDIR}") {
        if ("${currentBuild.buildCauses}".contains("UserIdCause")) {
            def deploy_script = "force:source:deploy --wait 10"
            if(params.validate_only_deploy) {
                deploy_script += " -c"
            }
            deploy_script += " --sourcepath ${DEPLOYDIR}"
            if("${params.test_level}".contains("RunSpecifiedTests")) {
                deploy_script += " --testlevel ${params.test_level} -r ${params.specified_tests}"
            }
            else {
                deploy_script += " --testlevel ${params.test_level}"
            }
            deploy_script += " -u targetEnvironment --json"

            echo deploy_script
            rc4 = command "${varsfdx}/sfdx " + deploy_script
        }
        else if("${currentBuild.buildCauses}".contains("BranchEventCause")) {
            if (env.CHANGE_ID == null && env.VALIDATE_ONLY == false){
                rc4 = command "${varsfdx}/sfdx force:source:deploy --wait 10 --sourcepath ${DEPLOYDIR} --testlevel ${TEST_LEVEL} -u targetEnvironment --json"         
            }
            else{
                rc4 = command "${varsfdx}/sfdx force:source:deploy --wait 10 --sourcepath ${DEPLOYDIR} --testlevel ${TEST_LEVEL} -u targetEnvironment --json"
            }
        }
 
        if ("$rc4".contains("0")) {
            echo "successful sfdx source deploy from X to X"
        } 
        else {
           currentBuild.result = 'FAILURE'
           echo "$rc4"
        }
    }
}

def authSF() {
    echo 'SF Auth method'
    def SF_AUTH_URL
    echo env.BRANCH_NAME

    if ("${currentBuild.buildCauses}".contains("UserIdCause")) {
        def fields = env.getEnvironment()
        fields.each {
            key, value -> if("${key}".contains("${params.target_environment}")) { SF_AUTH_URL = "${value}"; }
        }
    }
    else if("${currentBuild.buildCauses}".contains("BranchEventCause")) {
        if(env.BRANCH_NAME == 'master' || env.CHANGE_TARGET == 'master') {
            SF_AUTH_URL = env.SFDX_DEV
        }
        else { // {PR} todo - better determine if its a PR env.CHANGE_TARGET?
            SF_AUTH_URL = env.SFDX_DEV
        }
    }

    echo SF_AUTH_URL
    writeFile file: 'authjenkinsci.txt', text: SF_AUTH_URL
    sh 'ls -l authjenkinsci.txt'
    sh 'cat authjenkinsci.txt'
    echo 'end sf auth method'
}

def bitbucketCheckout() {
    dir('bitbucket-checkout') {
        // determine if the build was trigger from a git event or manually built with parameters
        if ("${currentBuild.buildCauses}".contains("UserIdCause")) {
            echo "git checkout ${params.source_branch}"
            // git checkout the branch
            git credentialsId: 'pwId', url:'repoUrl', branch: "${params.source_branch}"
        }
        else if("${currentBuild.buildCauses}".contains("BranchEventCause")) {
            echo "git checkout ${env.BRANCH_NAME}"
            checkout scm
        }
    }

    sh 'ls bitbucket-checkout'
    echo "Current GIT Commit : ${env.GIT_COMMIT}"
    echo "Previous Known Successful GIT Commit : ${env.GIT_PREVIOUS_SUCCESSFUL_COMMIT}"
}


def getSFEvnParams() {
    def fields = env.getEnvironment()
    def output = "";
    fields.each {
        key, value -> if("${key}".startsWith("SFDX_")) { output += "${key}\n"; }
    }
    return output;
}

def command(script) {
   if (isUnix()) {
       return sh(returnStatus: true, script: script);
   } else {
       return bat(returnStatus: true, script: script);
   }
}