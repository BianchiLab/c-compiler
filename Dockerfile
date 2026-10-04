FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# Basic environment
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        apt-utils \
        curl \
        wget \
        git \
        vim \
        nano \
        less \
        file \
        unzip \
        zip \
        xz-utils \
        bzip2 \
        tar \
        sudo \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# C / C++ development
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        gcc \
        g++ \
        make \
        cmake \
        ninja-build \
        pkg-config \
        autoconf \
        automake \
        libtool \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# Binary / ELF inspection
#
# readelf and objdump are provided by binutils.
# They are NOT separate Ubuntu packages.
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        binutils \
        binutils-multiarch \
        elfutils \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# LLVM / Clang
#
# Useful for:
#   - comparing compiler output
#   - generating LLVM IR
#   - clang-based experiments
#   - alternative assembler/linker tools
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        clang \
        llvm \
        lld \
        llvm-runtime \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# Debugging / runtime analysis
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        gdb \
        gdb-multiarch \
        valgrind \
        strace \
        ltrace \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# Static analysis / code quality
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        cppcheck \
        shellcheck \
        clang-format \
        clang-tidy \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# Lexer / parser development tools
#
# Flex  = lexer generator
# Bison = parser generator
# M4    = macro processor used by various build/parser tools
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        flex \
        bison \
        m4 \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# Python
#
# Useful for:
#   - test harnesses
#   - compiler tests
#   - scripts
#   - automated regression testing
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-pytest \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# OCaml development environment
#
# This is intentionally kept simple.
#
# Ubuntu 24.04 package names:
#
#   ocaml
#   ocaml-interp
#   ocaml-compiler-libs
#   ocaml-findlib
#   opam
#   ocaml-dune
#   menhir
#
# NOTE:
# Ubuntu 24.04 uses "ocaml-dune", NOT "dune".
#
# Zarith and OUnit are useful libraries for compiler projects.
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        ocaml \
        ocaml-interp \
        ocaml-compiler-libs \
        ocaml-findlib \
        opam \
        ocaml-dune \
        menhir \
        libzarith-ocaml-dev \
        libounit-ocaml-dev \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# Display versions during image build
#
# This makes it immediately obvious in the build log that
# the important compiler-development tools are installed.
# ============================================================

RUN echo "===== Compiler versions =====" && \
    gcc --version | head -n 1 && \
    clang --version | head -n 1 && \
    echo && \
    echo "===== OCaml =====" && \
    ocaml -version && \
    echo "===== Dune =====" && \
    dune --version && \
    echo "===== Menhir =====" && \
    menhir --version && \
    echo && \
    echo "===== Binutils =====" && \
    objdump --version | head -n 1 && \
    readelf --version | head -n 1 && \
    echo && \
    echo "===== GDB =====" && \
    gdb --version | head -n 1


# ============================================================
# Convenience wrappers
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'exec gcc -m64 "$@"' \
    > /usr/local/bin/x86-64-gcc && \
    chmod +x /usr/local/bin/x86-64-gcc


RUN printf '%s\n' \
    '#!/bin/bash' \
    'exec clang --target=x86_64-linux-gnu "$@"' \
    > /usr/local/bin/x86-64-clang && \
    chmod +x /usr/local/bin/x86-64-clang


# ============================================================
# Assembly / binary inspection helpers
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'echo "=== Architecture ==="' \
    'uname -m' \
    'echo' \
    'echo "=== GCC target ==="' \
    'gcc -dumpmachine' \
    'echo' \
    'echo "=== Clang target ==="' \
    'clang -print-target-triple' \
    'echo' \
    'echo "=== GNU assembler ==="' \
    'as --version | head -n 1' \
    'echo' \
    'echo "=== GNU linker ==="' \
    'ld --version | head -n 1' \
    'echo' \
    'echo "=== objdump ==="' \
    'objdump --version | head -n 1' \
    'echo' \
    'echo "=== readelf ==="' \
    'readelf --version | head -n 1' \
    > /usr/local/bin/asm-info && \
    chmod +x /usr/local/bin/asm-info


RUN printf '%s\n' \
    '#!/bin/bash' \
    'if [ "$#" -eq 0 ]; then' \
    '    echo "Usage: show-asm <source.c> [gcc options...]"' \
    '    exit 1' \
    'fi' \
    'SOURCE="$1"' \
    'shift' \
    'gcc -S -O0 -fno-asynchronous-unwind-tables "$SOURCE" "$@" -o -' \
    > /usr/local/bin/show-asm && \
    chmod +x /usr/local/bin/show-asm


RUN printf '%s\n' \
    '#!/bin/bash' \
    'if [ "$#" -eq 0 ]; then' \
    '    echo "Usage: disasm <binary>"' \
    '    exit 1' \
    'fi' \
    'objdump -d -Mintel "$1"' \
    > /usr/local/bin/disasm && \
    chmod +x /usr/local/bin/disasm


# ============================================================
# Workspace
#
# The host directory is mounted here by enter-container.sh.
# ============================================================

RUN mkdir -p /workspace

WORKDIR /workspace


# ============================================================
# Shell configuration
# ============================================================

RUN printf '%s\n' \
    'export PS1="\[\e[1;32m\][writing-c-compiler]\[\e[0m\] \w \$ "' \
    'alias ll="ls -alF"' \
    'alias la="ls -A"' \
    'alias l="ls -CF"' \
    > /root/.bashrc


# ============================================================
# Default command
# ============================================================

CMD ["/bin/bash"]