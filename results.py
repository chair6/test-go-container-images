#!/usr/bin/env python

import json
import os
import tabulate

IMAGE_NAME='test-go-container-image'

results = []

for f in sorted(os.listdir('./images')):
    target = '.'.join(f.split('.')[1:])
    print('parsing output for image {}...'.format(target))

    trivy_count = 0
    with open('./artifacts/{}-trivy.json'.format(target), 'r') as fin:
        trivy_results = json.loads(fin.read())
        for res in trivy_results.get('Results', []):
            vulns = res.get('Vulnerabilities', [])
            trivy_count = trivy_count + len(vulns)

    grype_count = 0
    with open('./artifacts/{}-grype.json'.format(target), 'r') as fin:
        grype_results = json.loads(fin.read())
        grype_count = len(grype_results['matches'])
    
    docker_count = 0
    with open('./artifacts/{}-docker.json'.format(target), 'r') as fin:
        docker_results = json.loads(fin.read())
        docker_count = len(docker_results['vulnerabilities'])

    govulncheck_count = 0
    with open('./artifacts/{}-govulncheck.json'.format(target), 'r') as fin:
        govulncheck_raw = fin.read()
        if govulncheck_raw != '':
            govulncheck_results = json.loads(govulncheck_raw)
            govulncheck_count = len(govulncheck_results.get('Vulns', []) or [])

    twistcli_count = 0
    with open('./artifacts/{}-twistcli.json'.format(target), 'r') as fin:
        twistcli_results = json.loads(fin.read())
        twistcli_count = len(twistcli_results['results'][0].get('vulnerabilities', []))

    results.append([
        '{}:{}'.format(IMAGE_NAME, target), trivy_count, grype_count, docker_count, govulncheck_count, twistcli_count
    ])

print(tabulate.tabulate(results, headers=['image', 'trivy', 'grype', 'docker', 'govulncheck', 'twistcli']))
