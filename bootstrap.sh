#######################################################################
# Deploy Cloud native Technologies into a particular Oracle Container Engine for Kubernetes cluster.
# This version created by Carlos Rodriguez Iturria (https://www.linkedin.com/in/citurria/)
#######################################################################
#################### Reading and validating passed parameters and mandatory files:

# Checking if Private key exists:
cp -r /vagrant/ssh /home/vagrant/ssh
chmod 400 /home/vagrant/ssh/*

if [ ! -f /home/vagrant/ssh/id_rsa_pri.pem ]; then
    echo "Private key doesn't exist. Make sure /home/vagrant/ssh/id_rsa_pri.pem exists!"
    exit 1
fi

if [ "$#" -ne 5 ]; then

    echo "**************************************** Error: "
    echo " Illegal number of parameters."
    echo " Order: [TENANCY_OCID USER_OCID PUB_KEY_FINGERPRINT OKE_OCID REGION_SHORTNAME]"
    echo " Example: ./bootstrap.sh TENANCY_OCID USER_OCID PUB_KEY_FINGERPRINT OKE_OCID us-ashburn-1"
    echo "****************************************"
    exit 1
    
fi

TENANCY_OCID=$1
USER_OCID=$2
PUB_KEY_FINGERPRINT=$3
OKE_OCID=$4
REGION_SHORTNAME=$5


    echo "##########################################################################"
    echo "###################### Updating packages ##############################"

    sudo apt-get update

    echo "##########################################################################"    
    echo "###################### Installing Git ##############################"

    sudo apt-get install git -y
   
    echo "##########################################################################"
    echo "############### Installing NodeJS on an Ubuntu Machine ###############"

    sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

    sudo apt-get install nodejs -y

    echo "##########################################################################"
    echo "############# Installing and configuring Docker for Dev #######################"

    sudo apt-get install docker.io -y
    sudo usermod -G docker ubuntu
    sudo usermod -G docker vagrant
    docker --version

    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

    sudo apt-get update

    sudo apt-get install docker-ce -y --force-yes

    echo "############################################################################################################"
    echo "########### Installing and Configuring Node-Oracledb with Oracle DB Instant Client ##############################"
    #  See: https://oracle.github.io/node-oracledb/ 

    sudo apt-get install libaio1 -y

    echo "export LD_LIBRARY_PATH=/vagrant/oradbInstantClient" >> /home/vagrant/.bashrc && echo "export TNS_ADMIN=/vagrant/oradbInstantClient/network/admin" >> /home/vagrant/.bashrc && bash
    # See: https://oracle.github.io/odpi/doc/installation.html#linux


    echo "##########################################################################"
    echo "############### Installing Kubectl for target OKE cluster ########################"

    # Configuring kubectl under vagrant user:
    sudo su vagrant

    echo " ################## Installing OCI CLI:"
    bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh) --accept-all-defaults"
    bash # Used to get oci cli available on this bash straightaway.


    echo " ################## Configuring .oci/config:"
    #    Interactive way: bash oci setup config

    mkdir -p /home/vagrant/.oci && cp /vagrant/oci/config_template /home/vagrant/.oci/config

    sed -i "s/@USER_OCID@/${USER_OCID}/g" /home/vagrant/.oci/config
    sed -i "s/@PUB_KEY_FINGERPRINT@/${PUB_KEY_FINGERPRINT}/g" /home/vagrant/.oci/config
    sed -i "s/@TENANCY_OCID@/${TENANCY_OCID}/g" /home/vagrant/.oci/config
    sed -i "s/@REGION_SHORTNAME@/${REGION_SHORTNAME}/g" /home/vagrant/.oci/config

    echo " ################## Downloading kube config file for a particular oke cluster tenancy:"
    mkdir -p /home/vagrant/.kube
    oci ce cluster create-kubeconfig --cluster-id $OKE_OCID --file /home/vagrant/.kube/config --region $REGION_SHORTNAME

    echo " ################## Installing kubectl now that we've got the kube config file:"
    sudo apt-get update && sudo apt-get install -y apt-transport-https

    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update

    sudo apt-get install kubectl

    echo " ################## Testing kubectl:"
    kubectl get nodes