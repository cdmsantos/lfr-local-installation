#!/bin/bash
set -e

#========================
## Commands
#========================
COMMAND="$1"
PARAMS="$2"
CURRENT_DIR=$(pwd)

#========================
## Files
#========================

LIFERAY_BUNDLE_FOLDER_NAME=liferay-dxp-7.3.10.1-sp1
LIFERAY_BUNDLE=bundles/liferay-dxp-tomcat-7.3.10.1-sp1-20210303153956119.tar.gz
LICENSE_XML=/activation/activation-key-digitalenterprisedevelopment-7.3-liferaycom.xml
LIFERAY_BUNDLES_DOCUMENT_LIBRARY_DIR="${LIFERAY_HOME}"/data/document_library
#FIXPACK_FILE=
#HOTFIX_FILE=

#========================
## Variables
#========================
TOMCAT_VERSION=9.0.40
LIFERAY_HOME=bundles
PROJECT=local
DATABASE=lportal
DATABASE_PASSWORD=local@2021
MYSQL_VERSION=8
MYSQL_PORT=3392

#========================
## Colors
#========================
blue=$'\e[1;34m'
cyan=$'\e[1;36m'
white=$'\e[0m'
red=$'\e[31m'

#========================
## Save and Load State
#========================
load_backup(){
  log_info "=> TASK: load_backup"
  
  if [ ! -d "$LIFERAY_HOME/data/document_library" ]; then
    log_debug mkdir -p $LIFERAY_HOME/data/document_library
  fi

  log_debug rm -rf $LIFERAY_HOME/data/document_library/*
  unzip -o backups/"$PROJECT"_document_library.zip -d $LIFERAY_HOME/data/document_library
  
  log_info "Restore database dump";
  cat backups/"$PROJECT"_mysql.sql | docker exec -i "$PROJECT"_mysql mysql -u root --password=$DATABASE_PASSWORD $DATABASE
}

load_state() {
  log_info "Warning: Liferay container will be stopped!";
  log_debug read -p "Press any key to continue..." -n1 -s

  stop_server

  remove_docker_mysql
  create_docker_mysql 
  
  load_data

  build_project
  start_server
}

save_state() {
  log_info "Warning: You will generate a dump!";
  log_debug read -p "Press any key to continue..." -n1 -s
  
  if [ ! -d "backups" ]; then
    mkdir backups
  else
    rm -rf backups/*
  fi

  log_info "Info: Exporting document and library";
  if [ -d "$LIFERAY_HOME/data/document_library" ]; then
    cd $LIFERAY_HOME/data/document_library && zip -r ../../../backups/"$PROJECT"_document_library.zip * && cd -
  fi

  log_info "Info: Creating database dump";
  docker exec "$PROJECT"_"mysql" sh -c 'exec mysqldump --all-databases -uroot --password="local@2021"' > backups/"$PROJECT"_mysql.sql
}

load_data() {
  if [ ! -d "$LIFERAY_HOME/data/document_library" ]; then
    log_debug mkdir -p $LIFERAY_HOME/data/document_library
  fi

  log_debug rm -rf $LIFERAY_HOME/data/document_library/*
  unzip -o backups/"$PROJECT"_document_library.zip -d $LIFERAY_HOME/data/document_library
  
  log_info "Restore database dump";
  
  cat backups/"$PROJECT"_mysql.sql | docker exec -i $DATABASE mysql -u root --password=$DATABASE_PASSWORD $DATABASE
}

#========================
## SO
#========================
isWindows() {
  log_info "Detect OS";
  if [[ "$OSTYPE" == "msys" ]]; then
    log_info "Windows detected";
    return 0;
  else
    log_info "MacOS or Linux detected";
    return 1;
  fi
}

set_files_folder() {
  if isWindows; then
      FOLDER_PATH=files
    else
      FOLDER_PATH=~/.liferay
  fi  
  LICENSE_XML=$FOLDER_PATH/$LICENSE_XML
  LIFERAY_BUNDLE=$FOLDER_PATH/$LIFERAY_BUNDLE
  LIFERAY_FIXPACK=$FOLDER_PATH/$LIFERAY_FIXPACK
  LIFERAY_HOTFIX=$FOLDER_PATH/$LIFERAY_HOTFIX
}

#========================
## Mail Catcher
#========================
mail_catcher_up(){
  log_info "Creating mail catcher"

  log_debug docker run --name="$PROJECT"_mail -d \
          --publish=1095:1080 \
          --publish=1035:1025 \
          dockage/mailcatcher:0.7.1
}

mail_catcher_stop(){
  log_info 'Stopping mailcatcher catcher'

  if docker ps -a | grep -q "$PROJECT"_mail; then
    log_debug docker stop "$PROJECT"_mail || true
    log_debug docker rm "$PROJECT"_mail || true
  fi 
}

#========================
## License
#========================
deploy_license() {
  log_info "=> TASK: deploy_license"
  log_info "Locating Liferay license..."

  if [ ! -d "$LIFERAY_HOME/deploy/" ]; then
    log_debug mkdir $LIFERAY_HOME/deploy/
  fi

  if [ -f $LICENSE_XML ]; then
    log_info "Deploying license file: \"$LICENSE_XML\""
    log_debug cp $LICENSE_XML bundles/deploy/
  else
    log_error "License not found at \"$LICENSE_XML\". Please deploy it manually"
    exit 2
  fi
}

#========================
## Patches
#========================
apply_patches(){
  log_info "=> TASK: apply_patches"
  log_info "Install $HOTFIX_FILE"
  cp $HOTFIX_FILE bundles/patching-tool/patches
  cp $FIXPACK_FILE bundles/patching-tool/patches
  ./bundles/patching-tool/patching-tool.sh install
  ./bundles/patching-tool/patching-tool.sh info
}

#========================
## Database
#========================
remove_docker_db() {
  log_info "=> TASK: remove_docker_db"

  # Check if docker is running
  log_info "docker ps -a"
  if ! docker ps -a | grep -q CONTAINER
  then
    log_error "Docker does not seem to be running, run it first and retry"
    exit 1
  fi

  if docker ps -a -f name="$PROJECT"_"mysql" | grep -q "$PROJECT"_"mysql"
  then
    log_debug docker stop "$PROJECT"_"mysql"
    log_debug docker rm "$PROJECT"_"mysql"
  fi
}

create_docker_db() {
  log_info "=> TASK: create_docker_db"

  if [ ! "$(docker ps -q -f name=\"$PROJECT\"_"mysql")" ]; then
      log_info "Info: Starting mysql container...";
      log_debug docker run \
        --name "$PROJECT"_"mysql" \
        -p "$MYSQL_PORT":3306 \
        -e MYSQL_DATABASE="$DATABASE" \
        -e MYSQL_ROOT_PASSWORD="$DATABASE_PASSWORD" \
        -d mysql:"$MYSQL_VERSION" \
        --character-set-server=utf8 \
        --collation-server=utf8_general_ci \
        --lower-case-table-names=0
      secs=$((15))
      while [ $secs -gt 0 ]; do
        echo -ne "$secs\033[0K\r"
        sleep 1
        secs=$((secs-1))
      done
  fi
}

#========================
## Liferay set up
#========================
setup_bundle() {
  set_files_folder

  log_info "Setup bundle $LIFERAY_BUNDLE"
  touch $LIFERAY_HOME/.liferay-home

  log_debug tar -xzf $LIFERAY_BUNDLE -C $LIFERAY_HOME/
  log_debug mv $LIFERAY_HOME/$LIFERAY_BUNDLE_FOLDER_NAME/* $LIFERAY_HOME/
  log_debug rm -Rf $LIFERAY_HOME/$LIFERAY_BUNDLE_FOLDER_NAME

  log_info "Copying common and local files..."
  
  ## Copy OSGi Properties
  log_debug find configs/common -name \*.config -exec cp -rv {} $LIFERAY_HOME/osgi/configs \;
  
  ## Copy Portal Properties
  log_debug find configs/common -name \*.properties -exec cp -rv {} $LIFERAY_HOME \;
  log_debug find configs/local -name \*.properties -exec cp -rv {} $LIFERAY_HOME \;
  
  ## Copy Tomcat Files
  #log_debug find lcp/liferay/config/common/tomcat -exec cp -rv {} $LIFERAY_HOME/tomcat-9.0.17 \;
  log_debug cp -R configs/local/tomcat-$TOMCAT_VERSION $LIFERAY_HOME
}

remove_bundle() {
  log_info "=> TASK: remove_bundle"
  read -p "This action will delete all the files inside ($LIFERAY_HOME) folder. Do you really want to proceed? [y/n]: " key
  if [[ $key = "y" ]]; then 
    stop_server
    mail_catcher_stop

    log_debug rm -rf $LIFERAY_HOME
    log_debug mkdir $LIFERAY_HOME
    log_debug rm -rf dump
    log_debug find . -name 'build' -type d -prune -exec rm -rf '{}' +
    log_debug find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +
    log_debug find . -name 'dist' -type d -prune -exec rm -rf '{}' +
  else
    exit 1
  fi
}

clean_temps(){
  log_info "=> TASK: clean_temps"

  log_info "Cleaning temp files..."
  log_debug rm -rf $LIFERAY_HOME/work $LIFERAY_HOME/osgi/state $LIFERAY_HOME/$TOMCAT_VERSION/work $LIFERAY_HOME/$TOMCAT_VERSION/temp
}

stop_server() {
  log_info "=> TASK: stop_server"
  log_info "Stopping liferay..."
  if [ -d "$LIFERAY_HOME" ]; then
    blade server stop
  fi
}

start_server() {
  log_info "=> TASK: start_server"
  blade server start -d
  show_logs
}

build_project() {
  log_info "=> TASK: build_project"
  log_debug blade gw deploy
}

#========================
## Debug
#========================
show_logs() {
  log_info "=> TASK: show_logs"
  while ! log_debug tail -f $LIFERAY_HOME/tomcat-$TOMCAT_VERSION/logs/catalina.out ; do sleep 1 ; done
}

log_date() {
  echo $(date '+%Y-%m-%d %H:%M:%S') "$@"
}

log_debug() {
  log_date "DEBUG.: " "$blue" "$@" "$white"
  "$@"
}

log_info() {
  echo "-------------------"
  log_date "INFO..: " "$cyan" "$@" "$white"
  echo "-------------------"
}

log_error() {
  echo "-------------------"
  log_date "ERROR..: " "$red" "$@" "$white"
  echo "-------------------"
}

log_warn() {
  echo "-------------------"
  log_date "WARN..: " "$yellow" "$@" "$white"
  echo "-------------------"
}

#========================
## Commands
#========================
init_command() {
  remove_bundle
  remove_docker_db
  create_docker_db
  setup_bundle
  load_backup
  mail_catcher_up
  deploy_license
  #apply_patches
  build_project
  start_server
}

init_clean_command() {
  stop_server
  remove_bundle
  remove_docker_db
  init_bundle
  deploy_license
  #apply_patches
  create_docker_db
  start_server
  show_logs
}

save_state_command() {
  save_state
}

load_state_command() {
  stop_server
  remove_docker_db
  clean_temps
  create_docker_db
  load_backup
  start_server
  show_logs
}

build_project_command(){
  build_project
}

clean_temps_command(){
  clean_temps
}

#========================
## Interface
#========================
case "${COMMAND}" in
  init ) init_command
        exit 0
        ;;
  saveState ) save_state_command
        exit 0
        ;;
  loadState ) load_state_command
        exit 0
        ;;
  deploy ) build_project_command
        exit 0
        ;;
  clean ) clean_temps_command
        exit 0
        ;;
  stop ) stop_server
      exit 0
      ;;
  start ) start_server
      exit 0
      ;;
  emailup ) mail_catcher_up
        exit 0
        ;;
  emailstop ) mail_catcher_stop
        exit 0
        ;;
   logs ) show_logs
        exit 0
        ;; 
  *)
      echo $"Usage:" "$0" "{init | saveState | loadState | deploy | clean | stop | start | emailup | emailstop | logs}"
      exit 1
esac
exit 0