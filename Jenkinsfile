#!groovy

node {

       load "$JENKINS_HOME/jobvars.env"

       dir('src/github.com/reportportal/service-index') {

           stage('Checkout'){
                checkout scm
                sh 'git checkout master'
                sh 'git pull'
            }

            stage('Build') {
                 sh 'echo $USER'
                 // Export environment variables pointing to the directory where Go was installed
                 docker.image('golang:1.10.2').inside("-u root -e GOPATH=${env.WORKSPACE}")  {
                        sh 'PATH=$PATH:$GOPATH/bin && make build v=`cat VERSION`-$BUILD_NUMBER'
                 }
                 archiveArtifacts artifacts: 'bin/*'
            }

           withEnv(["IMAGE_POSTFIX=-dev"]) {
                 docker.withServer("$DOCKER_HOST") {
                                  stage('Build Docker Image') {
                                          sh 'make build-image'
                                  }

                                  stage('Deploy container') {
                                          sh "docker-compose -p reportportal -f $COMPOSE_FILE up -d --force-recreate index"
                                  }
                 }
           }



        }
}

