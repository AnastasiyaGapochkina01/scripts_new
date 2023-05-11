#!/usr/bin/python3

import boto3
import datetime
import smtplib
import subprocess
import hvac
import json
import os
import logging
import logging.handlers as handlers

from smtplib import SMTPException
from email.message import EmailMessage
from datetime import datetime
from cryptography import x509
from cryptography.hazmat._oid import NameOID
from dotenv import load_dotenv

regions=['eu-central-1', 'us-east-1']
now = datetime.now()
recipient = 'webadmin@softline.com'
days_before_exp_trigger = 30

# logging config
log_filename='/var/log/check_ssl_certificate.log'
logger = logging.getLogger('check_ssl_certificate')
logger.setLevel(logging.INFO)
logHandler = handlers.RotatingFileHandler(log_filename, maxBytes=1000, backupCount=2)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)

def check_aws_certs(regions):
    for region in regions:
        client = boto3.client('acm', region_name=region)
        try:
            logger.info("Get certificate list from AWS {}".format(region))
            certificateList = client.list_certificates()["CertificateSummaryList"]
        except Exception as exp:
            logger.error("{} {}".format(exp.response['Error']['Code'], exp.response['Error']['Message']))
        else:
            logger.info("Check expiration date for AWS certificates")
            for certificate in certificateList:
                certificateDetails = client.describe_certificate(CertificateArn=certificate["CertificateArn"])["Certificate"]
                if 'NotAfter' in certificateDetails:
                    delta = certificateDetails['NotAfter'].replace(tzinfo=None) - now
                    if delta.days < days_before_exp_trigger:
                        subject = f"Certificate {certificateDetails['DomainName']} expire"
                        msg = f"Certificate for {certificateDetails['DomainName']} in AWS region {region} will be expired in {delta.days} days. Expiration date is {certificateDetails['NotAfter'].strftime('%Y-%m-%d')} link: https://{region}.console.aws.amazon.com/acm/home?region={region}#/certificates/{certificateDetails['CertificateArn'].split('/')[1]}"
                        body = bytes(msg, 'UTF-8')
                        send_email(subject, recipient, body)


def check_vault_certs():
    load_dotenv()
    token = os.getenv("token")
    vault_client = hvac.Client(url='https://vault.slweb.ru', token=token)
    prefix = 'SSL-certificates/'
    mount_point = 'devops'
    now = datetime.now()

    try:
        logger.info("Get certificate list from vault")
        certificate_list = vault_client.secrets.kv.v2.list_secrets(path=prefix, mount_point=mount_point)
    except Exception as exp:
        logger.error("{} {}".format(exp.response['Error']['Code'], exp.response['Error']['Message']))
    else:
        logger.info("Check expiration date for vault certificates")
        for certificate in certificate_list['data']['keys']:
            certificate_data = vault_client.secrets.kv.v2.read_secret_version(path=prefix + certificate,
                                                                      mount_point=mount_point,
                                                                      raise_on_deleted_version=True)
            fullchain_certificate = certificate_data['data']['data']['fullchain_certificate']
            certs = x509.load_pem_x509_certificates(fullchain_certificate.encode())
            for cert in certs:
                delta = cert.not_valid_after - now
                if delta.days < days_before_exp_trigger:
                   subject = f"Certificate {cert.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value} expire"
                   msg = f"Certificate for {cert.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value} will be expired in {delta.days} days. Expiration date is {cert.not_valid_after.strftime('%Y-%m-%d')}"
                   body = bytes(msg, 'UTF-8')
                   send_email(subject, recipient, body) 


def send_email(subject, recipient, body):
    try:
        logger.info("Send e-mail to {}".format(recipient))
        process = subprocess.Popen(['mail', '-s', subject, recipient],
                               stdin=subprocess.PIPE)
    except Exception as ecp:
        logger.error("{} {}".format(ecp.response['Error']['Code'], ecp.response['Error']['Message']))
    else:
        process.communicate(body)


if __name__ == "__main__":
    check_aws_certs(regions)
    check_vault_certs()
