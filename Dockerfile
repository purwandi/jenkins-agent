FROM r.j3ss.co/img as img

FROM rockylinux:8 as build
RUN yum install -y autoconf automake gcc gcc-c++ make byacc gettext gettext-devel gcc git libtool libxslt
RUN git clone https://github.com/shadow-maint/shadow.git /shadow
WORKDIR /shadow
RUN git checkout 59c2dabb264ef7b3137f5edb52c0b31d5af0cf76
RUN ./autogen.sh --disable-nls --disable-man --without-audit --without-selinux --without-acl --without-attr --without-tcb --without-nscd \
  && make && cp src/newuidmap src/newgidmap /usr/bin

FROM registry.access.redhat.com/ubi8-minimal

COPY --from=img     /usr/bin/img /usr/bin/img
COPY --from=build   /usr/bin/newuidmap /usr/bin/newuidmap
COPY --from=build   /usr/bin/newgidmap /usr/bin/newgidmap