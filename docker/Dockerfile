FROM python:3.7-alpine

LABEL maintainer="Vasilii Angapov <vasilii.angapov@li9.com>"

ENV PATH="/root/.local/bin:$PATH"
ENV PYTHONIOENCODING=UTF-8

RUN apk add --no-cache mariadb-client bash gettext
RUN pip install --upgrade --user awscli

ADD entrypoint.sh schema.sql queries.sql ./

ENTRYPOINT [ "/bin/bash", "./entrypoint.sh" ]
