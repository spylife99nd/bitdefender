####################################################
# GOLANG BUILDER
####################################################
FROM golang:1.11 as go_builder

COPY . /go/src/github.com/malice-plugins/bitdefender
WORKDIR /go/src/github.com/malice-plugins/bitdefender
RUN go get -u github.com/golang/dep/cmd/dep && dep ensure
RUN go build -ldflags "-s -w -X main.Version=v$(cat VERSION) -X main.BuildTime=$(date -u +%Y%m%d)" -o /bin/avscan

####################################################
# PLUGIN BUILDER
####################################################
FROM ubuntu:bionic
# FROM debian:jessie

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/bitdefender.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

# Create a malice user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN groupadd -r malice \
  && useradd --no-log-init -r -g malice malice \
  && mkdir /malware \
  && chown -R malice:malice /malware

ARG BDKEY
ENV BDVERSION 7.7-1

ENV BDURLPART BitDefender_Antivirus_Scanner_for_Unices/Unix/Current/EN_FR_BR_RO/Linux/
ENV BDURL https://download.bitdefender.com/SMB/Workstation_Security_and_Management/${BDURLPART}

RUN buildDeps='ca-certificates wget build-essential' \
  && apt-get update -qq \
  && apt-get install -yq $buildDeps psmisc
  
RUN set -x \
  && echo "===> Install Bitdefender..." \
  && cd /tmp \

  # && wget -q ${BDURL}/BitDefender-Antivirus-Scanner-${BDVERSION}-linux-amd64.deb.run \
  # && chmod 755 /tmp/BitDefender-Antivirus-Scanner-${BDVERSION}-linux-amd64.deb.run \

  && wget -q http://download.bitdefender.com/repos/deb/pool/non-free/b/bitdefender-scanner/bitdefender-scanner_7.6-3_amd64.deb \
  && chmod 755 /tmp/bitdefender-scanner_7.6-3_amd64.deb \
  && dpkg -i bitdefender-scanner_7.6-3_amd64.deb \
  && bdscan --version \

  && export path_scan_test=$(pwd)\
  # && bdscan "$path_scan_test"\
  # && yes | bdscan "$path_scan_test" && echo "accept"\
  # cái này để chạy spcae liên tục và cuối sẽ nhập accept (đã cài đặt xong)
  && yes "accept" | bdscan "$path_scan_test"\


  




  && echo "===> install done..." \
  && echo "===> Making installer noninteractive..." 


# test chạy thôi
RUN rm -rf /tmp/*
# Add EICAR Test Virus File to malware folder
ADD https://secure.eicar.org/eicar.com.txt /malware/EICAR

COPY --from=go_builder /bin/avscan /bin/avscan

WORKDIR /malware




