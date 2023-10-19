#!/bin/bash

labauto ansible

set-hostname -skip-apply ${component}

ansible-pull -i localhost, -U https://github.com/sairm21/roboshop-ansible-v1 -e env=${env} -e role_name=${component} main.yml &>> /opt/ansible.log
