#!/usr/bin/env bash
set -e

# HOST_UID is expected from the environment.
# HOST_GID can also be from the environment.
# If HOST_UID is not set or is empty, skip user/group modification.


if [ -n "$HOST_UID" ]; then
    # If HOST_GID is not set, default it to HOST_UID.
    # This is only relevant if HOST_UID is set.
    HOST_GID_TO_SET=${HOST_GID:-$HOST_UID}
    OLD_UID=$(id -u jovyan) # Store old UID for potential find command later (currently commented)
    CURRENT_UID=$(id -u jovyan)
    CURRENT_GID=$(id -g jovyan)

    if [ "$CURRENT_UID" != "$HOST_UID" ] || [ "$CURRENT_GID" != "$HOST_GID_TO_SET" ]; then
      echo "Remapping jovyan. Current UID: $CURRENT_UID -> Target UID: $HOST_UID. Current GID: $CURRENT_GID -> Target GID: $HOST_GID_TO_SET"
      # Apply group modification. || true to allow it to proceed if group already has the GID or other non-fatal errors.
      groupmod -g "$HOST_GID_TO_SET" jovyan || true
      # Apply user modification. This will also set the primary group to the new GID of 'jovyan' group.
      time usermod -u "$HOST_UID" -g "$HOST_GID_TO_SET" jovyan
      chmod 755 /home/jovyan
      time chown -R "${HOST_UID}:${HOST_GID_TO_SET}" /opt/conda # Explicitly use target UID/GID
      #find /home/jovyan -uid "$OLD_UID" -exec chown "$HOST_UID":"$HOST_GID_TO_SET" {} +
      echo "Done remapping."
    else
      echo "jovyan UID ($CURRENT_UID) and GID ($CURRENT_GID) already match specified HOST_UID ($HOST_UID) and HOST_GID ($HOST_GID_TO_SET). No changes made."
    fi

else
    echo "HOST_UID is not set or is empty. Skipping jovyan user/group modification."
fi

/usr/bin/supervisord -n -c /etc/supervisor/services.conf
