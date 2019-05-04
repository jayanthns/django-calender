#!/bin/bash
set -e

clear
#Preparing mendatory directories, packages and requirements
echo -e "-x-x-x-x-x-x- Preparing mendatory directories, packages and requirements -x-x-x-x-x-x-\n";
current_date_time=`date +%FT%T`
echo -e ${env}/bin/activate;
mkdir -p ${project_path}/log
declare -a logfiles=("debug" "info" "error" "critical")
for i in "${logfiles[@]}"
do
    sudo -E -H  touch ${project_path}/log/${i}.log
done
sudo chmod -R 777 ${project_path}/log/
echo "**************starting docker************"
cd ${project_path}; docker-compose -f docker-compose-backup.yml down; docker-compose -f docker-compose-backup.yml up &
sleep 10
echo "**************background docker************"
mkdir -p ${project_path}/backup
mkdir -p ${project_path}/static/uploads;
if [ ! -z "${mysql_password}" ]
then
    mysql_password_str="-p${mysql_password}"
else
    mysql_password_str=""
fi
echo "****************password of mysql****************"
echo ${mysql_password_str}
echo "**************end of passwod**********************"
sleep 20
sudo -E -H mysql_tzinfo_to_sql /usr/share/zoneinfo/ | mysql -u"${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" mysql --force || true

if ! $(gem list wkhtmltopdf-binary -i);
then
#    sudo apt-get install libxrender1
    echo "Gem wkhtmltopdf-binary is not installed!"
    sudo -E -H gem install wkhtmltopdf-binary || true
fi
cd ${project_path}
sudo -E -H ${env}/bin/pip install -q -r requirements.pip
file="/var/log/gunicorn-access.log"
if [[ ! -f ${file} ]]; then
  sudo touch ${file}
fi
file="/var/log/gunicorn-error.log"
if [[ ! -f ${file} ]]; then
  sudo touch ${file}
fi

#Exporting environment variables
echo -e "\n\n-x-x-x-x-x-x- Exporting environment variables -x-x-x-x-x-x-\n";
echo -e "main.settings.${settings}";


export PYTHONPATH=${project_path};
export DJANGO_SETTINGS_MODULE="main.settings.${settings}"
export HOST_NAME=${host_addr}
export DB_NAME=${dbname}
export DB_USERNAME=${mysql_username}
export DB_PASSWORD=${mysql_password}
export DB_HOST=${mysql_host}
export DB_PORT=${mysql_port}
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#Cache prevention enabling
echo -e "\n\n-x-x-x-x-x-x- Cache prevention enabling -x-x-x-x-x-x-\n"
echo "from common.helper import prevent_cache; prevent_cache();" | ${env}/bin/python manage.py shell


#Setting up os based environment
echo -e "\n\n-x-x-x-x-x-x- Setting up os based environment -x-x-x-x-x-x-\n"
if [ ${os} == "linux" ]
then
    nginx_suffix=""
    nginx_stop_command="sudo service nginx stop > /dev/null 2>&1 || true"
    sudo apt-get install zip
    sudo apt-get install unzip
    which ffmpeg
    if [ $? == 1 ]; then
        sudo apt-get install ffmpeg
    fi
    # ./scripts/install_ffmpeg_ubuntu.sh
else
    nginx_suffix="/usr/local"
    nginx_stop_command="sudo nginx -s stop > /dev/null 2>&1 || true"
    # HOMEBREW_NO_AUTO_UPDATE=1 brew install ffmpeg
fi

if [ ! -d ${nginx_suffix}/etc/nginx/sites-enabled/ ];
then
    echo -e " ${nginx_suffix}/etc/nginx/sites-enabled/ directory does not exist, please add it and include 'include /usr/local/etc/nginx/sites-enabled/*;' in nginx.conf http section."
    exit 1
fi

