ARG PYTHON_VERSION=3.12.3
FROM python:$PYTHON_VERSION

WORKDIR /usr/src/app

COPY ci/docker/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

#COPY . .

#CMD [ "python", "./your-daemon-or-script.py" ]
