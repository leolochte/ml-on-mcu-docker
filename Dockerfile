FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Copy the SDK and toolchain
COPY gap_sdk_private.zip /home/gap_sdk_private.zip
COPY gap_riscv_toolchain_ubuntu.zip /home/gap_riscv_toolchain_ubuntu.zip
RUN apt-get update && \
    apt-get install -y unzip && \
    unzip /home/gap_sdk_private.zip -d /home && \
    unzip /home/gap_riscv_toolchain_ubuntu.zip -d /home && \
    rm -f /home/gap_sdk_private.zip /home/gap_riscv_toolchain_ubuntu.zip

# Install ubuntu dependencies
WORKDIR /home/gap_sdk_private
RUN cat requirements_apt_ubuntu_22_04.md | xargs apt install -y && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# Python Setup
WORKDIR /home/gap_sdk_private
RUN apt-get install -y python3-venv && \
    python -m venv .venv && \
    . .venv/bin/activate && \
    ./install_python_deps.sh

# Toolchain Setup
WORKDIR /home/gap_sdk_private
SHELL ["/bin/bash", "-c"]
RUN . .venv/bin/activate && \
    . configs/gap9_evk_audio.sh && \
    cd ../gap_riscv_toolchain_ubuntu && \
    sed -i 's/sudo //g' install.sh && \
    echo "/usr/lib/gap_riscv_toolchain" | ./install.sh && \
    cd ../gap_sdk_private && \
    make all -j8

# Enable the GAP_SDK alias. This has to be written into the .bashrc like this, otherwise the alias will not persist
WORKDIR /home/gap_sdk_private
SHELL ["/bin/bash", "-c"]
RUN echo "alias GAP_SDK='cd /home/gap_sdk_private && source .venv/bin/activate && source configs/gap9_evk_audio.sh'" >> ~/.bashrc

# Making the (.venv) recognized by jupyter notebooks and downgrade numpy to 1.26.4 since it got upgraded unwanted to 2.0.2
RUN /home/gap_sdk_private/.venv/bin/pip install ipykernel jupyter numpy==1.26.4 seaborn
RUN /home/gap_sdk_private/.venv/bin/python -m ipykernel install --user --name=venv --display-name "(.venv)"

EXPOSE 8888

COPY kws /home/gap_sdk_private/kws
COPY start_jupyter.sh /home/gap_sdk_private/start_jupyter.sh
CMD ["/bin/bash", "/home/gap_sdk_private/start_jupyter.sh"]
