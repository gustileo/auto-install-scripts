#!/bin/bash

# Define variables
DOWNLOAD_DIR="/home/noeruid/Downloads"
COMPLETED_DIR="/home/noeruid/completed-downloads"
MOVE_SCRIPT="/home/noeruid/move_completed_downloads.sh"
UPLOAD_SCRIPT="/home/noeruid/upload_completed_downloads.sh"
MOVE_SERVICE="/etc/systemd/system/move-completed-downloads.service"
UPLOAD_SERVICE="/etc/systemd/system/rclone-upload.service"
RCLONE_CONFIG="/home/noeruid/.config/rclone/rclone.conf"
LOG_DIR="/home/noeruid/logs"

# Create required directories
mkdir -p "$COMPLETED_DIR"
mkdir -p "$(dirname $RCLONE_CONFIG)"
mkdir -p "$LOG_DIR"

# Create move_completed_downloads.sh script
cat << 'EOF' > "$MOVE_SCRIPT"
#!/bin/bash

# Source directory where Chrome saves downloads
DOWNLOAD_DIR="/home/noeruid/Downloads"
# Directory where completed downloads will be moved
COMPLETED_DIR="/home/noeruid/completed-downloads"
# Log file
LOG_FILE="/home/noeruid/logs/move_completed_downloads.log"
# Delay in seconds to wait before checking the file size
DELAY=10

# Create completed downloads directory if it doesn't exist
mkdir -p "$COMPLETED_DIR"

# Use inotifywait to monitor the directory for completed downloads
inotifywait -m -e close_write --format '%w%f' "$DOWNLOAD_DIR" | while read NEWFILE
do
  # Ignore files with .crdownload extension and .com.google.Chrome.* files
  if [[ "$NEWFILE" != *.crdownload && ! "$NEWFILE" =~ \.com\.google\.Chrome\..* ]]; then
    echo "Detected potential completed file: $NEWFILE" >> "$LOG_FILE"
    
    # Wait for a short delay to ensure the file writing is complete
    sleep "$DELAY"
    
    # Check if the file size is stable
    FILESIZE1=$(stat -c%s "$NEWFILE")
    sleep "$DELAY"
    FILESIZE2=$(stat -c%s "$NEWFILE")
    
    if [ "$FILESIZE1" -eq "$FILESIZE2" ]; then
      echo "File size is stable: $NEWFILE" >> "$LOG_FILE"
      # Move the completed download to the completed directory
      mv "$NEWFILE" "$COMPLETED_DIR" && echo "Moved $NEWFILE to $COMPLETED_DIR" >> "$LOG_FILE" || echo "Failed to move $NEWFILE" >> "$LOG_FILE"
    else
      echo "File size is not stable, skipping move: $NEWFILE" >> "$LOG_FILE"
    fi
  else
    echo "Ignoring temporary file: $NEWFILE" >> "$LOG_FILE"
  fi
done
EOF

# Make move script executable
chmod +x "$MOVE_SCRIPT"

# Create upload_completed_downloads.sh script
cat << 'EOF' > "$UPLOAD_SCRIPT"
#!/bin/bash

# Directory to monitor
COMPLETED_DIR="/home/noeruid/completed-downloads"
# Remote Google Drive directory
REMOTE_DIR="Drive:/Ubuntu"
# Log file
LOG_FILE="/home/noeruid/logs/upload_completed_downloads.log"
# Path to rclone config file
RCLONE_CONFIG="/home/noeruid/.config/rclone/rclone.conf"

# Log environment variables
echo "Environment Variables:" >> "$LOG_FILE"
printenv >> "$LOG_FILE"

# Use inotifywait to monitor the directory for new files or directories
inotifywait -m -e close_write,moved_to,create --format '%w%f' "$COMPLETED_DIR" | while read NEWFILE
do
  echo "Detected new file or directory for upload: $NEWFILE" >> "$LOG_FILE"
  if [ -d "$NEWFILE" ]; then
    echo "Detected directory: $NEWFILE" >> "$LOG_FILE"
    # If it's a directory, use rclone to copy the directory recursively
    rclone --config="$RCLONE_CONFIG" copy "$NEWFILE" "$REMOTE_DIR/$(basename "$NEWFILE")" -vv 2>> "$LOG_FILE" && echo "Successfully uploaded directory $NEWFILE to $REMOTE_DIR" >> "$LOG_FILE" || echo "Failed to upload directory $NEWFILE" >> "$LOG_FILE"
  else
    echo "Detected file: $NEWFILE" >> "$LOG_FILE"
    # If it's a file, use rclone to copy the file
    rclone --config="$RCLONE_CONFIG" copy "$NEWFILE" "$REMOTE_DIR" -vv 2>> "$LOG_FILE" && echo "Successfully uploaded file $NEWFILE to $REMOTE_DIR" >> "$LOG_FILE" || echo "Failed to upload file $NEWFILE" >> "$LOG_FILE"
  fi
done
EOF

# Make upload script executable
chmod +x "$UPLOAD_SCRIPT"

# Create move-completed-downloads.service file
cat << EOF > "$MOVE_SERVICE"
[Unit]
Description=Move completed downloads to a specific folder
After=network-online.target

[Service]
Type=simple
ExecStart=$MOVE_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

# Create rclone-upload.service file
cat << EOF > "$UPLOAD_SERVICE"
[Unit]
Description=Monitor completed downloads folder and upload to Google Drive
After=network-online.target

[Service]
Type=simple
ExecStart=$UPLOAD_SCRIPT
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service files
sudo systemctl daemon-reload

# Enable and start the services
sudo systemctl enable move-completed-downloads.service
sudo systemctl start move-completed-downloads.service
sudo systemctl enable rclone-upload.service
sudo systemctl start rclone-upload.service

echo "Setup complete. The system is now configured to move completed downloads and upload them to Google Drive."
