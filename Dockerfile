# VERSION 1.10.3
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:2.7-slim

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.4
ARG AIRFLOW_HOME=/usr/local/airflow/
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_GPL_UNIDECODE yes

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

COPY . ./airflow_src

RUN set -ex \
    && buildDeps=' \
           freetds-dev \
           libkrb5-dev \
           libsasl2-dev \
           libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
           nodejs \
        npm \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        unixodbc-dev \
        unixodbc-bin \
        unixodbc \
        awscli \
        git \
        nodejs \
        npm \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install pyodbc \
    && pip install hvac \
    && pip install selenium \
    && pip install flask_oidc \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && pip install --extra-index-url http://bos-rndapp02.acadian-asset.com:8080/artifactory/pybuild-snapshot/ \
        --trusted-host bos-rndapp02.acadian-asset.com util-aam \
    && pip install redis -I \
    && pip install Flask==1.1.1
    RUN ls airflow_src
RUN pip install ./airflow_src[s3,crypto,celery,postgres,hive,jdbc,mysql,ssh] \
    && cd airflow_src \
    && ./airflow/www_rbac/compile_assets.sh \
    && cd .. \
    && pip install marshmallow-sqlalchemy==0.18.0 \
    && apt-get purge --auto-remove -yqq $buildDeps \
        && apt-get autoremove -yqq --purge \
        && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY ./scripts/docker/entrypoint.sh /entrypoint.sh
# COPY ./.cacerts /.cacerts/

RUN mkdir ${AIRFLOW_HOME}/airflow
RUN chown -R airflow: ${AIRFLOW_HOME}
# RUN chown -R airflow: /.cacerts

RUN ["chmod", "+x", "/entrypoint.sh"]

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint
