FROM ubuntu:bionic

LABEL maintainer="RStudio Docker <docker@rstudio.com>"

# Set versions and platforms
ARG R_VERSION=4.1.0
ARG MINICONDA_VERSION=py37_4.8.3
ARG PYTHON_VERSION=3.9.5
ARG DRIVERS_VERSION=2021.10.0
ARG DEBIAN_FRONTEND=noninteractive

# Install RStudio Workbench session components -------------------------------#

RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    dpkg-sig \
    wget \
    krb5-user \
    libcurl4-gnutls-dev \
    libssl1.0.0 \
    libssl-dev \
    libuser \
    libuser1-dev \
    libpq-dev \
    rrdtool && \
    rm -rf /var/lib/apt/lists/*

ARG RSW_VERSION=2022.07.2+576.pro12
ARG RSW_NAME=rstudio-workbench
ARG RSW_DOWNLOAD_URL=https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update --fix-missing \
    && apt-get install --no-install-recommends -y gdebi-core \
    && RSW_VERSION_URL=$(echo -n "${RSW_VERSION}" | sed 's/+/-/g') \
    && curl -o rstudio-workbench.deb "${RSW_DOWNLOAD_URL}/${RSW_NAME}-${RSW_VERSION_URL}-amd64.deb" \
    && gpg --keyserver keyserver.ubuntu.com --recv-keys 3F32EE77E331692F \
    && dpkg-sig --verify rstudio-workbench.deb \
    && gdebi --non-interactive rstudio-workbench.deb \
    && rm rstudio-workbench.deb \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/rstudio-server/r-versions

EXPOSE 8788/tcp

# Install additional system packages ------------------------------------------#

# RUN apt-get update -y && \
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    git \
    libssl1.0.0 \
    libuser \
    libxml2-dev \
    subversion && \
    rm -rf /var/lib/apt/lists/*

# Install R -------------------------------------------------------------------#

RUN curl -O https://cdn.rstudio.com/r/ubuntu-1804/pkgs/r-${R_VERSION}_1_amd64.deb && \
    apt-get update && \
    gdebi --non-interactive r-${R_VERSION}_1_amd64.deb && \
    rm -rf r-${R_VERSION}_1_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R && \
    ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# Install Python --------------------------------------------------------------#

RUN curl -O https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh && \
    bash Miniconda3-4.7.12.1-Linux-x86_64.sh -bp /opt/python/${PYTHON_VERSION} && \
    /opt/python/${PYTHON_VERSION}/bin/conda install -y python==${PYTHON_VERSION} && \
    rm -rf Miniconda3-*-Linux-x86_64.sh

ENV PATH="/opt/python/${PYTHON_VERSION}/bin:${PATH}"

# Install Jupyter Notebook and RSW/RSC Notebook Extensions and Packages -------#

RUN /opt/python/${PYTHON_VERSION}/bin/pip install \
    jupyter \
    jupyterlab \
    workbench_jupyterlab \
    rsp_jupyter \
    rsconnect_jupyter \
    rsconnect_python && \
    ln -s /opt/python/${PYTHON_VERSION}/bin/jupyter /usr/local/bin/jupyter

RUN /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsp_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsp_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsconnect_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsconnect_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-serverextension enable --sys-prefix --py rsconnect_jupyter

# Install VSCode code-server, extensions, etc. --------------------------------------------------#

RUN rstudio-server install-vs-code /opt/code-server/ && \
    ln -s /opt/code-server/bin/code-server /usr/local/bin/code-server

COPY vscode.extensions.conf /etc/rstudio/vscode.extensions.conf

# Install RStudio Professional Drivers ----------------------------------------#

RUN apt-get update -y && \
    apt-get install --no-install-recommends -y unixodbc unixodbc-dev gdebi && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://cdn.rstudio.com/drivers/7C152C12/installer/rstudio-drivers_${DRIVERS_VERSION}_amd64.deb && \
    apt-get update && \
    gdebi --non-interactive rstudio-drivers_${DRIVERS_VERSION}_amd64.deb && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f rstudio-drivers_${DRIVERS_VERSION}_amd64.deb && \
    cp /opt/rstudio-drivers/odbcinst.ini.sample /etc/odbcinst.ini

RUN /opt/R/${R_VERSION}/bin/R -e 'install.packages("odbc", repos="https://packagemanager.rstudio.com/cran/__linux__/bionic/latest")'

# Locale configuration --------------------------------------------------------#

RUN apt-get update -y && \
    apt-get install --no-install-recommends -y locales && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Gurobi and Julia ----------------------------------------------------#

USER root

COPY --chown=$NB_UID:$NB_GID docker-images/posit/assets/saml2aws.profile $HOME/.saml2aws
COPY docker-images/posit/assets/vistra-image.sh /vistra_image.sh

RUN apt update && apt upgrade -y && \
    bash /vistra_image.sh && \
    rm /vistra_image.sh

USER $NB_UID

