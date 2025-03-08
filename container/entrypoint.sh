#!/bin/bash

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Function to handle shutdown when sigterm is recieved
shutdown () {
    echo ""
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    kill -2 $soulmask_pid
}

# Set our trap
trap 'shutdown' TERM

# Set vars established during image build
IMAGE_VERSION=$(cat /home/steam/image_version)
MAINTAINER=$(cat /home/steam/image_maintainer)
EXPECTED_FS_PERMS=$(cat /home/steam/expected_filesystem_permissions)

echo "$(timestamp) INFO: Launching Soulmask Dedicated Server image ${IMAGE_VERSION} by ${MAINTAINER}"

# Validate arguments
echo "$(timestamp) INFO: Validating launch arguments"
if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="Soulmask Containerized"
    echo "$(timestamp) WARN: SERVER_NAME not set, using default: Soulmask Containerized"
fi

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "$(timestamp) WARN: ADMIN_PASSWORD not set, using default: AdminPleaseChangeMe"
    ADMIN_PASSWORD="AdminPleaseChangeMe"
fi

if [ -z "$SERVER_PASSWORD" ]; then
    echo "$(timestamp) WARN: SERVER_PASSWORD not set, server will be open to the public"
fi

if [ -z "$GAME_MODE" ]; then
    echo "$(timestamp) ERROR: GAME_MODE not set, must be 'pve' or 'pvp'"
    exit 1
else
    if [ "$GAME_MODE" != "pve" ] && [ "$GAME_MODE" != "pvp" ]; then
        echo "$(timestamp) ERROR: GAME_MODE must be either 'pve' or 'pvp'"
        exit 1
    fi
fi

# Check for proper save permissions
echo "$(timestamp) INFO: Validating data directory filesystem permissions"
if ! touch "${SOULMASK_PATH}/test"; then
    echo ""
    echo "$(timestamp) ERROR: The ownership of ${SOULMASK_PATH} is not correct and the server will not be able to save..."
    echo "the directory that you are mounting into the container needs to be owned by ${EXPECTED_FS_PERMS}"
    echo "from your container host attempt the following command 'sudo chown -R ${EXPECTED_FS_PERMS} /your/soulmask/data/directory'"
    echo ""
    exit 1
fi

rm "${SOULMASK_PATH}/test"

# Install/Update Soulmask
echo "$(timestamp) INFO: Updating Soulmask Dedicated Server"
echo ""
${STEAMCMD_PATH}/steamcmd.sh +force_install_dir "${SOULMASK_PATH}" +login anonymous +app_update ${STEAM_APP_ID} validate +quit
echo ""

# Check that steamcmd was successful
if [ $? != 0 ]; then
    echo "$(timestamp) ERROR: steamcmd was unable to successfully initialize and update Soulmask"
    exit 1
else
    echo "$(timestamp) INFO: steamcmd update of Soulmask successful"
fi

# Build launch arguments
echo "$(timestamp) INFO: Constructing launch arguments"
LAUNCH_ARGS="${SERVER_LEVEL} -server -SILENT -SteamServerName=\"${SERVER_NAME}\" -${GAME_MODE} -MaxPlayers=${SERVER_SLOTS} -backup=${BACKUP} -saving=${SAVING} -log -UTF8Output -MULTIHOME=${LISTEN_ADDRESS} -Port=${GAME_PORT} -QueryPort=${QUERY_PORT} -online=Steam -forcepassthrough -adminpsw=${ADMIN_PASSWORD}"

if [ -n "${SERVER_PASSWORD}" ]; then
    LAUNCH_ARGS="${LAUNCH_ARGS} -PSW=${SERVER_PASSWORD}"
fi

if [ -n "${RCON_ADDR}" ] && [ -n "${RCON_PASSWORD}" ]; then
    LAUNCH_ARGS="${LAUNCH_ARGS} -rconaddr=${RCON_ADDR} -rconpsw=${RCON_PASSWORD} -rconport=${RCON_PORT}"
fi

# Let's go!
echo "$(timestamp) INFO: Lighting the bonfire..."

# Cheesy asci launch banner because I remember 1999
echo ""
echo ""
echo "  _________________   ____ ___.____       _____      _____    _____________  __."
echo " /   _____/\_____  \ |    |   \    |     /     \    /  _  \  /   _____/    |/ _|"
echo " \_____  \  /   |   \|    |   /    |    /  \ /  \  /  /_\  \ \_____  \|      <  "
echo " /        \/    |    \    |  /|    |___/    Y    \/    |    \/        \    |  \ "
echo "/_______  /\_______  /______/ |_______ \____|__  /\____|__  /_______  /____|__ \\"
echo "        \/         \/                 \/       \/         \/        \/        \/"
echo "                                                                                "
echo "                                                                                "
echo "$(timestamp) INFO: Launching Soulmask. Good luck out there, Chieftan!"
echo "--------------------------------------------------------------------------------"
echo "Server Name: ${SERVER_NAME}"
echo "Game Mode: ${GAME_MODE}"
echo "Server Level: ${SERVER_LEVEL}"
echo "Server Password: ${SERVER_PASSWORD}"
echo "Admin Password: ${ADMIN_PASSWORD}"
echo "Game Port: ${GAME_PORT}"
echo "Query Port: ${QUERY_PORT}"
echo "Server Slots: ${SERVER_SLOTS}"
echo "Listen Address: ${LISTEN_ADDRESS}"
echo "Database Backup (seconds): ${BACKUP}"
echo "World Save (seconds): ${SAVING}"
echo "Container Image Version: ${IMAGE_VERSION} "
echo "--------------------------------------------------------------------------------"
echo ""
echo ""

# Launch Soulmask
${SOULMASK_PATH}/WSServer.sh ${LAUNCH_ARGS} &

# Capture Soulmask server start script pid
init_pid=$!

# Capture Soulmask server binary pid
timeout=0
while [ $timeout -lt 11 ]; do
    if ps -e | grep "WSServer-Linux"; then
        soulmask_pid=$(ps -e | grep "WSServer-Linux" | awk '{print $1}')
        break
    elif [ $timeout -eq 10 ]; then
        echo "$(timestamp) ERROR: Timed out waiting for WSServer-Linux to be running"
        exit 1
    fi
    sleep 6
    ((timeout++))
done

# Hold us open until we recieve a SIGTERM
wait $init_pid

# Handle post SIGTERM from here
# Hold us open until WSServer-Linux pid closes, indicating full shutdown, then go home
tail --pid=$soulmask_pid -f /dev/null

# o7
echo "$(timestamp) INFO: Shutdown complete. Goodbye, Chieftan."
exit 0
