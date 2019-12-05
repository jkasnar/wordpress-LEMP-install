pipeline {
  agent {
    node {
      label 'master'
    }

  }
  stages {
    stage('Build') {
      parallel {
        stage('Build') {
          steps {
            sleep 20
          }
        }

        stage('Sleep') {
          steps {
            sleep 30
          }
        }

      }
    }

    stage('Post') {
      steps {
        sh 'echo "Done"'
      }
    }

  }
  environment {
    test = 'test2'
  }
}