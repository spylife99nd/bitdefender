FROM debian:jessie

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/blacktop.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

COPY bd_fix.sh /go/src/github.com/malice-plugins/bitdefender/bd_fix.sh
RUN buildDeps='ca-certificates \
               build-essential \
               gdebi-core \
               libssl-dev \
               mercurial \
               git-core \
               wget' \
  && apt-get update -qq \
  && apt-get install -yq $buildDeps libc6-i386 \
  && set -x \
  && echo "Install Bitdefender..." \
  && cd /tmp \
  && wget -O- -q http://download.bitdefender.com/repos/deb/bd.key.asc | apt-key add - \
  && echo "deb http://download.bitdefender.com/repos/deb/ bitdefender non-free" >> /etc/apt/sources.list \
  && apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq bitdefender-scanner \
  && echo "LicenseAccepted = True" >> /opt/BitDefender-scanner/etc/bdscan.conf \
  && chmod +x /go/src/github.com/malice-plugins/bitdefender/bd_fix.sh \
  && bash /go/src/github.com/malice-plugins/bitdefender/bd_fix.sh \
  && echo "Clean up unnecessary files..." \
  && apt-get purge -y --auto-remove $buildDeps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /go /usr/local/go

ENV GO_VERSION 1.8.3

COPY . /go/src/github.com/malice-plugins/bitdefender
RUN buildDeps='ca-certificates \
               build-essential \
               gdebi-core \
               libssl-dev \
               mercurial \
               git-core \
               wget' \
  && apt-get update -qq \
  && apt-get install -yq $buildDeps libc6-i386 \
  && set -x \
  && echo "Install Go..." \
  && ARCH="$(dpkg --print-architecture)" \
  && wget https://storage.googleapis.com/golang/go$GO_VERSION.linux-$ARCH.tar.gz -O /tmp/go.tar.gz \
  && tar -C /usr/local -xzf /tmp/go.tar.gz \
  && export PATH=$PATH:/usr/local/go/bin \
  && echo "Building avscan Go binary..." \
  && cd /go/src/github.com/malice-plugins/bitdefender \
  && export GOPATH=/go \
  && go version \
  && go get \
  && go build -ldflags "-X main.Version=$(cat VERSION) -X main.BuildTime=$(date -u +%Y%m%d)" -o /bin/avscan \
  && echo "Clean up unnecessary files..." \
  && apt-get purge -y --auto-remove $buildDeps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /go /usr/local/go

# Update Bitdefender definitions
RUN bdscan --update

# Add EICAR Test Virus File to malware folder
ADD http://www.eicar.org/download/eicar.com.txt /malware/EICAR

WORKDIR /malware

ENTRYPOINT ["/bin/avscan"]
CMD ["--help"]