clear
echo -e "Default values : ";
echo -e "****************";
echo -e "Selected OS is  : ${os}";
echo -e "Workspace path is : ${workspace_path}";
echo -e "Activated Virtual Environment is : ${env}";
echo -e "Project path is : ${project_path}";
echo -e "HostName is : ${host_addr}";
echo -e "Selected database is : ${dbname}";
echo -e "MySql username : ${mysql_username}";
echo -e "MySql password : ${mysql_password}";
echo -e "MySql host : ${mysql_host}";
echo -e "MySql port : ${mysql_port}";
echo -e "Selected Project Setting is :  ${settings}";
echo -e "Selected site : ${site}";
echo -e "Migration deletion default : ${choice}";
echo -e "Nginx conf file path is : ${nginx_config_file_name}";
echo -e "Superuser email is : ${superuser_email}";
echo -e "Superuser password is : ${superuser_password}";
echo -e "Superuser mobile number is : $superuser_mobile";
echo -e "Import server dump default is: ${dump_choice}";
echo -e "Initial sql path is: ${sql_script}";
echo -e "Server dump path is: ${server_dump}";
echo -e "Maintenance page path is : ${maintenance_page_path}";
echo -e "S3 backup default is: ${is_s3_backup_required}";
echo -e "Nginx port no is: ${nginx_port_no}";
echo -e "Gunicorn port no is: ${gunicorn_port_no}";
echo -e "Multiple projects is: ${multiple_projects}";
echo -e "Nginx timeout : ${timeout}";
echo -e "Nginx keep_alive_timeout : ${keep_alive_timeout}";
echo -e "Nginx graceful_timeout : ${graceful_timeout}";
echo -e "Worker count is : ${worker_count}";

echo -e "\n\nContinue with default values ? (y/n) (Default is y): ";
read do_continue;
do_continue=${do_continue:-"y"};

if [ "${do_continue}" == "y" -o "${do_continue}" == "Y" ]
then
  echo -e "\nDo you want to remove all migrations (y/n) (Default choice is ${choice}): ";
  read input;
  choice=${input:-${choice}};
  echo -e "Migration deletion default : ${choice}"

  if [ "${choice}" == "y" -o "${choice}" == "Y" ]
  then
      echo -e "\nDo you want to dump server sql (y/n) (Default choice is ${dump_choice}): ";
      read input;
      dump_choice=${input:-${dump_choice}};
      echo -e "Import server dump default is: ${dump_choice}";
   fi
fi


#Configuring Nginx
echo -e  "\n\n-x-x-x-x-x-x- Configuring Nginx -x-x-x-x-x-x-\n";
sudo rm -v "${nginx_suffix}/etc/nginx/sites-enabled/${site}" || true;
mkdir -p "${nginx_suffix}/etc/nginx/sites-available/";
ls "${nginx_suffix}/etc/nginx/sites-available/";
cd "${nginx_suffix}/etc/nginx/sites-available/";
if [ -e "${site}" ]
then
  sudo rm "${nginx_suffix}/etc/nginx/sites-available/${site}" || true;
fi
conf_content=$(eval "echo \"$(cat ${nginx_config_file_name})\"")
sudo sh -c "echo '${conf_content}' >> ${nginx_suffix}/etc/nginx/sites-available/${site}";
sudo ln -s "${nginx_suffix}/etc/nginx/sites-available/${site}" "${nginx_suffix}/etc/nginx/sites-enabled/" || true

echo -e "\n\n-x-x-x-x-x-x- Site enabled is -x-x-x-x-x-x-\n";
ls "${nginx_suffix}/etc/nginx/sites-enabled/";


#Running scheduler in background, Check /tmp/mnmSchedulerOutput.txt
echo -e  "\n\n-x-x-x-x-x-x- Running scheduler in background, Check /tmp/mnmSchedulerOutput.txt -x-x-x-x-x-x-\n";
if [ "${is_s3_backup_required}" == "y" -o "${is_s3_backup_required}" == "Y" ]
    then
    cd ${project_path}
    nohup ${env}/bin/python ${project_path}/common/util/schedulerHelper.py > /tmp/mnmSchedulerOutput.txt 2>&1 &
