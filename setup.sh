#!/bin/sh

# -----------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# SSL/TLS session ticket key script setup.
#
# AUTHOR: Richard Fussenegger <richard@fussenegger.info>
# COPYRIGHT: Copyright (c) 2013 Richard Fussenegger
# LICENSE: http://unlicense.org/ PD
# LINK: http://richard.fussenegger.info/
# -----------------------------------------------------------------------------

# Load configuration file.
source $(pwd)/config.sh

if [ -d "${TMPFS_PATH}" ]
then
  echo "Aborting: directory ${TMPFS_PATH} already exists."
  exit 1
else
  # Create mount point for temporary file system.
  mkdir "${TMPFS_PATH}"

  # Apply very permissive permissions.
  chmod 770 "${TMPFS_PATH}"

  # Mount temporary file system and precise it's size.
  #
  # TODO: Check if ramfs is available and use it instead of tmpfs (swap).
  mount -t tmpfs -o mode=770 tmpfs ${TMPFS_PATH}

  # Automatically create temporary file system on start up in the future.
  echo $'\n'"none ${TMPFS_PATH} ramfs defaults,mode=770 0 0"$'\n' >> /etc/fstab

  # Generate session ticket key for encryption and fake decrypt files.
  sh "$(pwd)/${GENERATOR}.sh"

  echo "Please add the following lines to your nginx configuration:"$'\n'
  for SERVER in ${SERVER_COUNT}
  do
    echo "Server ${SERVER}:"
    for KEY in 1 2 3
    do
      echo "    ssl_session_ticket_key ${TMPFS_PATH}/${SERVER}.${KEY}.key"
    done
    echo $'\n'
  done
  echo "And reload the service afterwards."$'\n'

  # Create symbolic link for regular rotation of session tickets.
  ln -s "$(pwd)/${GENERATOR}.sh" "/etc/cron.${CRON_KEYWORD}/${CRON_LINKNAME}"

  echo "The roation was set to ${CRON_KEYWORD} and will be automatically executed by"
  echo "cron."
  echo $'\n'
  echo "Please refer to the documentation if you have a server cluster in use and"
  echo "need to synchronize the keys."
  echo $'\n'

  exit 0
fi
