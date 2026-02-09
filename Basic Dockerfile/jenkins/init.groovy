import jenkins.model.*
import hudson.security.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import hudson.util.Secret

def instance = Jenkins.getInstance()

println("=== Starting Jenkins Auto-Configuration ===")

// 1. Configure Security
println("Configuring security...")
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println("✓ Security configured")

// 2. Configure Credentials
println("Configuring credentials...")
def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Docker Registry credentials (basic for insecure registry)
def dockerCreds = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "docker-registry-credentials",
    "Docker Registry Credentials",
    "admin",
    "admin"
)
store.addCredentials(domain, dockerCreds)
println("✓ Docker registry credentials created")

// 3. Disable setup wizard and CLI
try {
    def installStateClass = Class.forName("jenkins.install.InstallState")
    def initialSetup = installStateClass.getField("INITIAL_SETUP_COMPLETED").get(null)
    instance.setInstallState(initialSetup)
    println("✓ Setup wizard disabled")
} catch (Throwable t) {
    println("Warning: Could not set install state: ${t.message}")
}

def cliDescriptor = instance.getDescriptor("jenkins.CLI")
if (cliDescriptor != null) {
    cliDescriptor.get().setEnabled(false)
    println("✓ CLI disabled")
} else {
    println("Warning: CLI descriptor not found")
}

// 4. Set Jenkins URL
def jlc = JenkinsLocationConfiguration.get()
jlc.setUrl("http://jenkins:8080/")
jlc.save()
println("✓ Jenkins URL configured")

// 5. Configure executor count
instance.setNumExecutors(2)
println("✓ Executors configured")

// 6. Create a Pipeline Job
println("Creating a pipeline job...")
try {
    def jobName = "Hello-Captain-Pipeline"
    
    // Check if job already exists
    def existingJob = instance.getItemByFullName(jobName)
    if (existingJob != null) {
        println("Job already exists, skipping creation")
    } else {
        def pipelineJob = instance.createProject(WorkflowJob, jobName)
        
        // Read Jenkinsfile content
        def jenkinsfileContent = """
pipeline {
    agent any
    
    stages {
        stage('Verify Files') {
            steps {
                echo 'Checking workspace...'
                sh 'pwd'
                sh 'ls -la'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t hello-captain /workspace'
            }
        }
        
        stage('Run Docker Container') {
            steps {
                echo 'Running Docker container...'
                sh 'docker run --rm hello-captain'
            }
        }
        
        stage('Cleanup') {
            steps {
                echo 'Cleaning up...'
                sh 'docker rmi hello-captain || true'
            }
        }
    }
    
    post {
        success {
            echo '================================'
            echo 'Pipeline completed successfully!'
            echo 'Check the "Run Docker Container" stage above'
            echo 'You should see: Hello, Captain!'
            echo '================================'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
"""
        
        // Set pipeline script directly
        def pipelineScript = new org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition(jenkinsfileContent, true)
        pipelineJob.setDefinition(pipelineScript)
        
        pipelineJob.save()
        println("✓ Pipeline job '${jobName}' created with inline script")
    }
} catch (Exception e) {
    println("Warning: Could not create pipeline job: ${e.message}")
    e.printStackTrace()
}

// Configure build timestamps
println("Configuring build timestamps...")
def timestamperConfig = instance.getDescriptor("hudson.plugins.timestamper.TimestamperConfig")
if (timestamperConfig != null) {
    timestamperConfig.setAllPipelines(true)
    timestamperConfig.save()
    println("✓ Build timestamps configured")
}

// Save everything
instance.save()

println("=== Jenkins Auto-Configuration Complete ===")
println("Jenkins is ready to use!")
println("URL: http://localhost:8080")
println("Username: admin")
println("Password: admin123")