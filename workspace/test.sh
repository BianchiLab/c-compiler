#!/usr/bin/env bash
# test_environment.sh — run INSIDE the writing-c-compiler container.
#
# IMPORTANT CAVEAT (read before trusting a green run):
# This script was written without ever executing it against a real build of
# this Dockerfile — Claude's sandbox has no Docker available. Package names
# were checked against Ubuntu 24.04's actual repositories, and command
# invocations were chosen based on documented behavior, but nothing here
# has been confirmed by actually running it. Treat the FIRST run of this
# script as itself part of the test, not as a formality — a failure here
# is genuinely new information, not a script bug to assume away.
#
# Usage (inside the container):
#   bash /workspace/test_environment.sh
set -uo pipefail  # not -e: run every check, report all failures together

PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    printf "%-60s" "[ ] ${name}"
    if eval "${cmd}" >/tmp/test_output.log 2>&1; then
        printf "\r[✓] %-60s\n" "${name}"
        PASS=$((PASS + 1))
        return 0
    else
        printf "\r[✗] %-60s\n" "${name}"
        echo "    Error: $(tail -n 3 /tmp/test_output.log | head -c 300 | tr '\n' ' ')"
        FAIL=$((FAIL + 1))
        return 1
    fi
}

echo "=== Writing a C Compiler environment — end-to-end test ==="
echo ""

# ---- 1. Core C toolchain ----
check "gcc present"            "command -v gcc"
check "g++ present"            "command -v g++"
check "make present"           "command -v make"
check "cmake present"          "command -v cmake"
check "ninja present"          "command -v ninja"

# ---- 2. Clang/LLVM ----
check "clang present"          "command -v clang"
check "llvm-config or llc present" "command -v llvm-config || command -v llc"
check "lld (ld.lld) present"   "command -v ld.lld"

# ---- 3. Binutils / ELF inspection — the tools your own comment flagged
#         as easy to mis-name, so worth checking explicitly rather than
#         assuming the comment's correction was sufficient ----
check "objdump present (via binutils)" "command -v objdump"
check "readelf present (via binutils)" "command -v readelf"
check "as (GNU assembler) present"     "command -v as"
check "ld (GNU linker) present"        "command -v ld"
check "elfutils' eu-readelf present"   "command -v eu-readelf"

# ---- 4. Debugging tools ----
check "gdb present"             "command -v gdb"
check "valgrind present"        "command -v valgrind"
check "strace present"          "command -v strace"
check "ltrace present"          "command -v ltrace"

# ---- 5. Static analysis ----
check "cppcheck present"        "command -v cppcheck"
check "shellcheck present"      "command -v shellcheck"
check "clang-format present"    "command -v clang-format"
check "clang-tidy present"      "command -v clang-tidy"

# ---- 6. Lexer/parser tools ----
check "flex present"            "command -v flex"
check "bison present"           "command -v bison"

# ---- 7. Python ----
check "python3 present"         "command -v python3"
check "pytest importable"       "python3 -c 'import pytest'"

# ---- 8. OCaml toolchain — the most likely place for a real problem,
#         given the Dockerfile's own comments flag non-obvious package/
#         command naming (ocaml-dune package -> dune command) ----
check "ocaml interpreter present"  "command -v ocaml"
check "dune present (command, NOT ocaml-dune)" "command -v dune"
check "menhir present"             "command -v menhir"
check "opam present"               "command -v opam"
check "ocamlfind present (from ocaml-findlib)" "command -v ocamlfind"

# Zarith and OUnit are libraries, not commands — check via ocamlfind list,
# which is the correct way to verify an OCaml findlib package is actually
# registered and usable, rather than just checking a binary exists (there
# is no binary for a library).
check "zarith findlib package registered"  "ocamlfind list 2>/dev/null | grep -qi zarith"
check "OUnit findlib package registered"   "ocamlfind list 2>/dev/null | grep -qi ounit"

# ---- 9. Custom convenience wrappers this Dockerfile builds itself —
#         these are the parts unique to this Dockerfile, most likely to
#         have a typo since they were hand-written with printf heredocs
#         rather than installed from a package ----
check "x86-64-gcc wrapper exists and is executable" "test -x /usr/local/bin/x86-64-gcc"
check "x86-64-clang wrapper exists and is executable" "test -x /usr/local/bin/x86-64-clang"
check "asm-info wrapper exists and is executable"   "test -x /usr/local/bin/asm-info"
check "show-asm wrapper exists and is executable"   "test -x /usr/local/bin/show-asm"
check "disasm wrapper exists and is executable"     "test -x /usr/local/bin/disasm"

