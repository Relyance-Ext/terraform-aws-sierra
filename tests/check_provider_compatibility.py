#!/usr/bin/env python3
"""Install exact providers and check local source without cloud credentials or calls.

Public Registry/provider downloads are required. Root tests use mock plans; the
S3 policy test applies only virtual resources using explicit resource overrides.
Logs, copied fixtures, providers, and an empty HOME stay under .terraform/.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / ".terraform" / "provider-compatibility" / "matrix"
VERSIONS = sys.argv[1:] or ["5.79.0", "5.100.0", "6.0.0", "6.69.1"]
TERRAFORM = shutil.which(os.environ.get("TERRAFORM_BIN", "terraform"))
if not TERRAFORM:
    sys.exit("Set TERRAFORM_BIN to a Terraform 1.9.x executable.")
WORK.mkdir(parents=True, exist_ok=True)
(WORK / "home").mkdir(exist_ok=True)
(WORK / "cache").mkdir(exist_ok=True)
(WORK / "terraform.rc").write_text("")
ENV = {
    "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
    "HOME": str(WORK / "home"),
    "TF_CLI_CONFIG_FILE": str(WORK / "terraform.rc"),
    "TF_PLUGIN_CACHE_DIR": str(WORK / "cache"),
    "TF_IN_AUTOMATION": "1",
    "CHECKPOINT_DISABLE": "1",
    "AWS_CONFIG_FILE": os.devnull,
    "AWS_SHARED_CREDENTIALS_FILE": os.devnull,
    "AWS_EC2_METADATA_DISABLED": "true",
}


def run(directory, *arguments):
    result = subprocess.run(
        [TERRAFORM, f"-chdir={directory}", *arguments],
        env=ENV, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    log = directory / (arguments[0] + ".log")
    log.write_text(result.stdout)
    if result.returncode:
        print(result.stdout, flush=True)
        sys.exit(f"FAILED: {directory}: {' '.join(arguments)}; log: {log}")
    print(f"PASS {directory.relative_to(WORK)}: {' '.join(arguments)}", flush=True)
    if arguments[0] == "test":
        for line in result.stdout.splitlines():
            if line.startswith("Success!"):
                print(line, flush=True)
    return result.stdout


def pin(directory, version):
    (directory / "compatibility_override.tf").write_text(
        'terraform {\n  required_providers {\n    aws = {\n'
        '      source = "hashicorp/aws"\n'
        f'      version = "= {version}"\n'
        '    }\n  }\n}\n'
    )


for version in VERSIONS:
    if not version.replace(".", "").isdigit():
        sys.exit(f"Expected an exact stable provider version: {version!r}")
    base = WORK / version
    if base.exists():
        shutil.rmtree(base)
    # The caller's exact pin must intersect the unmodified module constraints.
    wrapper = base / "constraint"
    wrapper.mkdir(parents=True)
    pin(wrapper, version)
    (wrapper / "main.tf").write_text(
        'module "sierra" {\n  source = ' + json.dumps(str(ROOT)) + '\n}\n'
    )
    run(wrapper, "init", "-backend=false", "-input=false", "-no-color")
    run(wrapper, "validate", "-no-color")

    source = base / "source"
    shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns(".git", ".terraform", ".terraform.lock.hcl"))
    pin(source, version)
    shutil.copy(wrapper / ".terraform.lock.hcl", source / ".terraform.lock.hcl")
    run(source, "init", "-backend=false", "-input=false", "-no-color")
    run(source, "validate", "-no-color")
    run(source, "test", "-no-color")

    # Exercise the exact example inputs against this checkout, not its public release.
    for name in ("create_cluster", "use_existing_cluster"):
        example = source / "examples" / name
        path = example / "sierra.tf"
        path.write_text(path.read_text().replace(
            'source  = "Relyance-Ext/sierra/aws"\n  version = "0.8.0"',
            'source = "../.."',
        ))
        pin(example, version)
        shutil.copy(wrapper / ".terraform.lock.hcl", example / ".terraform.lock.hcl")
        run(example, "init", "-backend=false", "-input=false", "-no-color")
        run(example, "validate", "-no-color")

    s3 = source / "modules" / "s3"
    pin(s3, version)
    shutil.copy(wrapper / ".terraform.lock.hcl", s3 / ".terraform.lock.hcl")
    run(s3, "init", "-backend=false", "-input=false", "-no-color")
    run(s3, "validate", "-no-color")
    run(s3, "test", "-no-color")
print(f"All provider compatibility checks passed: {', '.join(VERSIONS)}")
