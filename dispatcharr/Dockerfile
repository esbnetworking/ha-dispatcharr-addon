# Use the official Dispatcharr image
FROM ghcr.io/dispatcharr/dispatcharr:latest

# Copy our custom initialization script
COPY run.sh /run.sh

# Ensure the script is executable
RUN chmod a+x /run.sh

# Hijack the entrypoint to run our symlink script first
ENTRYPOINT [ "/run.sh" ]
