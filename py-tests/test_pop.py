import json
import subprocess
import time

import pytest


@pytest.fixture(scope="module")
def mail_server():
    subprocess.check_call("""docker run -d --name mail_pop3 \
		-v "`pwd`/test/config":/tmp/docker-mailserver \
		-v "`pwd`/test":/tmp/docker-mailserver-test \
		-v "`pwd`/test/config/letsencrypt":/etc/letsencrypt/live \
		-e ENABLE_POP3=1 \
		-e DMS_DEBUG=0 \
		-e SSL_TYPE=letsencrypt \
		-h mail.my-domain.com -t tvial/docker-mailserver:testing
    """, shell=True)
    try:
        output = json.loads(subprocess.check_output("""docker inspect mail_pop3""", shell=True, universal_newlines=True))
        ipaddress = output[0]["NetworkSettings"]["IPAddress"]
        yield ipaddress
    finally:
        subprocess.check_call("docker rm -f mail_pop3", shell=True)


def test_server_is_ready(mail_server):
    for i in range(20):
        time.sleep(0.5)
        try:
            output = subprocess.check_output('docker exec mail_pop3 /bin/bash -c "nc -w 1 0.0.0.0 110"', shell=True,
                                             universal_newlines=True)
            assert output.startswith("+OK")
            break
        except subprocess.CalledProcessError as e:
            print(e.stdout)
            pass
    else:
        assert False


def test_authentication_works(mail_server):
    output = subprocess.check_output("""docker exec mail_pop3 /bin/sh -c "nc -w 1 0.0.0.0 110 < /tmp/docker-mailserver-test/auth/pop3-auth.txt" """, shell=True, universal_newlines=True)
    assert "+OK Logged in." in output


def test_added_user_authentication_works(mail_server):
    output = subprocess.check_output("""docker exec mail_pop3 /bin/sh -c "nc -w 1 0.0.0.0 110 < /tmp/docker-mailserver-test/auth/added-pop3-auth.txt" """, shell=True, universal_newlines=True)
    assert "+OK Logged in." in output
