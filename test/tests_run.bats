load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
#
# configuration checks
#

@test "checking configuration: hostname/domainname" {
  run docker run tvial/docker-mailserver:testing
  assert_success
}

#
# opendkim
#

# this set of tests is of low quality. It does not test the RSA-Key size properly via openssl or similar
# Instead it tests the file-size (here 511) - which may differ with a different domain names
# This test may be re-used as a global test to provide better test coverage.
@test "checking opendkim: generator creates default keys size" {
    # Prepare default key size 2048
    rm -rf "$(pwd)/test/config/keyDefault" && mkdir -p "$(pwd)/test/config/keyDefault"
    run docker run --rm \
      -v "$(pwd)/test/config/keyDefault/":/tmp/docker-mailserver/ \
      -v "$(pwd)/test/config/postfix-accounts.cf":/tmp/docker-mailserver/postfix-accounts.cf \
      -v "$(pwd)/test/config/postfix-virtual.cf":/tmp/docker-mailserver/postfix-virtual.cf \
      tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-config | wc -l'
    assert_success
    assert_output 6

  run docker run --rm \
    -v "$(pwd)/test/config/keyDefault/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing \
    /bin/sh -c 'stat -c%s /etc/opendkim/keys/localhost.localdomain/mail.txt'

  assert_success
  assert_output 511
}

# this set of tests is of low quality. It does not test the RSA-Key size properly via openssl or similar
# Instead it tests the file-size (here 511) - which may differ with a different domain names
# This test may be re-used as a global test to provide better test coverage.
@test "checking opendkim: generator creates key size 2048" {
    # Prepare set key size 2048
    rm -rf "$(pwd)/test/config/key2048" && mkdir -p "$(pwd)/test/config/key2048"
    run docker run --rm \
      -v "$(pwd)/test/config/key2048/":/tmp/docker-mailserver/ \
      -v "$(pwd)/test/config/postfix-accounts.cf":/tmp/docker-mailserver/postfix-accounts.cf \
      -v "$(pwd)/test/config/postfix-virtual.cf":/tmp/docker-mailserver/postfix-virtual.cf \
      tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-config 2048 | wc -l'
    assert_success
    assert_output 6

  run docker run --rm \
    -v "$(pwd)/test/config/key2048/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing \
    /bin/sh -c 'stat -c%s /etc/opendkim/keys/localhost.localdomain/mail.txt'

  assert_success
  assert_output 511
}

# this set of tests is of low quality. It does not test the RSA-Key size properly via openssl or similar
# Instead it tests the file-size (here 329) - which may differ with a different domain names
# This test may be re-used as a global test to provide better test coverage.
@test "checking opendkim: generator creates key size 1024" {
    # Prepare set key size 1024
    rm -rf "$(pwd)/test/config/key1024" && mkdir -p "$(pwd)/test/config/key1024"
    run docker run --rm \
      -v "$(pwd)/test/config/key1024/":/tmp/docker-mailserver/ \
      -v "$(pwd)/test/config/postfix-accounts.cf":/tmp/docker-mailserver/postfix-accounts.cf \
      -v "$(pwd)/test/config/postfix-virtual.cf":/tmp/docker-mailserver/postfix-virtual.cf \
      tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-config 1024 | wc -l'
    assert_success
    assert_output 6

  run docker run --rm \
    -v "$(pwd)/test/config/key1024/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing \
    /bin/sh -c 'stat -c%s /etc/opendkim/keys/localhost.localdomain/mail.txt'

  assert_success
  assert_output 329
}

@test "checking opendkim: generator creates keys, tables and TrustedHosts" {
  rm -rf "$(pwd)/test/config/empty" && mkdir -p "$(pwd)/test/config/empty"
  run docker run --rm \
    -v "$(pwd)/test/config/empty/":/tmp/docker-mailserver/ \
    -v "$(pwd)/test/config/postfix-accounts.cf":/tmp/docker-mailserver/postfix-accounts.cf \
    -v "$(pwd)/test/config/postfix-virtual.cf":/tmp/docker-mailserver/postfix-virtual.cf \
    tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-config | wc -l'
  assert_success
  assert_output 6
  # Check keys for localhost.localdomain
  run docker run --rm \
    -v "$(pwd)/test/config/empty/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/localhost.localdomain/ | wc -l'
  assert_success
  assert_output 2
  # Check keys for otherdomain.tld
  run docker run --rm \
    -v "$(pwd)/test/config/empty/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/otherdomain.tld | wc -l'
  assert_success
  assert_output 2
  # Check presence of tables and TrustedHosts
  run docker run --rm \
    -v "$(pwd)/test/config/empty/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c "ls -1 etc/opendkim | grep -E 'KeyTable|SigningTable|TrustedHosts|keys'|wc -l"
  assert_success
  assert_output 4
}