fi

function migrate_db(){
    clear
    echo -e "\nDo you want to migrate ? (y/n) (Default is y): ";
    read make_migrate;
    make_migrate=${make_migrate:-"y"};
    if [ "${make_migrate}" == "y" -o "${make_migrate}" == "Y" ]
    then
        #Makin migrations
        cd ${project_path}
        echo -e "\n\n-x-x-x-x-x-x- Making migrations -x-x-x-x-x-x-\n"
        ${env}/bin/python manage.py makemigrations --verbosity 0
        ${env}/bin/python manage.py makemigrations --merge --verbosity 0
        echo -e "\n\n-x-x-x-x-x-x- Migrating -x-x-x-x-x-x-\n"
        ${env}/bin/python manage.py migrate --verbosity 1
        echo -e "\nDo you want to re-migrate ? (y/n) (Default is n): ";
        read re_make_migrate;
        re_make_migrate=${re_make_migrate:-"n"};
        if [ "${re_make_migrate}" == "y" -o "${re_make_migrate}" == "Y" ]
        then
            migrate_db
        fi
    fi
}
if [ "${choice}" == "y" -o "${choice}" == "Y" ]
then
    #Backing up and removing database
    echo -e "\n\nBacking up and removing database : \n"
    cd "${project_path}/app"
    #Removing migrations
    echo -e "\n\nRemoving migrations : \n"
    mkdir -p ${project_path}/backup/${current_date_time};
    sudo -E -H rsync -azq --verbose --exclude="*.pyc" --include='*/' --include='*/migrations/***' --exclude="*" ${project_path}/app/ ${project_path}/backup/${current_date_time}/app/
    sudo find . -path '*/migrations/__init__.py' -exec truncate -s 0 {} + -o -path '*/migrations/*' -delete || true

    #Setting up database
    echo -e "\n\nSetting up database : \n"
    result=$(mysql -u"${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" --batch --skip-column-names -e "SHOW DATABASES LIKE '"${dbname}"';" | grep "${dbname}" > /dev/null; echo "$?")
    if [ "${result}" -eq 0 ]
    then
        #Backing up database
        echo -e "\n\nBacking up database : ${dbname}\n"
        if [ ${os} == "linux" ]
        then
            mysqldump -u"${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" ${dbname} --ignore-table=${dbname}.django_migrations --ignore-table=${dbname}.django_content_type --ignore-table=${dbname}.django_admin_log --ignore-table=${dbname}.django_ses_sesstat --ignore-table=${dbname}.django_session > ${project_path}/backup/${current_date_time}/${dbname}.sql
            mysqldump -u"${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" ${dbname} > ${project_path}/backup/${current_date_time}/${dbname}_full.sql
        else
            mysqldump --column-statistics=0 -u"${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" ${dbname} --ignore-table=${dbname}.django_migrations --ignore-table=${dbname}.django_content_type --ignore-table=${dbname}.django_admin_log --ignore-table=${dbname}.django_ses_sesstat --ignore-table=${dbname}.django_session > ${project_path}/backup/${current_date_time}/${dbname}.sql
            mysqldump --column-statistics=0 -u"${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" ${dbname} > ${project_path}/backup/${current_date_time}/${dbname}_full.sql
        fi
    fi
    mysql -u "${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" -e "DROP DATABASE ${dbname}" || true
    echo -e "\n\nCreating database : ${dbname}\n"
    mysql -u "${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" -e "CREATE DATABASE ${dbname} CHARACTER SET utf8 COLLATE utf8_general_ci;" || true

    #Making backup folder zip
    cd ${project_path}/backup/;
    zip -qr $(eval "echo \"${current_date_time}_${host}.zip\"") ${current_date_time}
    if [ "${is_s3_backup_required}" == "y" -o "${is_s3_backup_required}" == "Y" ]
    then
        cd ${project_path};
        echo "from common.helper import upload_file; upload_file('${current_date_time}_${host}.zip','migration_with_sql');" | ${env}/bin/python manage.py shell
    fi
    if [ "${dump_choice}" == "y" -o "${dump_choice}" == "Y" ]
    then
        #Importing from server dump
        echo -e "\n\n-x-x-x-x-x-x- Importing from server dump -x-x-x-x-x-x-\n"
        mysql -u "${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" ${dbname} < ${server_dump} || true
    else
        #Importing from initial sql
        echo -e "\n\n-x-x-x-x-x-x- Importing from initial sql -x-x-x-x-x-x-\n"
        migrate_db
        echo -e "\n\nCreating superuser with Mobile Number: ${superuser_mobile} and Email: ${superuser_email} and Password: ${superuser_password}\n";
        echo "from app.accounts.models import User; User.objects.create_superuser(email='${superuser_email}', mobile_number='${superuser_mobile}', password='${superuser_password}', **{'first_name': 'Admin'})" | ${env}/bin/python manage.py shell
        echo -e "\n\nInitial insertion : \n"
        mysql -u "${mysql_username}" ${mysql_password_str} -h"${mysql_host}" -P"${mysql_port}" ${dbname} -e "set @host='${host}'; `cat ${sql_script}`" || true
    fi
    cd ${project_path};
    echo "from common.helper import one_time_run; one_time_run();" | ${env}/bin/python manage.py shell
