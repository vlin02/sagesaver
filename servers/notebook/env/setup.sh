# Required: -p [Jupyter Password]
# Optional: -h [Jupyter Port Number]

cd "$( dirname "${BASH_SOURCE[0]}" )"

function render_template() {
  eval "echo \"$(cat $1)\""
}

JPY_PORT=8888
for arg in "$@"
do
    case $arg in
        -p|--password)
        JPY_PWD=$2
        shift
        shift
        ;;
        --port)
        JPY_PORT=$2
        shift
        shift
        ;;
    esac
done

python3 -m venv ../root-env
source ../root-env/bin/activate
pip3 install -r requirements_root.txt
deactivate

su ec2-user -c "python3 -m venv /home/ec2-user/notebook-env"
source /home/ec2-user/notebook-env/bin/activate
pip3 install -r requirements_notebook.txt

JPY_SHA=$(
python3 - <<-EOF
from IPython.lib import passwd
print(passwd('$JPY_PWD'))
EOF
)

render_template jupyter_lab_config.py.tmpl \
    > /home/ec2-user/notebook-env/etc/jupyter/jupyter_lab_config.py
deactivate