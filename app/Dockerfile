FROM perl:latest
RUN cpanm Mojolicious
WORKDIR /usr/src/app
COPY app.pl .
CMD ["perl", "app.pl"]
