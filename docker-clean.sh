#!/bin/bash

BUILD_PROPERTIES_FILE='build.properties'

if [ ! -f "$BUILD_PROPERTIES_FILE" ]
then
	echo "Properties file $BUILD_PROPERTIES_FILE was not found" 1>&2
	exit 1
fi

AZP_AGENT_IMAGE_VERSION=''
DISTRO=''
DISTRO_VERSION=''

while IFS='=' read -r KEY VALUE
do
	if [ ! -z "$KEY" ] && [ ! -z "${KEY:0:1}" ] && [ "${KEY:0:1}" != "#" ]
	then
		if [ "$KEY" == 'AZP_AGENT_IMAGE_VERSION' ]; then
			AZP_AGENT_IMAGE_VERSION=$VALUE
		elif [ "$KEY" == 'DISTRO' ]; then
			DISTRO=$VALUE
		elif [ "$KEY" == 'DISTRO_VERSION' ]; then
			DISTRO_VERSION=$VALUE
		fi
	fi
done < $BUILD_PROPERTIES_FILE

FIRST_ARG=$1

TAG_VERSIONS_BASE=(minimal base dotnet java go cpp haskell)
TAG_VERSIONS=(${TAG_VERSIONS_BASE[@]})

for (( ITERATOR = 2; ITERATOR < ${#TAG_VERSIONS_BASE[@]}; ITERATOR++ ))
do
	BASE_TAG_VERSION=${TAG_VERSIONS_BASE[$ITERATOR]}
	for (( INNER_ITERATOR = $ITERATOR + 1; INNER_ITERATOR < ${#TAG_VERSIONS_BASE[@]}; INNER_ITERATOR++ ))
	do
		BASE_TAG_VERSION+="-${TAG_VERSIONS_BASE[$INNER_ITERATOR]}"
		TAG_VERSIONS+=($BASE_TAG_VERSION)
	done
done

TAG_VERSIONS+=(standard)

if [ -z "$AZP_AGENT_IMAGE_VERSION" ]; then
	echo "AZP_AGENT_IMAGE_VERSION was not set" 1>&2
	exit 1
fi
if [ -z "$DISTRO" ]; then
	echo "DISTRO was not set" 1>&2
	exit 1
fi
if [ -z "$DISTRO_VERSION" ]; then
	echo "DISTRO_VERSION was not set" 1>&2
	exit 1
fi

BUILD_IMAGE='gmaresca/azure-pipeline-agent'

echo "Uploading $BUILD_IMAGE with tag versions [${TAG_VERSIONS[@]}]"

for IMAGE_TAG in ${TAG_VERSIONS[@]}
do
	DEV_IMAGE_TAG="${DISTRO}-${DISTRO_VERSION}-${IMAGE_TAG}-dev"

	FULL_IMAGE_TAG="${DISTRO}-${DISTRO_VERSION}-${IMAGE_TAG}-${AZP_AGENT_IMAGE_VERSION}"
	SHORT_IMAGE_TAG="${DISTRO}-${DISTRO_VERSION}-${IMAGE_TAG}"
	SHORTEST_IMAGE_TAG="${DISTRO}-${IMAGE_TAG}"
	
	if [ -z "$FIRST_ARG" ] || [ "$FIRST_ARG" == "$IMAGE_TAG" ]
	then
		TAGS_TO_RMI=(
			$DEV_IMAGE_TAG
			$FULL_IMAGE_TAG
			$SHORT_IMAGE_TAG
			$SHORTEST_IMAGE_TAG
		)

		if [ "$IMAGE_TAG" == "standard" ]
		then
			TAGS_TO_RMI+=(
				"${DISTRO}-${DISTRO_VERSION}-${AZP_AGENT_IMAGE_VERSION}"
				"${DISTRO}-${DISTRO_VERSION}"
				$DISTRO
				latest
			)
		fi

		echo "Cleaning azp-agent: [${TAGS_TO_RMI[@]}]"

		for TAG_TO_RMI in ${TAGS_TO_RMI[@]}
		do
			if [ -z "$DRY_RUN" ]; then docker rmi "docker.io/${BUILD_IMAGE}:${TAG_TO_RMI}"; fi
		done

		echo "Finished cleaning azp-agent: [${TAGS_TO_RMI[@]}]"
	else
		echo "Not cleaning ${BUILD_IMAGE}:$FULL_IMAGE_TAG - only cleaning $FIRST_ARG"
	fi
done
