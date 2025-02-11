FROM eclipse-temurin:22

ENV TYPE=real
ENV CASE=2
ENV RND=0

RUN apt-get update && \
	apt-get install -y swi-prolog

WORKDIR /app

COPY . /app
	
CMD java -jar dred-mark-eval-0.1.0.jar $TYPE $CASE $RND
