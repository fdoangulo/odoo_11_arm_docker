FROM alpine:edge
LABEL maintainer="fernandoangulo@gmail.com"

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Adding needed repos
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories

# Updates & Upgrades
RUN apk update \
    && apk upgrade

# Install needed packages
RUN apk add --update --no-cache \
    bash \
    python-dev \
    py-pip \
    ca-certificates \
    wkhtmltopdf \
    tar \
    wget \
    gcc \
    py-lxml \
    linux-headers \
    postgresql-dev \
    libxml2-dev \
    libxslt-dev \
    musl-dev \
    jpeg-dev \
    zlib-dev \
    openldap-dev\
    nodejs \
    nodejs-npm \
    sudo \
    && update-ca-certificates

# Download and install Odoo 11
RUN addgroup odoo && adduser odoo -s /bin/sh -D -G odoo \
    && echo "odoo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/010_odoo-nopasswd \
    && mkdir /opt \
    && wget https://nightly.odoo.com/11.0/nightly/src/odoo_11.0.latest.tar.gz \
    && tar -xzf odoo_11.0.latest.tar.gz -C /opt \
    && rm odoo_11.0.latest.tar.gz \
    && npm install -g less less-plugin-clean-css \
    && cd /opt/odoo* \
    && pip install --upgrade pip \
    && pip install -r requirements.txt \
    && python setup.py install \
    && rm -r /opt/odoo*

# Copy entrypoint script and Odoo configuration file
RUN pip3 install num2words xlwt phonenumbers
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
# USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
