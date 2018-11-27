#!/bin/bash


# Absolute path on your local McMyAdmin installation 
MCMYADMIN_BACKUP_PATH="/home/mcmyadmin/Backups"

# Absolute path on your remote NAS or any
REMOTE_BACKUP_PATH="/home/backup/minecraft"

# SSH HOST
REMOTE_BACKUP_SSH_HOST="my.favorite.nas"

# SSH PORT
REMOTE_BACKUP_SSH_PORT="22"

info() {
  echo "$(date +%Y-%m-%dT%H:%M:%S) [INFO] $1"
}

error() {
  echo "$(date +%Y-%m-%dT%H:%M:%S) [ERROR] $1"
}

fetch_local_backups() {
  ls -t $MCMYADMIN_BACKUP_PATH/Backup-*.mb2 | sed -e "s|^.*/\([^/]*\)*$|\1|"
}

fetch_remote_backups() {
  ssh -p $REMOTE_BACKUP_SSH_PORT $REMOTE_BACKUP_SSH_HOST ls -t $REMOTE_BACKUP_PATH/Backup-*.mb2 | sed -e "s|^.*/\([^/]*\)*$|\1|"
}

copy_backups_local_to_remote() {
  local -n l_backups=$1
  local nb_l_backups=${#l_backups[@]}

  for ((l = 0; l <= nb_l_backups - 1; l++)); do
    info "Copying from local to remote host: ${l_backups[l]}"
    if scp -P $REMOTE_BACKUP_SSH_PORT $MCMYADMIN_BACKUP_PATH/${l_backups[l]} $REMOTE_BACKUP_SSH_HOST:$REMOTE_BACKUP_PATH; then
      info "Copying from local to remote host: ${l_backups[l]}... OK"
    else
      error "Copying from local to remote host: ${l_backups[l]}... FAILED"
    fi
  done
}

delete_backups_remote() {
  local -n r_backups=$1
  local nb_r_backups=${#r_backups[@]}

  for ((r = 0; r <= nb_r_backups - 1; r++)); do
    info "Removing backup on remote host: ${r_backups[r]}"
    if ssh -p $REMOTE_BACKUP_SSH_PORT $REMOTE_BACKUP_SSH_HOST "rm $REMOTE_BACKUP_PATH/${r_backups[r]}"; then
      info "Removing backup on remote host: ${r_backups[r]}... OK"
    else
      error "Removing backup on remote host: ${r_backups[r]}... FAILED"
    fi
  done
}

debug_args() {
  local -n l_backups=$1
  echo "local backups: ${l_backups[@]}"

  local -n r_backups=$2
  echo "remote backups: ${r_backups[@]}"
}

what_backups_exist_only_in_local() {
  local -n l_backups=$1
  local -n r_backups=$2
  local backups_only_in_local=()

  local nb_l_backups=${#l_backups[@]}
  local nb_r_backups=${#r_backups[@]}

  for ((l = 0; l <= nb_l_backups - 1; l++)); do

    local found="false"
    for ((r = 0; r <= nb_r_backups - 1; r++)); do
      if [ "${l_backups[l]}" == "${r_backups[r]}" ]; then
        found="true"
        break
      fi
    done

    if [ "$found" == "false" ]; then
      backups_only_in_local+=(${l_backups[l]})
    fi
  done
 
  echo "${backups_only_in_local[@]}"
}

what_backups_exist_only_in_remote() {
  local -n l_backups=$1
  local -n r_backups=$2
  local backups_only_in_remote=()

  local nb_l_backups=${#l_backups[@]}
  local nb_r_backups=${#r_backups[@]}

  for ((r = 0; r <= nb_r_backups - 1; r++)); do
    local found="false"
    for ((l = 0; l <= nb_l_backups - 1; l++)); do
      if [ "${r_backups[r]}" == "${l_backups[l]}" ]; then
        found="true"
        break
      fi
    done

    if [ "$found" == "false" ]; then
      backups_only_in_remote+=(${r_backups[r]})
    fi
  done

  echo "${backups_only_in_remote[@]}"
}

main() {
  info "Start synchronizing between local MCMyAdmin backups and remote storage"

  # Sleep commands prevent disorder on logging tools like ELK because of same timestamp
  # Remove them if you do not care
  sleep 0.1
  local local_backups=($(fetch_local_backups))
  local remote_backups=($(fetch_remote_backups))

  local backups_only_in_local=($(what_backups_exist_only_in_local local_backups remote_backups))
  local backups_only_in_remote=($(what_backups_exist_only_in_remote local_backups remote_backups))

  if [ ${#backups_only_in_local[@]} -gt 0 ]; then
    copy_backups_local_to_remote backups_only_in_local
  else
    info "No new local backups found to copy on remote..."
  fi

  sleep 0.1

  if [ ${#backups_only_in_remote[@]} -gt 0 ]; then
    delete_backups_remote backups_only_in_remote
  else
    info "No old remote backups found to delete..."
  fi

  sleep 0.1

  info "End synchronizing between local MCMyAdmin backups and remote storage"
}

main
