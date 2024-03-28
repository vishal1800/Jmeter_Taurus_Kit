# Use a base image with your preferred Linux distribution
FROM ubuntu:latest

# Install OpenJDK (Java)
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk

# Install Python
RUN apt-get install -y python3

# Install curl and gnupg
RUN apt-get update && apt-get install -y curl gnupg



# Install kubectl

RUN apt-get update && apt-get install -y apt-transport-https curl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update && apt-get install -y kubelet kubeadm kubectl


# Set environment variables
ENV JMETER_HOME /opt/jmeter
ENV JMETER_BIN ${JMETER_HOME}/bin
ENV PATH $PATH:${JMETER_BIN}

# Install JMeter
RUN apt-get update \
    && apt-get install -y wget \
    && mkdir -p /opt/jmeter \
    && wget --show-progress -qO- https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.5.tgz | tar xvz -C /opt/jmeter --strip-components=1

# Install JMeter Plugins Manager
RUN wget --no-check-certificate -O ${JMETER_HOME}/lib/ext/jmeter-plugins-manager-1.6.jar https://jmeter-plugins.org/get/

# Copy local cmdrunner-2.3.jar into the container
COPY ./cmdrunner-2.3.jar ${JMETER_BIN}/../lib/

COPY ./PluginsManagerCMD.sh ${JMETER_BIN}

# Set execute permissions for PluginsManagerCMD.sh
RUN chmod +x ${JMETER_BIN}/PluginsManagerCMD.sh

# Install JMeter Plugins using the local PluginsManagerCMD.sh
RUN ${JMETER_BIN}/PluginsManagerCMD.sh install jpgc-casutg,jpgc-json,jpgc-standard,jpgc-dummy,jpgc-ffw,jpgc-fifo,jpgc-functions,jpgc-perfmon,jpgc-prmctl,jpgc-tst

#RUN ${JMETER_BIN}/PluginsManagerCMD.sh install jpgc-casutg,jpgc-json,jpgc-standard
#${JMETER_BIN}/PluginsManagerCMD.sh install jpgc-casutg,jpgc-json,jpgc-standard

# Clean up
RUN rm -rf /tmp/hsperfdata_root /tmp/PluginManagerCMD.sh

# Install Taurus
RUN apt-get install -y python3-pip && \
    pip3 install bzt

# Install kubectl
RUN apt-get update && apt-get install -y kubelet kubeadm kubectl

# Set Results Directory
RUN mkdir /mnt/results

# Set Results Directory for config file
RUN mkdir /mnt/taurus-config

# Add write permissions to the below directory
#RUN chmod -R 777 /mnt/taurus-config/

# Set Working Directory for config file
RUN mkdir /mnt/jmeter

# Set working directory
WORKDIR /mnt/jmeter/

# Set CMD to run the bzt command
CMD ["bzt", "taurus_execution.yaml"]



