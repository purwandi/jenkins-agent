FROM jenkins/agent:4.10-3-alpine as jagent
FROM jenkins/inbound-agent:4.10-3-alpine as jiagent
FROM r.j3ss.co/img as img

FROM centos:8 AS idmap
RUN yum install -y autoconf automake gcc gcc-c++ make byacc gettext gettext-devel gcc git libtool libxslt
RUN git clone https://github.com/shadow-maint/shadow.git /shadow
WORKDIR /shadow
RUN git checkout 59c2dabb264ef7b3137f5edb52c0b31d5af0cf76
RUN ./autogen.sh --disable-nls --disable-man --without-audit --without-selinux --without-acl --without-attr --without-tcb --without-nscd \
  && make && cp src/newuidmap src/newgidmap /usr/bin

ENV HELM_VERSION v3.8.0
ENV OC_VERSION 4.7.40
ENV NEXUS_VERSION 1.124.0-01
ENV CRANE_VERSION 0.8.0
ENV TRIVY_VERSION 0.23.0

WORKDIR /workspace
ADD . .

USER root
RUN microdnf install -y curl tar wget gzip --nodocs --setopt=install_weak_deps=0 --best \
    && microdnf clean all

# helm 
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm

# openshift client
RUN curl -Lo /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v$(echo $OC_VERSION | cut -d'.' -f 1)/amd64/clients/ocp/$OC_VERSION/openshift-client-linux-$OC_VERSION.tar.gz \
  && tar xzvf /tmp/oc.tar.gz -C /usr/local/bin/ 

# crane
RUN curl -Lo /tmp/crane.tar.gz https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz -O \
  && tar xzvf /tmp/crane.tar.gz -C /usr/local/bin/ 

# nexus-cli
# https://help.sonatype.com/iqserver/product-information/download-and-compatibility
RUN curl -u $nexus_username:$nexus_password https://nexus.appsnp.ocbcnisp.com:8443/repository/repo_raw_hosted/fortify/nexus-iq-cli-${NEXUS_VERSION}.jar \
  -o /tmp/nexus-iq-cli.jar

# trivy
RUN curl -Lo /tmp/trivy.tar.gz https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz -O \
  && tar xzvf /tmp/trivy.tar.gz -C /tmp/ 

COPY --from=idmap /usr/bin/newuidmap /usr/bin/newuidmap
COPY --from=idmap /usr/bin/newgidmap /usr/bin/newgidmap
COPY --from=img   /usr/bin/img /usr/bin/img

COPY --from=jagent  /usr/share/jenkins/agent.jar  /usr/share/jenkins/agent.jar
COPY --from=jiagent /usr/local/bin/jenkins-agent  /usr/local/bin/jenkins-agent