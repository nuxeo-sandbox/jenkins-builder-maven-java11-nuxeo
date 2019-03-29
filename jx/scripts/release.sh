#!/usr/bin/env bash
set -ex

# ensure we're not on a detached head
git checkout master

# until we switch to the new kubernetes / jenkins credential implementation use git credentials store
git config credential.helper store

export VERSION="$(jx-release-version)"
echo "Releasing version to ${VERSION}"

docker build --no-cache -t $DOCKER_REGISTRY/$ORG/$APP_NAME:${VERSION} .
docker push $DOCKER_REGISTRY/$ORG/$APP_NAME:${VERSION}
docker tag $DOCKER_REGISTRY/$ORG/$APP_NAME:${VERSION} $DOCKER_REGISTRY/$ORG/$APP_NAME:latest
docker push $DOCKER_REGISTRY/$ORG/$APP_NAME


#jx step tag --version ${VERSION}
git tag -fa v${VERSION} -m "Release version ${VERSION}"
git push origin v${VERSION}

updatebot push-regex -r "\s+tag: (.*)" -v ${VERSION} --previous-line "\s+repository: ${ORG}/${APP_NAME}" values.yaml
updatebot push-version --kind helm ${ORG}/${APP_NAME} ${VERSION}
updatebot push-version --kind docker ${ORG}/${APP_NAME} ${VERSION}
updatebot update-loop
