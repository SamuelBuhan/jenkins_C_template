pipeline {
    agent any

    environment {
        BUILD_DIR = 'build'
        CC = 'gcc'
        CFLAGS = '-Wall -Wextra -O2'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup') {
            steps {
                sh 'mkdir -p ${BUILD_DIR}'
            }
        }

        stage('Build') {
            steps {
                sh '''
                    ${CC} ${CFLAGS} -o ${BUILD_DIR}/app src/*.c
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    if [ -d tests ]; then
                        # Exclude main.c so the test binary has its own entry point
                        LIB_SRCS=$(find src -name "*.c" ! -name "main.c")
                        ${CC} ${CFLAGS} -o ${BUILD_DIR}/test_runner tests/*.c ${LIB_SRCS}
                        ./${BUILD_DIR}/test_runner
                    else
                        echo "No tests directory found, skipping tests."
                    fi
                '''
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: "${BUILD_DIR}/**", fingerprint: true
            }
        }
    }

    post {
        always {
            sh 'rm -rf ${BUILD_DIR}'
        }
        success {
            echo 'Build succeeded.'
        }
        failure {
            echo 'Build failed.'
        }
    }
}
