FROM ubuntu:22.04

# SSH mit Login einrichten
RUN apt update && apt install -y openssh-server curl wget nano vim sudo \
    && echo 'root:root' | chpasswd \
    && useradd -m -s /bin/bash user \
    && echo 'user:password' | chpasswd \
    && useradd -m -s /bin/bash admin \
    && echo 'admin:admin' | chpasswd \
    && usermod -aG sudo admin \
    && mkdir -p /run/sshd

# Notwendige Tools installieren
RUN apt-get install -y python3-pip tcpdump rsyslog && \
    pip3 install asciinema && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Scripts-Verzeichnis erstellen und Wrapper kopieren
RUN mkdir -p /opt/myscripts
COPY scripts/monitoring/session_wrapper.sh /opt/myscripts/session_wrapper.sh
RUN chmod +x /opt/myscripts/session_wrapper.sh

# Custom sshd_config mit ForceCommand
COPY docker/configs/sshd_config /etc/ssh/sshd_config

# Alert-Script kopieren
COPY scripts/monitoring/alert.sh /opt/myscripts/alert.sh
RUN chmod +x /opt/myscripts/alert.sh

# Verzeichnisse mit passenden Rechten anlegen
RUN mkdir -p /var/log/auth && chmod 700 /var/log/auth \
    && mkdir -p /var/log/.journal && chmod 700 /var/log/.journal \
    && mkdir -p /tmp/.systemd-private && chmod 777 /tmp/.systemd-private

# Verzeichnisse für die Fake Webapp anlegen
RUN mkdir -p /home/user/webapp/backups \
    && mkdir -p /home/user/webapp/logs \
    && mkdir -p /home/user/documents \
    && mkdir -p /home/user/downloads

# Fake Dateien einschleusen
COPY data/fake_data/fake_env.md /home/user/webapp/.env
COPY data/fake_data/db_backup.sql /home/user/webapp/backups/db_backup.sql
COPY data/fake_data/fake_bash.md /home/user/.bash_history

# Startup Script kopieren
COPY scripts/startup/startup-script /opt/start.sh
RUN chmod +x /opt/start.sh

# Rsyslog konfigurieren
COPY docker/configs/rsyslog.conf /etc/rsyslog.d/honeypot.conf

EXPOSE 22

VOLUME [ "/tmp/.systemd-private", "/var/log/auth", "/var/log/.journal" ]

CMD ["/opt/start.sh"]
