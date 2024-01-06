#!/usr/bin/env bash


# md5 checksum calculation for $SOURCE_PATH

# Copyright (c) 2021, Aleksandr Bazhenov

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# -----------------------------------------------------------------------------------------------
# Warning! Running this file you accept that you know what you're doing. All actions with this
#          script are at your own risk.
# -----------------------------------------------------------------------------------------------


SOURCE_PATH="/mnt/backup/"


usage_error() {
  echo "Error: unrecognized option: $POSITIONAL"
  echo ""
  echo "Usage:"
  echo "   -s|--source|--source-path /path/to/source/folder/or/file"
  echo "                             (defaults: $SOURCE_PATH)"
  exit 1
}

check_md5() {
  FILENAME="$1"
  echo "Checking exising ${FILENAME#./}'s md5..."
  md5sum -c "$FILENAME.md5" || \
    (echo "Re-calculating md5 for $FILENAME..." && \
      md5sum -b "$FILENAME" | tee "$FILENAME".md5)
}

while [[ $# -gt 0 ]]; do
  KEY="$1"

  case $KEY in
  -s | --source | --source-path)
    SOURCE_PATH="$2"
    shift
    shift
    ;;

  *)                   # unknown option
    POSITIONAL+=("$1")
    usage_error
    ;;
  esac
done

set -- "${POSITIONAL[@]}"
export -f check_md5

HOSTNAME="$(hostname)"
echo "Ready to calculate md5 checksum on $HOSTNAME for directory: $SOURCE_PATH"

find . ! -name '*.md5' -type f -exec bash -c \
  'if [[ -f $1.md5 ]]; then check_md5 $1; else md5sum -b $1 | tee $1.md5; fi' -- {} \; || \
  /./opt/scripts/check_error_notification.sh "md5" && exit 1