fi
migrate_db
#post deploy tasks
cd ${project_path};
echo -e "\n\n-x-x-x-x-x-x- Collecting static files -x-x-x-x-x-x-\n"
sudo -E -H ${env}/bin/python manage.py collectstatic --noinput --verbosity 0
file="${maintenance_page_path}/maintenance_on.html"
if [[ -f ${file} ]]; then
  maintenance_on=true
fi
file="${maintenance_page_path}/maintenance_off.html"
if [[ -f ${file} ]]; then
  maintenance_off=true
fi
if [ "${maintenance_on}" = true -a "${maintenance_off}" = true ] ; then
    sudo rm "${maintenance_page_path}/maintenance_on.html"
fi

#Clearing required ports
echo -e "\n\n-x-x-x-x-x-x- Stopping processes running at port ${nginx_port_no} & ${gunicorn_port_no} -x-x-x-x-x-x-\n"
sudo kill $(sudo lsof -ti :${nginx_port_no} -ti :${gunicorn_port_no}) > /dev/null 2>&1 || true

if [ "${multiple_projects}" != "y" -a "${multiple_projects}" != "Y" ]
then
    #Stopping previous nginx & gunicorn instances
    echo -e "\n\n-x-x-x-x-x-x- Stopping previous nginx & gunicorn instances -x-x-x-x-x-x-\n";
    # eval ${nginx_stop_command}
    sudo kill $(ps aux | grep "[n]ginx\|[g]unicorn" | awk '{print $2}') > /dev/null 2>&1 || true
    sleep 2
fi

echo -e "\n\n-x-x-x-x-x-x- Reloading gunicorn -x-x-x-x-x-x-\n"
sudo -E -H ${env}/bin/gunicorn  --keep-alive ${keep_alive_timeout} --timeout ${timeout} --graceful-timeout ${graceful_timeout} --workers ${worker_count:-"1"} --bind 127.0.0.1:${gunicorn_port_no} main.wsgi:application --access-logfile /var/log/gunicorn-access.log --error-logfile /var/log/gunicorn-error.log --log-level DEBUG   --reload &

echo -e "\n\n-x-x-x-x-x-x- Reloading nginx -x-x-x-x-x-x-\n"
sudo nginx || true%