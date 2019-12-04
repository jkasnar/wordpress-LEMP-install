pipeline {
  agent {
    node {
      label 'master'
    }

  }
  stages {
    stage('Test') {
      parallel {
        stage('Test') {
          steps {
            sh 'echo "test"'
          }
        }

        stage('Test2') {
          steps {
            sh 'echo "Parallel echo"'
          }
        }

      }
    }

  }
}