#!/bin/bash

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

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
${STEAMCMD_PATH}/steamcmd.sh +force_install_dir "${SOULMASK_PATH}" +login anonymous +app_update ${STEAM_APP_ID} validate +quit

# Check that steamcmd was successful
if [ $? != 0 ]; then
    echo "$(timestamp) ERROR: steamcmd was unable to successfully initialize and update Soulmask"
    exit 1
fi

# Build launch arguments
echo "$(timestamp) INFO: Constructing launch arguments"
LAUNCH_ARGS="${SERVER_LEVEL} -server -SILENT -SteamServerName=${SERVER_NAME} -MaxPlayers=${SERVER_SLOTS} -backup=900 -saving=600 -log -UTF8Output -MULTIHOME=${LISTEN_ADDRESS} -Port=${GAME_PORT} -QueryPort=${QUERY_PORT} -online=Steam -forcepassthrough -adminpsw=${ADMIN_PASSWORD}"

if [ -n "${SERVER_PSASWORD}" ]; then
    LAUNCH_ARGS="${LAUNCH_ARGS} -PSW=${SERVER_PASSWORD}"
fi

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
echo "$(timestamp) INFO: Launching Soulmask"
echo "--------------------------------------------------------------------------------"
echo "Server Name: ${SERVER_NAME}"
echo "Server Level: ${SERVER_LEVEL}"
echo "Server Password: ${SERVER_PASSWORD}"
echo "Admin Password: ${ADMIN_PASSWORD}"
echo "Game Port: ${GAME_PORT}"
echo "Query Port: ${QUERY_PORT}"
echo "Server Slots: ${SERVER_SLOTS}"
echo "Listen Address: ${LISTEN_ADDRESS}"
echo "--------------------------------------------------------------------------------"
echo ""
echo ""

# Launch Soulmask
${SOULMASK_PATH}/WSServer.sh ${LAUNCH_ARGS}