@test "checking opendkim: generator creates keys, tables and TrustedHosts without postfix-accounts.cf" {
  rm -rf "$(pwd)/test/config/without-accounts" && mkdir -p "$(pwd)/test/config/without-accounts"
  run docker run --rm \
    -v "$(pwd)/test/config/without-accounts/":/tmp/docker-mailserver/ \
    -v "$(pwd)/test/config/postfix-virtual.cf":/tmp/docker-mailserver/postfix-virtual.cf \
    tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-config | wc -l'
  assert_success
  assert_output 5
  # Check keys for localhost.localdomain
  run docker run --rm \
    -v "$(pwd)/test/config/without-accounts/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/localhost.localdomain/ | wc -l'
  assert_success
  assert_output 2
  # Check keys for otherdomain.tld
  # run docker run --rm \
  #   -v "$(pwd)/test/config/without-accounts/opendkim":/etc/opendkim \
  #   tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/otherdomain.tld | wc -l'
  # assert_success
  # [ "$output" -eq 0 ]
  # Check presence of tables and TrustedHosts
  run docker run --rm \
    -v "$(pwd)/test/config/without-accounts/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c "ls -1 etc/opendkim | grep -E 'KeyTable|SigningTable|TrustedHosts|keys'|wc -l"
  assert_success
  assert_output 4
}

@test "checking opendkim: generator creates keys, tables and TrustedHosts without postfix-virtual.cf" {
  rm -rf "$(pwd)/test/config/without-virtual" && mkdir -p "$(pwd)/test/config/without-virtual"
  run docker run --rm \
    -v "$(pwd)/test/config/without-virtual/":/tmp/docker-mailserver/ \
    -v "$(pwd)/test/config/postfix-accounts.cf":/tmp/docker-mailserver/postfix-accounts.cf \
    tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-config | wc -l'
  assert_success
  assert_output 5
  # Check keys for localhost.localdomain
  run docker run --rm \
    -v "$(pwd)/test/config/without-virtual/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/localhost.localdomain/ | wc -l'
  assert_success
  assert_output 2
  # Check keys for otherdomain.tld
  run docker run --rm \
    -v "$(pwd)/test/config/without-virtual/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/otherdomain.tld | wc -l'
  assert_success
  assert_output 2
  # Check presence of tables and TrustedHosts
  run docker run --rm \
    -v "$(pwd)/test/config/without-virtual/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c "ls -1 etc/opendkim | grep -E 'KeyTable|SigningTable|TrustedHosts|keys'|wc -l"
  assert_success
  assert_output 4
}

@test "checking opendkim: generator creates keys, tables and TrustedHosts using domain name" {
  rm -rf "$(pwd)/test/config/with-domain" && mkdir -p "$(pwd)/test/config/with-domain"
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/":/tmp/docker-mailserver/ \
    -v "$(pwd)/test/config/postfix-accounts.cf":/tmp/docker-mailserver/postfix-accounts.cf \
    -v "$(pwd)/test/config/postfix-virtual.cf":/tmp/docker-mailserver/postfix-virtual.cf \
    tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-config | wc -l'
  assert_success
  assert_output 6
  # Generate key using domain name
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/":/tmp/docker-mailserver/ \
    tvial/docker-mailserver:testing /bin/sh -c 'generate-dkim-domain testdomain.tld | wc -l'
  assert_success
  assert_output 1
  # Check keys for localhost.localdomain
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/localhost.localdomain/ | wc -l'
  assert_success
  assert_output 2
  # Check keys for otherdomain.tld
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/otherdomain.tld | wc -l'
  assert_success
  assert_output 2
  # Check keys for testdomain.tld
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c 'ls -1 /etc/opendkim/keys/testdomain.tld | wc -l'
  assert_success
  assert_output 2
  # Check presence of tables and TrustedHosts
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c "ls -1 /etc/opendkim | grep -E 'KeyTable|SigningTable|TrustedHosts|keys' | wc -l"
  assert_success
  assert_output 4
  # Check valid entries actually present in KeyTable
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c \
    "egrep 'localhost.localdomain|otherdomain.tld|localdomain2.com|testdomain.tld' /etc/opendkim/KeyTable | wc -l"
  assert_success
  assert_output 4
  # Check valid entries actually present in SigningTable
  run docker run --rm \
    -v "$(pwd)/test/config/with-domain/opendkim":/etc/opendkim \
    tvial/docker-mailserver:testing /bin/sh -c \
    "egrep 'localhost.localdomain|otherdomain.tld|localdomain2.com|testdomain.tld' /etc/opendkim/SigningTable | wc -l"
  assert_success
  assert_output 4
}
