#!/bin/bash
set -e

clear
#Preparing mendatory directories, packages and requirements
echo -e "-x-x-x-x-x-x- Preparing mendatory directories, packages and requirements -x-x-x-x-x-x-\n";
current_date_time=`date +%FT%T`
echo -e ${env}/bin/activate;


echo "**************starting docker************"
cd ${project_path}; docker-compose down; docker-compose up -d;
sleep 10
echo "**************background docker************"

cd ${project_path}
sudo -E -H ${env}/bin/pip install -q -r requirements.txt
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
echo -e ${settings};


export PYTHONPATH=${project_path};
export DJANGO_SETTINGS_MODULE=${settings}
export HOST_NAME=${host_addr}
export DB_NAME=${dbname}
export DB_USERNAME=${psql_username}
export DB_PASSWORD=${psql_password}
export DB_HOST=${psql_host}
export DB_PORT=${psql_port}
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

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
echo -e "psql username : ${psql_username}";
echo -e "psql password : ${psql_password}";
echo -e "psql host : ${psql_host}";
echo -e "psql port : ${mysql_port}";
echo -e "Selected Project Setting is :  ${settings}";
echo -e "Selected site : ${site}";
echo -e "Migration deletion default : ${choice}";
echo -e "Nginx conf file path is : ${nginx_config_file_name}";
echo -e "Superuser email is : ${superuser_email}";
echo -e "Superuser password is : ${superuser_password}";
echo -e "Import server dump default is: ${dump_choice}";
echo -e "S3 backup default is: ${is_s3_backup_required}";
echo -e "Nginx port no is: ${nginx_port_no}";
echo -e "Gunicorn port no is: ${gunicorn_port_no}";
echo -e "Multiple projects is: ${multiple_projects}";
echo -e "Nginx timeout : ${timeout}";
echo -e "Nginx keep_alive_timeout : ${keep_alive_timeout}";
echo -e "Nginx graceful_timeout : ${graceful_timeout}";
echo -e "Worker count is : ${worker_count}";

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



#post deploy tasks
cd ${project_path};

sudo -E -H ${env}/bin/python manage.py makemigrations
sudo -E -H ${env}/bin/python manage.py migrate
echo -e "\n\n-x-x-x-x-x-x- Collecting static files -x-x-x-x-x-x-\n"
sudo -E -H ${env}/bin/python manage.py collectstatic --noinput --verbosity 0

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
sudo -E -H ${env}/bin/gunicorn  --keep-alive ${keep_alive_timeout} --timeout ${timeout} --graceful-timeout ${graceful_timeout} --workers ${worker_count:-"1"} --bind 127.0.0.1:${gunicorn_port_no} ${wsgi_app} --access-logfile /var/log/gunicorn-access.log --error-logfile /var/log/gunicorn-error.log --log-level DEBUG   --reload &

echo -e "\n\n-x-x-x-x-x-x- Reloading nginx -x-x-x-x-x-x-\n"
sudo nginx || true
