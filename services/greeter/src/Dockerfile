FROM node:16 AS build
WORKDIR /srv
COPY package.json .
RUN npm install

FROM node:16-slim
RUN apt-get update && apt-get install curl -y
COPY --from=build /srv .
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
#checkov:skip=CKV_DOCKER_2:healthcheck via ECS
#checkov:skip=CKV_DOCKER_3:non-root user via ECS