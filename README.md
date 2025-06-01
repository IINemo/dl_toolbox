# DLToolbox

Deep Learning toolbox with PyTorch, Hugging Face Transformers, TRL (Transformer Reinforcement Learning), and Accelerate for efficient model training.

Features:
- Integrated Jupyter Lab and SSH server for flexible development
- CUDA-enabled PyTorch for GPU acceleration
- Full Hugging Face ecosystem support
- Secure SSH access with key authentication
- Configurable user permissions via HOST_UID

## Run

1. Install nvidia-docker: https://github.com/NVIDIA/nvidia-docker

2. Run the command
```
nvidia-docker run -ti  \
    -e "HASHED_PASSWORD=$YOUR_HASHED_PASSWORD" \
    -e "SSL=1" \
    -v <ssl certs>:/home/jovyan/jupyter/certs \
    -v `pwd`:/home/jovyan/workspace \
    -v <.ssh dir>:/home/jovyan/.ssh \
    --shm-size=2048m \
    -p 8888:8888 \
    -p 2222:2222 \
    --name jupyter \
    --memory=30g \
    -e HOST_UID=$(id -u) \
    -d \
    inemo/dl_toolbox:latest
```

User Permission Handling:
Set the HOST_UID environment variable to match your host user ID to ensure proper file ownership. Files created in the container will be owned by your user. 
If HOST_UID is not specified, files will be created with the default user ID (1001). 
If you specify HOST_UID, it takes 15-20 minutes to start due to chaning owner of the conda.

3. Jupyter will be available at ```https://<hostname>:8888/```
4. SSH will be available by ssh key at ```ssh -p 2222 jovyan@<hostname>```

## Pre-built containers:

```
inemo/dl_toolbox:latest
```

## Useful utilities

### 1. Create SSL certificates

Use openssl to generate a self-signed certificate. If you always forget how to do this (like I do), you can use a simple utility: https://github.com/windj007/ssl-utils


### 2. Make a hashed password

Jupyter does not store plain password. It uses a hashed version instead. To make a hashed version of you password, please run:

    $ docker run -ti --rm inemo/dl_toolbox:latest /hashpwd.py
    Enter password: 
    Verify password: 
    <your hashed password>
    $ YOUR_HASHED_PASSWORD="<your hashed password>" # save it to a variable for convenience
