# Stage 1: Build the NestJS application
FROM node:20-alpine AS build

WORKDIR /usr/src/app

COPY package*.json ./
RUN ls
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Create a minimal production image
FROM node:20-alpine

WORKDIR /usr/src/app

COPY --from=build /usr/src/app/package*.json ./
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist

EXPOSE 3000
CMD [ "node", "dist/main.js" ]