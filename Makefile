SHELL=bash

# define names for pom.xml and java packages
pom_gid = io.github.jeffshee
pom_artifactId = openapitest
package_base = ${pom_gid}.${pom_artifactId}
package_api = ${package_base}.api
package_model = ${package_base}.model

RestPortHTTP=8080
UID=1000
GID=1000
JAVA_OPTS=-Duser.home=/var/maven

# api_yaml: API definition
api_yaml=${PWD}/api.yaml

# dirs in host. don't change this.
dir_maven_repo_local=${PWD}/maven-repo-local
dir_codegen=${PWD}/codegen
dir_build=${PWD}/build
dir_impl=${PWD}/override

# docker images to use
codegenBaseImg=openapitools/openapi-generator-cli:v5.2.0
# codegenBaseImg=openapitools/openapi-generator-cli:v5.4.0
mavenImg=maven:3-openjdk-8

# option to codegen
codegenOpt= --group-id ${pom_gid} --artifact-id ${pom_artifactId} \
			--api-package ${package_api} \
			--model-package ${package_model} \
			--import-mappings=DateTime=java.time.LocalDateTime --type-mappings=DateTime=java.time.LocalDateTime \
			--global-property skipFormModel=false

imgTag=openapitest

all:: compile buildImg start

compile:
	mkdir -p .m2
	mkdir -p maven-repo-local
	mkdir -p build
	mkdir -p codegen

# pull docker image
	docker pull ${codegenBaseImg}
	docker pull ${mavenImg}

# genrate codes from open api yaml file
	docker run -it --rm -e TZ="Asia/Tokyo" \
		-u ${UID}:${GID} \
		-v ${api_yaml}:/api.yaml:ro \
		-v ${dir_codegen}:/codegen \
		${codegenBaseImg} generate -g jaxrs-jersey -i /api.yaml -o /codegen ${codegenOpt}
	
# setup files into ${dir_build} for compiling by maven
	cp -p -r ${dir_codegen}/pom.xml ${dir_codegen}/src ${dir_build}/  # copy auto generated files
	cp -p -r ${dir_impl}/* ${dir_build}/  # override  files

# compile by maven
	docker run -it --rm  \
		-u ${UID}:${GID} \
		-v ${PWD}/.m2:/var/maven/.m2 \
		-e MAVEN_CONFIG=/var/maven/.m2 \
		-v ${dir_build}:${dir_build} -w ${dir_build} \
		-v ${dir_maven_repo_local}:${dir_maven_repo_local} -e MAVEN_OPTS="-Dmaven.repo.local=${dir_maven_repo_local} ${JAVA_OPTS}" \
		${mavenImg} mvn package

# download all dependencies before starting container
	docker run -it --rm  \
		-u ${UID}:${GID} \
		-v ${PWD}/.m2:/var/maven/.m2 \
		-e MAVEN_CONFIG=/var/maven/.m2 \
		-v ${dir_build}:${dir_build} -w ${dir_build} \
		-v ${dir_maven_repo_local}:${dir_maven_repo_local} -e MAVEN_OPTS="-Dmaven.repo.local=${dir_maven_repo_local} ${JAVA_OPTS}" \
		${mavenImg} mvn de.qaware.maven:go-offline-maven-plugin:resolve-dependencies

start: ${dir_build}/pom.xml
	mavenImg=${mavenImg} \
	dir_maven_repo_local=${dir_maven_repo_local} \
	containerName=${pom_artifactId} hostName=${pom_artifactId} \
	RestPortHTTP=${RestPortHTTP} \
	dir_build=${dir_build}  \
	docker-compose up -d

stop:
	mavenImg=${mavenImg}  \
	dir_maven_repo_local=${dir_maven_repo_local} \
	dir_build=${dir_build}  \
	RestPortHTTP=${RestPortHTTP} \
	docker-compose down -v

buildImg: ${dir_build}/pom.xml
	docker build -f docker/Dockerfile \
	  --build-arg mavenImg=${mavenImg} \
	  --build-arg dir_top=${PWD} --build-arg dir_build=`basename ${dir_build}` --build-arg dir_maven_repo_local=`basename ${dir_maven_repo_local}` \
	  -t ${pom_artifactId}:${imgTag} ./

clean: stop
	rm -rf build
	rm -rf codegen

cleanAll: clean
	rm -rf .m2
	rm -rf maven-repo-local