FROM alpine:3.8

RUN apk update && apk add bash py-pip ruby-irb ruby-rdoc ruby ncurses shadow libxml2-utils

RUN pip install shyaml yamllint facter hiera

RUN mkdir -p /opt/erb-hiera-generator && mkdir -p /params

COPY erb-hiera-generator.rb /opt/erb-hiera-generator/erb-hiera-generator.rb 
RUN chmod +x /opt/erb-hiera-generator/erb-hiera-generator.rb

CMD ["/opt/erb-hiera-generator/erb-hiera-generator.rb", "/params/hiera.yaml", "/params/template", "/params/outputfile"]
