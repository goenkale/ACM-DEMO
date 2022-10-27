@Library('github.com/bonitasoft-presales/bonita-jenkins-library@1.0.1') _

def bonitaVersion = "7.14.0"
def bonitaVersionShortened = "7140"
def nodeName = "bcd-${bonitaVersionShortened}"

node("${nodeName}") {
  
	def scenarioFile = "/home/bonita/bonita-continuous-delivery/scenarios/scenario-ACM-ec2.yml"
  	def bonitaConfiguration = "Qualification"
  
  	// used to archive artifacts
  	def jobBaseName = "${env.JOB_NAME}".split('/').last()

  	// used to set build description and bcd_stack_id
  	def gitRepoName = "${env.JOB_NAME}".split('/')[1]
  	def normalizedGitRepoName = gitRepoName.toLowerCase().replaceAll('-','_')

  	// used to set bcd_stack_id
  	def branchName = env.BRANCH_NAME
  	def normalizedBranchName = branchName.toLowerCase().replaceAll('-','_')
  
  	//bcd_stack_id overrides scenario value
  	//will deploy all PR on same server
	def stackName = "${normalizedGitRepoName}_${normalizedBranchName}_${bonitaVersionShortened}" 
  
  	// set to true/false if bonitaConfiguration requires a .bconf file
  	// e.g. configuration has parameters
  	def useBConf = false

	  // set to true/false to switch verbose mode
	  def debugMode = false    
	  def debug_flag = ''
	  def verbose_mode = ''
	  if ("${debugMode}".toBoolean()) {
	    debug_flag = '-X'
	    verbose_mode='-v'
	  }
  	
      // used in steps, do not change
    def yamlFile = "${WORKSPACE}/props.yaml"
    def bconfFolder = '/home/bonita/bonita-continuous-delivery/bconf'
    def yamlStackProps
    def privateDnsName
    def privateIpAddress
    def bonitaAwsVersion = '1.0-SNAPSHOT'
    def keyFileName = '~/.ssh/presale-ci-eu-west-1.pem'
    def deployScenarioFile
    def extraVars="--extra-vars bcd_stack_id=${stackName} --extra-vars bonita_version=${bonitaVersion}"

	ansiColor('xterm') {
 		timestamps {
			stage("Checkout") {
				checkout scm
				echo "jobBaseName: $jobBaseName"
				echo "gitRepoName: $gitRepoName"
			}
             
             stage("Create stack") {
                sh """
cd ~/ansible/aws
java -jar bonita-aws-${bonitaAwsVersion}-jar-with-dependencies.jar -c create --stack-id ${stackName} --name ${normalizedGitRepoName} --key-file ${keyFileName}
cp ${stackName}.yaml ${WORKSPACE}
"""
                yamlStackProps = readYaml file: "${WORKSPACE}/${stackName}.yaml"
                privateDnsName = yamlStackProps.privateDnsName
                privateIpAddress = yamlStackProps.privateIpAddress
                echo "privateDnsName: [${privateDnsName}]"
                echo "privateIpAddress: [${privateIpAddress}]"
            }
            		    
	     	stage("Build LAs") {
				bcd scenario:scenarioFile, args: "${extraVars} livingapp build ${debug_flag} -p ${WORKSPACE} --environment ${bonitaConfiguration}"
		    }


            stage("clean SSH known hosts records"){
                // ensure private ip/dns name is removed from known hosts since AWS reuse IPs
                // keep this stage after build, to ensure SSHd is up & running on created stack
                sh """
ssh-keygen -R ${privateDnsName}
ssh-keygen -R ${privateIpAddress}
ssh -o StrictHostKeyChecking=no -i ~/.ssh/presale-ci-eu-west-1.pem  ubuntu@${privateDnsName} ls
ssh -o StrictHostKeyChecking=no -i ~/.ssh/presale-ci-eu-west-1.pem  ubuntu@${privateIpAddress} ls
"""     
            }
            
		    
            stage("Deploy server") {
                sh """
cd ~/ansible
ansible-playbook bonita-7140.yaml -i aws/private-inventory-${stackName}.yaml
"""
                def bonitaUrl = "http://${yamlStackProps.publicDnsName}:8081/bonita/login.jsp"
                currentBuild.description = "<a href='${bonitaUrl}'>${stackName}</a>"
            }            

             stage('Create yml parameter file') {
                echo "yamlFile properties set to: ${yamlFile}"
                if( fileExists(yamlFile)) {
                    echo "remove existing file ${yamlFile}"
                    sh "rm $yamlFile"
                }
                def yamlProps = [:]
                yamlProps.global_parameters=[ [ name:'serverUrl',type:'String',value:"http://${yamlStackProps}:8081/bonita"]]
                writeYaml file:yamlFile, data:yamlProps
            }

	
			def zip_files = findFiles(glob: "target/*_${jobBaseName}-${bonitaConfiguration}-*.zip")
        	def bconf_files = findFiles(glob: "target/*_${jobBaseName}-${bonitaConfiguration}-*.bconf")
        	def bConfArg = ""
        	if(bconf_files && bconf_files[0].length > 0){
	            stage('Configure GMAIL email parameters') {
	                def mergeBonitaArgs = extraVars
	                def inputBConf = "${WORKSPACE}/${bconf_files[0].path}"
	                def ouputBConf = "${bconfFolder}/${stackName}-${bonitaConfiguration}-merged.bconf"
	                def yamlInput  = "${bconfFolder}/email-${bonitaConfiguration}.yml"
	                
	                mergeBonitaArgs += " livingapp merge-conf "
	                mergeBonitaArgs += " -p ${inputBConf} "
	                mergeBonitaArgs += " -i ${yamlInput}" 
	                mergeBonitaArgs += " -o ${ouputBConf}"
	
	                bcd scenario:scenarioFile, args: mergeBonitaArgs
	                
	                bConfArg = "-c ${ouputBConf}"
	            }
	            
	            stage('Configure GMAIL imap parameters') {
	            	def mergeBonitaArgs = extraVars
	                def inputBConf = "${bconfFolder}/${stackName}-${bonitaConfiguration}-merged.bconf"
	                def ouputBConf = "${bconfFolder}/${stackName}-${bonitaConfiguration}-merged2.bconf"
	                def yamlInput  = "${bconfFolder}/imap-${bonitaConfiguration}.yml"
	                
	                mergeBonitaArgs += " livingapp merge-conf "
	                mergeBonitaArgs += " -p ${inputBConf} "
	                mergeBonitaArgs += " -i ${yamlInput}" 
	                mergeBonitaArgs += " -o ${ouputBConf}"
	
	                bcd scenario:scenarioFile, args: mergeBonitaArgs
	            
	                bConfArg = "-c ${ouputBConf}"
	            }
	            
	             stage('Configure serverUrl') {
	             	def mergeBonitaArgs = extraVars
	                def inputBConf = "${bconfFolder}/${stackName}-${bonitaConfiguration}-merged2.bconf"
	                def ouputBConf = "${bconfFolder}/${stackName}-${bonitaConfiguration}-merged3.bconf"
	                def yamlInput  = "${yamlFile}"
	                
	                mergeBonitaArgs += " livingapp merge-conf "
	                mergeBonitaArgs += " -p ${inputBConf} "
	                mergeBonitaArgs += " -i ${yamlInput}" 
	                mergeBonitaArgs += " -o ${ouputBConf}"
	
	                bcd scenario:scenarioFile, args: mergeBonitaArgs
	            
	                bConfArg = "-c ${ouputBConf}"
	            }
	        }
	
	     	stage('Deploy LAs') {
                // workaround for https://bonitasoft.atlassian.net/browse/BCD-559
                deployScenarioFile="${WORKSPACE}/deployScenario.yml"
                echo "deployScenarioFile set to: ${deployScenarioFile}"
                if( fileExists(deployScenarioFile)) {
                    echo "remove existing file ${deployScenarioFile}"
                    sh "rm $deployScenarioFile"
                }
                yamlDeployProps=[
                	bonita_url:"http://${yamlStackProps.privateDnsName}:8081/bonita",
                	bonita_technical_username:'install',
                	bonita_technical_password:'install']
                
                echo "yamlDeployProps set to: ${yamlDeployProps}"
                writeYaml file:deployScenarioFile, data:yamlDeployProps
                bcd scenario:deployScenarioFile, args: "${extraVars} livingapp deploy ${debug_flag} -p ${WORKSPACE}/${zip_files[0].path} ${bConfArg} --development-mode"
		    }
	
	     	stage('Archive') {
	      		archiveArtifacts artifacts: "target/*.zip, target/*.bconf, target/*.xml, target/*.bar", fingerprint: true, flatten:true
	  	 	}   
  		} // timestamps
  	} // ansiColor
} // node