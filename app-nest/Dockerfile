FROM node:16.20-alpine As codebase
USER node
WORKDIR /home/node
COPY --chown=node:node package.json ./
RUN yarn
COPY --chown=node:node . .

USER root
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]

USER node
WORKDIR /home/node
FROM node:16.20-alpine As production
COPY --chown=node:node --from=codebase /home/node/package.json ./package.json
COPY --chown=node:node --from=codebase /home/node/node_modules ./node_modules
COPY --chown=node:node . .
RUN yarn build
EXPOSE 3000
CMD ["node", "dist/main.js"]
