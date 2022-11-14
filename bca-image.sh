# This code should be run as part of Dockerfile and burned into image
# for all data science workbench images

# oracle: libaio1
# postgres: libpq-dev

apt-get install -y build-essential vim git make unzip zip curl
apt-get install -y libpq-dev libaio1

# add saml2aws
SAML2AWS_VERSION=2.36.0
wget https://github.com/Versent/saml2aws/releases/download/v${SAML2AWS_VERSION}/saml2aws_${SAML2AWS_VERSION}_linux_amd64.tar.gz
sudo tar -xzvf saml2aws_${SAML2AWS_VERSION}_linux_amd64.tar.gz -C /usr/local/bin
sudo chmod +x /usr/local/bin/saml2aws
rm saml2aws_${SAML2AWS_VERSION}_linux_amd64.tar.gz

# install awscli v2
wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" 
unzip -q awscli-exe-linux-x86_64.zip 
sudo ./aws/install
rm awscli-exe-linux-x86_64.zip
rm -r aws/

# Install Gurobi --------------------------------------------------------------#

# aws s3 cp s3://eap-nonprod-s3-artifacts/gurobi/952/gurobi9.5.2_linux64.tar.gz /opt/gurobi9.5.2_linux64.tar.gz || \
#   aws s3 cp s3://eap-prod-s3-artifacts/gurobi/952/gurobi9.5.2_linux64.tar.gz /opt/gurobi9.5.2_linux64.tar.gz

aws s3 cp s3://testmlflow2/files/gurobi10.0.0_linux64.tar.gz
tar xvfz /opt/gurobi9.5.2_linux64.tar.gz --directory /opt
rm /opt/gurobi9.5.2_linux64.tar.gz
cd /opt/gurobi952/linux64 && python /opt/gurobi952/linux64/setup.py install
ln -s /opt/gurobi952/linux64/lib/libgurobi95.so /usr/local/lib && ldconfig

# prepare gurobi environment
echo 'export GUROBI_HOME=/opt/gurobi952/linux64
export PATH=$PATH:$GUROBI_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GUROBI_HOME/lib' > ~/.it_bashrc

# Install Julia ---------------------------------------------------------------#

cd /opt
wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.2-linux-x86_64.tar.gz
tar zxvf julia-1.8.2-linux-x86_64.tar.gz
rm julia-1.8.2-linux-x86_64.tar.gz

# prepare julia environment >> Append to ~/.it_bashrc
echo 'export JULIA_HOME=/opt/julia-1.8.2
export PATH=$PATH:$JULIA_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JULIA_HOME/lib' >> ~/.it_bashrc
