FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Install dependencies and tools
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    unzip \
    python3-venv \
    git && \
    apt-get clean

# Copy the SDK and unzip it
COPY kws /home/kws
COPY start_jupyter.sh /home/start_jupyter.sh
COPY gap_sdk_private.zip /home/gap_sdk_private.zip
RUN unzip /home/gap_sdk_private.zip -d /home && rm -f /home/gap_sdk_private.zip

# Install ubuntu dependencies
WORKDIR /home/gap_sdk_private
RUN cat requirements_apt_ubuntu_22_04.md | xargs apt install -y && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    apt-get clean

# Python Setup and clean up the cloned repository after installation
RUN python -m venv .venv && \
    source .venv/bin/activate && \
    ./install_python_deps.sh && \
    /home/gap_sdk_private/.venv/bin/pip install jupyter numpy==1.26.4 seaborn && \
    rm -rf /root/.cache/pip

# Toolchain Setup
WORKDIR /home
RUN git clone https://github.com/GreenWaves-Technologies/gap_riscv_toolchain_ubuntu.git && \
    cd gap_riscv_toolchain_ubuntu && \
    sed -i 's/sudo //g' install.sh && \
    echo "/usr/lib/gap_riscv_toolchain" | ./install.sh && \
    rm -rf gap_riscv_toolchain_ubuntu

# Build the SDK
WORKDIR /home/gap_sdk_private
RUN source /home/gap_sdk_private/.venv/bin/activate && \
    source configs/gap9_evk_audio.sh && \
    make all -j8

# Enable the GAP_SDK alias. This has to be written into the .bashrc like this, otherwise the alias will not persist
RUN echo "alias GAP_SDK='cd /home/gap_sdk_private && source .venv/bin/activate && source configs/gap9_evk_audio.sh'" >> ~/.bashrc


# Run the jupyter interface
EXPOSE 8888
CMD ["/bin/bash", "/home/start_jupyter.sh"]

