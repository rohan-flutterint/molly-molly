FROM ubuntu:latest

RUN apt-get update -y && apt-get install -y \
        apt-transport-https cmake libapr1-dev libaprutil1-dev \
        flex bison default-jdk libsqlite3-dev python g++ graphviz

RUN echo "deb https://dl.bintray.com/sbt/debian /" >> \
        /etc/apt/sources.list.d/sbt.list \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv \
        2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
  && apt-get update \
  && apt-get install -y sbt

COPY . /molly

RUN cd /molly/lib/c4 \
  && cmake . && make -j4 && mv src/libc4/libc4.so /usr/lib \
  && cd /molly/lib/z3 \
  && ./configure && cd build && make -j5 && make install

RUN cd /molly \
  && sbt update \
  && sbt "run-main edu.berkeley.cs.boom.molly.SyncFTChecker" || true

WORKDIR /molly
