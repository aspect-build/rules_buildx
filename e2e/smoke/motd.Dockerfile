FROM python:3.11.17-bookworm

WORKDIR /app
COPY motd.txt .

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "cat motd.txt" ]
