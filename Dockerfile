FROM alpine:3 AS base

# install git and python
RUN apk update
RUN apk add --no-cache git python3 py3-yarl py3-multidict esh
# create pubobot user + home with no password prompt
RUN adduser pubobot -D

# switch to user pubobot
USER pubobot
WORKDIR /home/pubobot/
RUN git clone https://gitlab.com/mittermichal/PUBobot-discord.git pubobot

# switch to a new build stage we'll discard later
FROM base AS build
USER root
RUN apk add --no-cache py3-pip gcc python3-dev bash
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing gosu
RUN pip3 install --upgrade pip
USER pubobot
WORKDIR /home/pubobot/pubobot/
COPY run.sh .
RUN pip3 install -r requirements.txt
RUN touch database.sqlite3 && touch state.json && echo "{}" > state.json
COPY config.esh .
COPY client_config.esh .

# eventually I want to drop back to base here to clean up
RUN sed -i "/c.ipc = ipc.Server(c, secret_key=client_config.IPC_SECRET)  # create our IPC Server/{s/c,/c, host='0.0.0.0',/}" modules/client.py
# fix permissions
USER root
RUN chmod +x run.sh && chown pubobot:pubobot -R /home/pubobot
#USER pubobot # not running as user so we can recieve signals
ENV IPC_SECRET "5i2jd93j5la9"
ENV DISCORD_TOKEN ""
ENV COMMANDS_URL "https://gitlab.com/mittermichal/PUBobot-discord/-/blob/master/commands.md"
ENV WEB_URL "http://change.me"
EXPOSE 5000
STOPSIGNAL SIGINT
CMD ./run.sh

