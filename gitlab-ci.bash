#!/bin/bash

# Determine ROS_DISTRO
#---------------------
ROS_DISTRO=$(ls /opt/ros/)

if [ -z "$ROS_DISTRO" ]; then
  echo "No ROS distribution was found in /opt/ros/. Aborting!"
  exit -1
fi

# Source ROS
#-----------
source /opt/ros/$ROS_DISTRO/setup.bash &>/dev/null

# Install catkin tools # https://catkin-tools.readthedocs.io/en/latest/installing.html
#---------------------
apt-get update &>/dev/null
apt-get install -qq wget &>/dev/null
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list' &>/dev/null
wget http://packages.ros.org/ros.key -O - | apt-key add - &>/dev/null
apt-get update &>/dev/null
apt-get install -qq python-catkin-tools &>/dev/null
export TERM=xterm # Makes catkin build output less ugly

# Install ROS packages required by the user
#------------------------------------------
# Split packages into package list
IFS=' ' read -ra PACKAGES <<< "$ROS_PACKAGES_TO_INSTALL"
# Clear packages list
ROS_PACKAGES_TO_INSTALL=""

# Append "ros-kinetic-" (eg for Kinetic) before the package name
# and append in the packages list
for package in "${PACKAGES[@]}"; do
    ROS_PACKAGES_TO_INSTALL="${ROS_PACKAGES_TO_INSTALL} ros-$ROS_DISTRO-$package"
done

# Install the packages
apt-get install -qq $ROS_PACKAGES_TO_INSTALL

# Display system information
#---------------------------
uname -a
lsb_release -a
gcc --version
cmake --version

# Prepare build
#--------------
# https://docs.gitlab.com/ce/ci/variables/README.html#predefined-variables-environment-variables
cd $CI_PROJECT_DIR/..
mkdir -p src
# Copy current directory into a src directory
# Don't move the original clone or GitLab CI fails!
cp -r $CI_PROJECT_DIR src/
mv src $CI_PROJECT_DIR
cd $CI_PROJECT_DIR

# If self testing
#----------------
if [ ! -z ${SELF_TEST+x} ]; then
  echo "SELF TESTING"
  cd $CI_PROJECT_DIR/src
  # We create a package beginner_tutorials so that the catkin workspace is not empty
  catkin_create_pkg beginner_tutorials std_msgs rospy roscpp
  cd $CI_PROJECT_DIR
fi
