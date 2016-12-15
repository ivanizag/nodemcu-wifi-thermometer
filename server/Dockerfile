FROM node:argon

RUN mkdir /app
WORKDIR /app
COPY . /app
RUN npm install

EXPOSE 23322
CMD ["npm", "start"]
