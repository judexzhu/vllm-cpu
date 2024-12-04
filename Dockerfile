FROM registry.access.redhat.com/ubi9/python-311

USER 0

RUN yum -y update && \
    yum -y clean all && \
    rm -rf /var/cache/yum

USER 1001

RUN pip install --upgrade pip \
    && pip install wheel packaging ninja "setuptools>=49.4.0" numpy

# Fetch the vLLM repo we will build from
WORKDIR /workspace
RUN git clone https://github.com/RHRolun/vllm
WORKDIR /workspace/vllm
RUN git checkout tags/0.1

RUN pip install -v -r requirements-cpu.txt --extra-index-url https://download.pytorch.org/whl/cpu

# Set VLLM_CPU_AVX512BF16=1 if cross-compilation, otherwise remove it
RUN VLLM_TARGET_DEVICE=cpu VLLM_CPU_DISABLE_AVX512=true python3 setup.py install

WORKDIR /workspace/

RUN ln -s /workspace/vllm/tests  && ln -s /workspace/vllm/examples && ln -s /workspace/vllm/benchmarks

EXPOSE 8000

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
