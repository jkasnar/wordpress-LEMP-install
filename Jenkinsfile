pipeline {
  agent {
    node {
      label 'master'
    }

  }
  stages {
    stage('Test') {
      steps {
        sh 'echo "test"'
        mail(subject: 'test', body: 'test', to: 'kasnar@protonmail.com')
      }
    }

  }
}