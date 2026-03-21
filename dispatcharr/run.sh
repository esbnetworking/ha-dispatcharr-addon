#!/usr/bin/with-contenv bashio
# ^ Use bashio for easy logging and config fetching

set -e

# 1. Define Paths
# Internal app path (mapped to /addon_configs via config.yaml)
CONFIG_PATH="/data" 
# Where you stored the "factory default" files in your Dockerfile
DEFAULT_CONF="/defaults" 

bashio::log.info "Starting Dispatcher add-on..."

# 2. Check if the persistent config folder is empty
# If the main config file doesn't exist, we copy the defaults over
if [ ! -f "$CONFIG_PATH/dispatcher.conf" ]; then
    bashio::log.warning "No configuration found in /addon_configs. Initializing with defaults..."
    
    # Create directory structure if needed
    mkdir -p "$CONFIG_PATH"
    
    # Copy default files from the image to the persistent host folder
    cp -pr "$DEFAULT_CONF/." "$CONFIG_PATH/"
    
    bashio::log.info "Initialization complete. You can now edit files in /addon_configs/dispatcher/"
else
    bashio::log.info "Existing configuration found in /addon_configs. Skipping initialization."
fi

# 3. (Optional) Sync HA Options to the Config file
# If you want to take settings from the HA "Configuration" UI and 
# inject them into your app's config file:
# LOG_LEVEL=$(bashio::config 'log_level')
# sed -i "s/loglevel = .*/loglevel = $LOG_LEVEL/" "$CONFIG_PATH/dispatcher.conf"

# 4. Start the actual Dispatcher application
bashio::log.info "Launching Dispatcher..."
exec /usr/bin/dispatcher --config "$CONFIG_PATH/dispatcher.conf"
