SEPARATOR=`printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -`

echo $SEPARATOR
echo "Trivy Scan Results"
echo $SEPARATOR
for i in artifacts/*-trivy.json; do echo $i; jq ".Results[]?.Vulnerabilities | length" $i; done

echo $SEPARATOR
echo "Grype Scan Results"
echo $SEPARATOR
for i in artifacts/*-grype.json; do echo $i; jq ".matches | length" $i; done

echo $SEPARATOR
echo "Docker Scan Results"
echo $SEPARATOR
for i in artifacts/*-docker.json; do echo $i; jq ".vulnerabilities | length" $i; done

echo $SEPARATOR
echo "govulncheck Scan Results"
echo $SEPARATOR
for i in artifacts/*-govulncheck.json; do echo $i; jq ".Vulns | length" $i; done

echo $SEPARATOR
echo "twistcli Scan Results"
echo $SEPARATOR
for i in artifacts/*-twistcli.json; do echo $i; jq ".results[0].vulnerabilities | length" $i; done
