#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a script to run tests the same way Travis does, but on a local
# development Apple laptop. This handles
# - checking that the "official" CPython is installed where expected
# - checking that ``gfortran`` is installed
# - setting of relevant environment variables
# - building a universal ``libgfortran``
# - make sure we have a latest `nox`, `pip`, `numpy` and `virtualenv`
# - puts the "local" Python at the front of `PATH`

set -e

PREFIX="/Library/Frameworks/Python.framework/Versions"
# ``readlink -f`` is not our friend on OS X.
SCRIPT_FI=$(python -c "import os; print(os.path.realpath('${0}'))")
OSX_SCRIPTS_DIR=$(dirname ${SCRIPT_FI})

if [[ -z "${PY_VERSION}" ]]; then
    echo "PY_VERSION environment variable should be set by the caller."
    exit 1
fi

if [[ -z "$(command -v gfortran)" ]]; then
    echo "gfortran must be installed, please run 'brew install gcc'."
    exit 1
fi

# Verify the version and set the PY_BIN_DIR (used by `test.sh`).
if [[ "${PY_VERSION}" == "2.7" ]]; then
    export PY_BIN_DIR="${PREFIX}/2.7/bin"
elif [[ "${PY_VERSION}" == "3.5" ]]; then
    export PY_BIN_DIR="${PREFIX}/3.5/bin"
elif [[ "${PY_VERSION}" == "3.6" ]]; then
    export PY_BIN_DIR="${PREFIX}/3.6/bin"
else
    echo "Unexpected version: ${PY_VERSION}"
    exit 1
fi

# Check that the relevant version of CPython is installed.
if [[ -d "${PY_BIN_DIR}" ]]; then
    echo "PY_BIN_DIR=${PY_BIN_DIR}"
else
    echo "${PY_BIN_DIR} does not exist"
    exit 1
fi

# Make sure the "official" installed CPython is set up for testing.
${PY_BIN_DIR}/python -m pip install --upgrade virtualenv pip
${PY_BIN_DIR}/python -m pip install --upgrade 'nox-automation >= 0.18.2' numpy

# Make sure there is a universal ``libgfortran``.
export GFORTRAN_LIB="${OSX_SCRIPTS_DIR}/frankenstein"
if [[ -d "${GFORTRAN_LIB}" ]]; then
    echo "The 'frankenstein' universal gfortran library already exists."
else
    ${PY_BIN_DIR}/python ${OSX_SCRIPTS_DIR}/make_universal_libgfortran.py
fi


# Set up the tempfile directories for universal builds.
export TEMPDIR_I386=${OSX_SCRIPTS_DIR}/tempdir-i386
mkdir -p ${TEMPDIR_I386}
export TEMPDIR_X86_64=${OSX_SCRIPTS_DIR}/tempdir-x86_64
mkdir -p ${TEMPDIR_X86_64}

# Make sure the current Python is at the front of `PATH`.
export PATH="${PY_BIN_DIR}:${PATH}"

# Finally, run the tests.
${OSX_SCRIPTS_DIR}/test.sh
