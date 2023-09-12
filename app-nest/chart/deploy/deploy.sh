source $1

# Clean-up of volumes / containers
docker container prune -f 
docker volume prune -f

# Function to pull a docker image and deploy the container.
DeployDockerContainer()
{
  image=$1
  tempVolumeName=$2
  mountFolder=$3
  instanceName=$4
  configFileName=$5
  exitCode=0

  # Pull the docker image first, if we don't octopus treats pulling the new image as an error
  docker pull $image || { echo "[DEPLOY.SH] Unable to pull docker image"; exit 1; }
  
  # chown the mount folder so we have write permissions in the container
  chown 1001:1001 $mountFolder

  # Create a volume to pass in a mounted drive
  docker volume create --driver local --name $tempVolumeName --opt type=none --opt device=$mountFolder --opt o=uid=pwsh,gid=pwsh --opt o=bind \
  || { echo "[DEPLOY.SH] Unable to create terraform volume"; exitCode=1; }
  
  # Run the deploy container, the config file will be passed as an environment file to docker
  docker run \
    --name "$instanceName" \
      --rm \
      -v $tempVolumeName:/home/pwsh/tempVolume \
      --env-file $configFileName \
      -e optionalArg=$optionalArg \
      "$image" || { echo "[DEPLOY.SH] docker run exited with a non-zero exit code"; \
                    exitCode=1; }

  # Remove container if it still exists
  RemoveContainer $instanceName

  # Removes the volume
  RemoveVolume $tempVolumeName

  return $exitCode
}

# Function to remove volumes
RemoveVolume()
{
  VolumeName=$1
  if [[ `docker volume ls -f "name=$VolumeName"` =~ "$VolumeName" ]]
  then
      docker volume rm $VolumeName -f || { echo "[DEPLOY.SH] Unable to force delete volume"; exit 1; }
  fi
}

# Function to remove container
RemoveContainer()
{
  ContainerName=$1
  if [[ `docker ps -a -f "name=$ContainerName"` =~ "$ContainerName" ]]
  then
      docker rm $ContainerName -f || { echo "[DEPLOY.SH] Unable to force delete container"; exit 1; }
  fi
}

configFileName=$1

if [ ! -z "$2" ] 
then
    optionalArg=$2
    echo "[DEPLOY.SH] Additional argument supplied to deploy.sh: "$optionalArg". This will be passed to docker run as -e optionalArg=$optionalArg"
fi

parentFolderName="$(basename "$(dirname `pwd`)")"

image="$docker_registry/$imageName:$imageTag"
instanceName="deploy_${namespace}_${projectName}_${deployVersion}"
tempVolumeName="volume_${namespace}_${projectName}_${deployVersion}"

# If we're in a deploy folder, we want to mount the parent folder else we want to mount the current
# Difference is that if a package only has deploy files there's no parent folder or deploy directory
if [ "$parentFolderName" = "chart" ]; then
  mountFolder=$(dirname `pwd`)
else
  mountFolder=`pwd`
fi

echo $arm_client_secret | docker login "$docker_registry" -u "$arm_client_id" --password-stdin || { echo "[DEPLOY.SH] Unable to login to docker"; exit 1; }

DeployDockerContainer $image $tempVolumeName $mountFolder $instanceName $configFileName
deployExitCode=$?

if [ "$deployExitCode" -ne 0 ]
then
  exit $deployExitCode
fi

# Automated Testing
if [[ ! -z $enable_tests && "$enable_tests" == "true" ]];
then
  if [[ -z $tests_dir ]];
  then
    echo "No automated tests found for $projectName"
  else
    echo "Automated tests found in $projectName/$tests_dir"
    if [ "$parentFolderName" = "chart" ]; then
      testMountFolder=$(dirname $(dirname `pwd`))/$tests_dir
    else
      testMountFolder=$(dirname `pwd`)/$tests_dir
    fi
    
    testsImage="$docker_registry/$tests_image_name:$tests_image_tag"
    testsInstanceName="deploy_${namespace}_${projectName}_tests_${deployVersion}"
    testsTempVolumeName="volume_${namespace}_${projectName}_tests_${deployVersion}"
    
    DeployDockerContainer $testsImage $testsTempVolumeName $testMountFolder $testsInstanceName $configFileName
    testExitCode=$?

    new_octopusartifact $testMountFolder/log.html
    new_octopusartifact $testMountFolder/output.xml
    new_octopusartifact $testMountFolder/report.html

    if [ "$testExitCode" -ne 0 ]
    then
      exit $testExitCode
    fi
  fi
else
  echo "Automated tests not enabled for $projectName in this environment."
fi
