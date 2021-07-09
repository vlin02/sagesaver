cd "$( dirname "${BASH_SOURCE[0]}" )"

function render_template() {
  eval "echo \"$(cat $1)\""
}

for arg in "$@"
do
    case $arg in
        -u|--username)
        DB_USER=$2
        shift
        shift
        ;;
        -p|--password)
        DB_PWD=$2
        shift
        shift
        ;;
        -d|--dev)
        DEV=true
        shift
        ;;
    esac
done

LOG_PATH=$(jq -r '.mysql.log_path' < /etc/sagesaver.conf)

# Premptively create mysql log and set public permissons before mysql does
if [ "$DEV" = true ] ; then
    touch $LOG_PATH
    chmod 777 $LOG_PATH
fi

rpm -Uvh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm 
yum install -y mysql-community-server
systemctl enable mysqld
systemctl start mysqld

TMP_PWD=$(echo $(grep 'temporary password' /var/log/mysqld.log)\
    | rev | cut -d ' ' -f 1 | rev)

mysqladmin --user=root --password=$TMP_PWD password $DB_PWD

mysql --user=root --password=$DB_PWD --execute="
RENAME USER 'root'@'localhost' TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
"

mysql --user=$DB_USER --password=$DB_PWD --execute="
SET GLOBAL log_output = 'FILE';
SET GLOBAL general_log_file = '$LOG_PATH';
SET GLOBAL general_log = 'ON';
"
