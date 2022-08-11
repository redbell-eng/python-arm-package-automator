#!/bin/sh
python -m venv venv && \
source ./venv/bin/activate && \
python -m pip install $1 && \
tar -czvf ./$1.tar.gz ./venv/lib/python3.10/site-packages/ && \
aws s3 cp ./$1.tar.gz s3://$S3_BUCKET_NAME/