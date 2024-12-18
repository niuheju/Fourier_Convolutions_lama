FROM ubuntu:20.04

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 安装证书和相关依赖
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    apt-get upgrade -y && \
    apt-get install -y wget mc tmux nano build-essential rsync libgl1 sudo && \
    rm -rf /var/lib/apt/lists/*

# 使用国内镜像源提高下载速度
RUN sed -i 's|http://archive.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list

# 设置用户与权限
ARG USERNAME=user
RUN addgroup --gid 1000 $USERNAME && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos '' $USERNAME && \
    adduser $USERNAME sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# 设置用户环境变量
USER $USERNAME:$USERNAME
WORKDIR "/home/$USERNAME"
ENV PATH="/home/$USERNAME/miniconda3/bin:/home/$USERNAME/.local/bin:${PATH}"
ENV PYTHONPATH="/home/$USERNAME/project"
ENV TORCH_HOME="/home/$USERNAME/.torch"

# 下载 Miniconda 并安装
RUN wget -O /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh && \
    echo "536817d1b14cb1ada88900f5be51ce0a5e042bae178b5550e62f61e223deae7c /tmp/miniconda.sh" > /tmp/miniconda.sh.sha256 && \
    sha256sum --check /tmp/miniconda.sh.sha256 && \
    bash /tmp/miniconda.sh -bt -p "/home/$USERNAME/miniconda3" && \
    rm /tmp/miniconda.sh && \
    conda build purge && \
    conda init

# 更新 pip 并安装依赖
RUN pip install -U pip && \
    pip install numpy==1.22.4 scipy torch==1.8.1 torchvision opencv-python tensorflow joblib matplotlib pandas \
    albumentations==0.5.2 pytorch-lightning==1.2.9 tabulate easydict==1.9.0 kornia==0.5.0 webdataset \
    packaging gpustat tqdm pyyaml hydra-core==1.3.0 scikit-learn==0.24.2 tabulate && \
    pip install scikit-image>=0.18.0

# 安装兼容的 omegaconf 版本
RUN pip install omegaconf==2.1.1

# 添加 entrypoint 脚本并设置入口
ADD entrypoint.sh /home/$USERNAME/.local/bin/entrypoint.sh
USER root
RUN chmod +x /home/$USERNAME/.local/bin/entrypoint.sh

ENTRYPOINT ["/home/$USERNAME/.local/bin/entrypoint.sh"]
