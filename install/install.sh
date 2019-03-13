#!/bin/bash


set -e


# Manage arguments
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------

usage()
{
    cat <<EOF

    usage: $0 

    This script install the GOAL-Robots-competiotion env

    OPTIONS:
    -u --uninstall     uninstall
    -r --reinstall     reinstall
    -v --virtual_env   use a virtual env

EOF
}

INSTALL=true
UNINSTALL=false
VE=false

# getopt
GOTEMP="$(getopt -o "urvh" -l "uninstall,reinstall,virtual_env,help"  -n '' -- "$@")"

# if [[ -z "$(echo -n $GOTEMP |sed -e"s/\-\-\(\s\+.*\|\s*\)$//")" ]]; then
#     usage; exit;
# fi

eval set -- "$GOTEMP"

while true ;
do
    case "$1" in
        -u | --uninstall)
            INSTALL=false
            UNINSTALL=true
            break ;;
        -r | --reinstall)
            INSTALL=true
            UNINSTALL=true
            shift;;
        -v | --virtual_env)
            VE=true
            shift;; 
        -h | --help)
            usage; exit;
            shift;
            break;;
        --) shift ;
            break ;;
    esac
done

# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------

CURR_DIR=$(pwd)

SCRIPT=$(realpath -s $0)
SCRIPTPATH=$(dirname $SCRIPT)
ROBOSCHOOL_PATH=${HOME}/opt/roboschool


if [[ $UNINSTALL == true ]]; then
    pip3 uninstall roboschool || true
    [[ -d $ROBOSCHOOL_PATH ]] && rm -fr "$ROBOSCHOOL_PATH"
fi

if [[ $INSTALL == true ]]; then

    if [[ $UNINSTALL == false ]]; then
	if [[ -d $ROBOSCHOOL_PATH ]]; then 
	    echo "roboschool allready installed"
	    exit
	fi
    fi
    if [[ $VE == false ]]; then
        sudo apt install python3-pip
        pip3 install --user gym
        pip3 install --user pyOpenGL
    elif [[ $VE == true ]]; then
        pip3 install gym
        pip3 install pyOpenGL
    fi

    mkdir -p $ROBOSCHOOL_PATH
    sudo apt install -y \
        cmake ffmpeg pkg-config qtbase5-dev \
        libqt5opengl5-dev libassimp-dev libpython-dev \
        libboost-python-dev libtinyxml-dev

    cd $ROBOSCHOOL_PATH

    cp -r ${SCRIPTPATH}/../roboschool/* $ROBOSCHOOL_PATH
    git clone https://github.com/olegklimov/bullet3 -b roboschool_self_collision
    cd bullet3
    git apply ${SCRIPTPATH}/bullet.patch
    mkdir build
    cd build
    cmake \
        -DBUILD_SHARED_LIBS=ON -DUSE_DOUBLE_PRECISION=ON \
        -DCMAKE_INSTALL_PREFIX:PATH=$ROBOSCHOOL_PATH/roboschool/cpp-household/bullet_local_install \
        -DBUILD_CPU_DEMOS=OFF -DBUILD_BULLET2_DEMOS=ON \
        -DBUILD_EXTRAS=ON  -DBUILD_PYBULLET=ON -DBUILD_UNIT_TESTS=OFF \
        -DBUILD_CLSOCKET=OFF -DBUILD_ENET=OFF -DCMAKE_BUILD_TYPE=Release \
        ..
    make -j8
    make install
    
    echo install

    mkdir -p $ROBOSCHOOL_PATH/bin

    cp examples/SharedMemory/App_PhysicsServer_SharedMemory $ROBOSCHOOL_PATH/bin/physics_server
    cp $SCRIPTPATH/b3serv $ROBOSCHOOL_PATH/bin/

    cd $ROBOSCHOOL_PATH
    if [[ $VE == false ]]; then
        pip3 install --user -e .
    elif [[ $VE == true ]]; then
        pip3 install -e .
    fi


    echo "export PATH=\$PATH:$ROBOSCHOOL_PATH/bin" >> ${HOME}/.bashrc

fi

cd $CURR_DIR
