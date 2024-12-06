#!/usr/bin/env python3

import jinja2
import yaml

config_file = 'ci/config.yaml'

with open(config_file) as f:
    config = yaml.safe_load(f)

jinja_env = jinja2.Environment(loader=jinja2.BaseLoader())

def recursive_render(tpl, values):
     prev = tpl
     while True:
         curr = jinja_env.from_string(prev).render(**values)
         if curr != prev:
             prev = curr
         else:
             return curr

def generate_job(template, os, osver, spackver, target, cudaver=None, rocmver=None):
    if target == "cpu":
        spack_target = "alps-zen2"
    elif target == "cuda-x86_64":
        spack_target = "alps-a100"
    elif target == "cuda-aarch64":
        spack_target = "alps-gh200"
    elif target == "rocm":
        spack_target = "alps-mi200"
    else:
        print(f"Error: undnouwn target {target}")
        exit(1)

    data = config | {
            "os": os,
            "osver": osver,
            "spackver": spackver,
            "cudaver": cudaver,
            "rocmver": rocmver,
            "arch": target,
            "spack_target": spack_target,
            }

    return recursive_render(template, data)

def generate_template(template_file, os_dict, spackver_list, cudaver_list, rocmver_list):
    pipeline = []

    with open(template_file) as f:
        template = f.read()

    for os in os_dict.keys():
        for osver in os_dict[os]:
            for spackver in spackver_list:
                target = "cpu"
                pipeline.append(generate_job(template, os, osver, spackver, target, None, None))

                for cudaver in cudaver_list:
                    target = "cuda-x86_64"
                    pipeline.append(generate_job(template, os, osver, spackver, target, cudaver, None))
                    target = "cuda-aarch64"
                    pipeline.append(generate_job(template, os, osver, spackver, target, cudaver, None))

                #for rocmver in rocmver_list:
                #    target = "rocm"
                #    pipeline.append(generate_job(template, os, osver, spackver, target, None, rocmver))

    return pipeline

pipeline = []

# Add header (include)
pipeline.append(
"""include:
  - remote: 'https://gitlab.com/cscs-ci/recipes/-/raw/master/templates/v2/.ci-ext.yml'

stages:
  - build_base_image
  - create_multiarch_base_image
  - test_base_image
  - build_test_image
  - test_test_image
  - deploy_base_image"""
)

templates = [{"template_file": 'ci/templates/build_image.yml.j2',
              "os_dict": config["os"],
              "spackver_list": config["spackver"],
              "cudaver_list": config["cudaver"],
              "rocmver_list": config["rocmver"],
             },
             {"template_file": 'ci/templates/runtime_image.yml.j2',
              "os_dict": config["os"],
              "spackver_list": [None],
              "cudaver_list": config["cudaver"],
              "rocmver_list": config["rocmver"],
             },
             {"template_file": 'ci/templates/test_image.yml.j2',
              "os_dict": config["os"],
              "spackver_list": config["spackver"],
              "cudaver_list": config["cudaver"],
              "rocmver_list": config["rocmver"],
             },
            ]

for t in templates:
    pipeline += generate_template(t["template_file"], t["os_dict"], t["spackver_list"], t["cudaver_list"], t["rocmver_list"])

print("\n\n".join(pipeline))
