FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04


ARG NB_USER="jovyan"
ARG NB_UID="1001"
ARG NB_GID="1001"


# ====== ROOT ======
USER root

# Basic libs
RUN apt clean && apt update
RUN apt install -yqq curl wget tmux mc nano
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential locales acl

# Nodejs 
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash && apt install -y nodejs

# UTF-8 locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
        dpkg-reconfigure --frontend=noninteractive locales
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create a nonroot user
RUN userdel -rf ubuntu || true

ENV HOME=/home/$NB_USER
ENV CONDA_DIR=/opt/conda
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
   mkdir -p $CONDA_DIR && \
   chown $NB_USER:$NB_GID $CONDA_DIR && \
   chmod -R 777 /home/$NB_USER && \
   chmod -R 777 $CONDA_DIR && \
   groupadd -g ${NB_GID} ${NB_USER}

# ====== NONROOT ======

USER $NB_UID
WORKDIR /tmp

RUN setfacl -PRdm u::rwx,g::rwx,o::rwx ${CONDA_DIR}
RUN setfacl -PRdm u::rwx,g::rwx,o::rwx ${HOME}

# Install Conda
ENV PATH="$CONDA_DIR/bin:${PATH}"
RUN wget -nv https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \ 
             bash miniconda.sh -f -b -p $CONDA_DIR && \
             rm -f miniconda.sh && \
             conda config --add channels conda-forge && \
             conda init

# Install Python
RUN conda install -c conda-forge python==3.12 xeus-python

# Generaul ML tools
RUN pip install \ 
           numpy scipy pandas scikit-learn \
           ujson line_profiler matplotlib \
           xgboost joblib lxml h5py tqdm lightgbm lime \ 
           scikit-image tensorboardX plotly graphviz seaborn \
           jsonlines pyyaml optuna hydra-core wandb huggingface_hub \
           tables sharedmem

# Basic computation frameworks
RUN pip install torch --index-url https://download.pytorch.org/whl/cu128

# NLP tools
RUN pip install nltk yargy
RUN pip install transformers accelerate datasets evaluate trl
RUN pip install -U pymystem3 # && python -c "import pymystem3 ; pymystem3.Mystem()"

# CV tools
RUN pip install torchvision --index-url https://download.pytorch.org/whl/cu128

# Jupyterlab
RUN pip install jupyterlab  \ 
     jupyter_contrib_nbextensions ipywidgets


# ==== Finalizing Jupyter ====
VOLUME [${HOME}/workspace, "$HOME/jupyter/certs"]
WORKDIR ${HOME}/workspace

COPY --chown=$NB_UID:$NB_UID --chmod=777 test_scripts $HOME/test_scripts
COPY --chown=$NB_UID:$NB_UID --chmod=777 jupyter $HOME/jupyter
RUN chmod -R 777 ${HOME}/jupyter && chmod -R 777 ${HOME}/test_scripts

COPY --chmod=777 entrypoint.sh /entrypoint.sh
COPY --chmod=777 hashpwd.py /hashpwd.py

ENV JUPYTER_CONFIG_DIR="${HOME}/jupyter"
ENV JUPYTER_RUNTIME_DIR="${HOME}/jupyter/run"
ENV JUPYTER_DATA_DIR="${HOME}/jupyter/data"

EXPOSE 8888

ENTRYPOINT ["/entrypoint.sh"]

# ==== Adding SSH service
USER root

# Installing SSH
RUN apt install -y openssh-server 
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd
RUN ssh-keygen -A

VOLUME [$HOME/.ssh]

# Disallow root login, disable pw-auth if you wish
RUN sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config

RUN apt install -y supervisor

COPY --chmod=755 services.conf /etc/supervisor/services.conf
COPY --chmod=755 start_services.sh /start_services.sh

EXPOSE 2222

CMD ["/start_services.sh"]