echo ""
echo "=== Results so far: ${PASS} passed, ${FAIL} failed ==="
echo ""
echo "=== Functional checks: do the wrappers actually DO the right thing,"
echo "    not just exist? This is the part a package-presence check can't"
echo "    tell you, and it's exactly the category of bug the jump-table"
echo "    test surfaced earlier (a script that runs without erroring but"
echo "    checks/does the wrong thing). ==="
echo ""

# A minimal, deliberately trivial C program — small enough to eyeball the
# expected assembly output by hand if something looks wrong.
cat > /tmp/hello.c << 'EOF'
int add(int a, int b) {
    return a + b;
}
EOF

# ---- x86-64-gcc wrapper: does it actually force 64-bit output? ----
check "x86-64-gcc produces a 64-bit ELF object" \
    'x86-64-gcc -c /tmp/hello.c -o /tmp/hello_gcc.o && file /tmp/hello_gcc.o | grep -q "ELF 64-bit"'

# ---- x86-64-clang wrapper: same check, different compiler ----
check "x86-64-clang produces a 64-bit ELF object" \
    'x86-64-clang -c /tmp/hello.c -o /tmp/hello_clang.o && file /tmp/hello_clang.o | grep -q "ELF 64-bit"'

# ---- show-asm: does it actually emit assembly text, not an error? ----
check "show-asm emits assembly (contains 'add' mnemonic-adjacent text)" \
    'show-asm /tmp/hello.c 2>/dev/null | grep -qi "add"'

# ---- disasm: does it run objdump correctly against a real binary? ----
check "disasm produces Intel-syntax disassembly of a real object file" \
    'x86-64-gcc -c /tmp/hello.c -o /tmp/hello_disasm.o && disasm /tmp/hello_disasm.o | grep -qi "add"'

# ---- asm-info: does it run end-to-end without erroring, and does its
#      output make basic internal sense (uname -m and gcc -dumpmachine
#      should both mention x86_64, since this is an x86_64 container)? ----
check "asm-info runs cleanly and reports x86_64 consistently" \
    'asm-info 2>&1 | grep -q "x86_64"'

echo ""
echo "=== OCaml build smoke test: can dune actually build something? ===" 
echo "    (Package presence doesn't guarantee the build toolchain is"
echo "     correctly wired together — dune needs findlib, ocaml, and its"
echo "     own config to all agree with each other.)"
echo ""

mkdir -p /tmp/dune_smoke_test/bin
cd /tmp/dune_smoke_test
cat > dune-project << 'EOF'
(lang dune 3.0)
EOF
mkdir -p bin
cat > bin/main.ml << 'EOF'
let () = print_endline "dune smoke test ok"
EOF
cat > bin/dune << 'EOF'
(executable
 (name main))
EOF

check "dune builds a trivial OCaml executable" "dune build 2>&1"
check "dune-built executable runs and prints expected output" \
    './_build/default/bin/main.exe | grep -q "dune smoke test ok"'

cd /
rm -rf /tmp/dune_smoke_test /tmp/hello*.c /tmp/hello*.o

echo ""
echo "=== FINAL Results: ${PASS} passed, ${FAIL} failed ==="

if [ "${FAIL}" -gt 0 ]; then
    echo ""
    echo "One or more checks failed. Given this test has never been run"
    echo "against a real build of this Dockerfile before now, a failure"
    echo "here is telling you something true about the environment, not"
    echo "just about the test script — but paste the specific [✗] lines"
    echo "back rather than assuming which one matters most; some of these"
    echo "checks (e.g. exact grep text) are my best guess at expected"
    echo "output and could themselves be slightly off even when the"
    echo "underlying tool is working fine."
    exit 1
else
    echo "All checks passed. Note this is the FIRST real execution of this"
    echo "test — treat this as a good sign, not a certainty, since the"
    echo "checks reflect my best understanding of correct behavior, not"
    echo "a specification verified against this exact Dockerfile before now."
    exit 0
fi