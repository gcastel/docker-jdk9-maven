FROM phusion/baseimage:latest

# Pre-install
RUN \
  apt-get update && \
  apt-get install -y \
    libxt-dev zip pkg-config libX11-dev libxext-dev \
    libxrender-dev libxtst-dev libasound2-dev libcups2-dev libfreetype6-dev \
    mercurial ca-certificates-java build-essential wget && \
  rm -rf /var/lib/apt/lists/*

# User
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/javadev && \
    echo "javadev:x:${uid}:${gid}:JavaDev,,,:/home/javadev:/bin/bash" >> /etc/passwd && \
    echo "javadev:x:${uid}:" >> /etc/group && \
    echo "javadev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/javadev && \
    chmod 0440 /etc/sudoers.d/javadev && \
    chown ${uid}:${gid} -R /home/javadev

ENV JAVA_HOME=/opt/java-bin
ENV PATH=$JAVA_HOME/bin:$PATH

# We need JDK8 to build
RUN \
  wget --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.tar.gz

RUN \
  tar zxvf jdk-8u65-linux-x64.tar.gz -C /opt

# Let's get JDK9
RUN \
  cd /tmp && \
  hg clone http://hg.openjdk.java.net/jdk9/jdk9 openjdk9 && \ 
  cd openjdk9 && \
  sh ./get_source.sh 

RUN \
  cd /tmp/openjdk9 && \
  bash ./configure --with-cacerts-file=/etc/ssl/certs/java/cacerts --with-boot-jdk=/opt/jdk1.8.0_65

RUN \  
  cd /tmp/openjdk9 && \
  make clean images

RUN \  
  cd /tmp/openjdk9 && \
  cp -a build/linux-x86_64-normal-server-release/images/jdk \
    /opt/openjdk9 

RUN \  
  cd /tmp/openjdk9 && \
  find /opt/openjdk9 -type f -exec chmod a+r {} + && \
  find /opt/openjdk9 -type d -exec chmod a+rx {} +

ENV PATH /opt/openjdk9/bin:$PATH
ENV JAVA_HOME /opt/openjdk9 

# Maven
RUN mkdir /apache-maven
RUN curl -fSL http://apache.mirrors.ovh.net/ftp.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz -o maven.tar.gz \
	&& tar -xvf maven.tar.gz -C apache-maven --strip-components=1 \
	&& rm maven.tar.gz*


ENV PATH /opt/openjdk9/bin:/opt/apache-maven/bin:$PATH

USER javadev
WORKDIR /home/javadev
VOLUME /home/javadev
