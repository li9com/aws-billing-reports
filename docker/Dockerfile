FROM python:3.7-alpine

LABEL maintainer="Vasilii Angapov <vasilii.angapov@li9.com>"

ENV PATH="/root/.local/bin:$PATH"
ENV PYTHONIOENCODING=UTF-8

RUN apk add --no-cache mariadb-client bash gettext &&\
    apk add --virtual=build gcc make libffi-dev musl-dev openssl-dev && \
    pip install --upgrade --user azure-cli awscli &&\
    apk del --purge build

ADD entrypoint.sh *.sql ./

ENTRYPOINT [ "/bin/bash", "./entrypoint.sh" ]
