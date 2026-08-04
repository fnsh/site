#!/usr/bin/env python3
"""Render Gluon domains.conf Lua trainwreck from input YAML.
Input YAML:

    common:
      wifi:
        ssid: darmstadt.freifunk.net
        owe_ssid: owe.darmstadt.freifunk.net
        owe_transition_mode: true
      next_node:
        name: [nextnode.ffda.io, nextnode]
        mac: "da:ff:00:00:ff:ff"
      ipv6_base: "fd01:67c:2ed8"
      extra_ipv6_bases: ["2a0f:3786:100", "2a13:fcc0:2ed8"]
      vpn_base_port: 10000
      mesh_vpn:
        fastd:
          groups:
            backbone:
              peers:
                gw1:
                  key: "..."
                  remotes: ['"gw1.example.net"', '"203.0.113.1"']

    domain:
      dom1:
        dom_id: 1
        domain_codes:
          fnsh_dom1: 
            name: "Domain 1"
            hidden: true
          fnsh_da_110: 
            name: "Darmstadt: Stadtzentrum"
            hidden: false
        # optional overrides:
        # domain_seed: "<64 hex chars>"
        # dns: {servers: [...], cacheentries: 4096}

"""

import argparse
import re
import secrets
from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader

SCRIPT_DIR = Path(__file__).resolve().parent
SEED_RE = re.compile(r"domain_seed\s*=\s*'([0-9a-fA-F]{64})'")


def lua_bool(value):
    return "true" if value else "false"


def build_context(spec, common, output_dir):
    dom_id = spec["dom_id"]
    domain_codes = spec["domain_codes"]
    primary_code = next(iter(domain_codes))
    domain_prefix = primary_code.split("_", 1)[0]
    hexid = f"{dom_id:02x}"

    hide_domain = [x for x, v in domain_codes.items() if v.get("hidden", False)]
    hide_domain_repr = "{ " + ", ".join(f"'{c}'" for c in hide_domain) + " }"

    ipv6_base = common["ipv6_base"]
    next_node = common.get("next_node", {})
    wifi = common.get("wifi", {})
    dns = spec.get("dns") or common.get("dns")

    domain_seed = (
        spec.get("domain_seed")
    )

    peers = (
        common.get("mesh_vpn", {})
        .get("fastd", {})
        .get("groups", {})
        .get("backbone", {})
        .get("peers", {})
    )

    return {
        "primary_code": primary_code,
        "domain_codes": domain_codes,
        "domain_seed": domain_seed,
        "hide_domain_repr": hide_domain_repr,
        "dns": dns,
        "prefix4": f"10.{dom_id * 10}.0.0/20",
        "prefix6": f"{ipv6_base}:10{hexid}::/64",
        "extra_prefixes6": [
            f"{base}:10{hexid}::/64" for base in common.get("extra_ipv6_bases", [])
        ],
        "next_node_name": next_node.get("name", []),
        "next_node_ip4": f"10.{dom_id * 10}.0.254",
        "next_node_ip6": f"{ipv6_base}:10{hexid}::1:1",
        "next_node_mac": spec.get("next_node_mac", next_node.get("mac", "da:ff:00:00:ff:ff")),
        "wifi_ssid": spec.get("wifi_ssid", wifi.get("ssid")),
        "wifi_owe_ssid": spec.get("wifi_owe_ssid", wifi.get("owe_ssid")),
        "owe_transition_mode": lua_bool(wifi.get("owe_transition_mode", True)),
        "mesh_id": f"{domain_prefix}-mesh-dom{dom_id}",
        "vpn_port": common.get("vpn_base_port", 10000) + dom_id * 10,
        "mesh_vpn_peers": peers,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("config", type=Path, help="YAML file describing the domains to generate")
    parser.add_argument(
        "-o", "--output-dir", type=Path, default=Path("domains"),
        help="directory to write domain .conf files into (default: domains)",
    )
    args = parser.parse_args()

    data = yaml.safe_load(args.config.read_text())
    common = data.get("common", {})
    domains = data.get("domain", {})

    env = Environment(
        loader=FileSystemLoader(str(SCRIPT_DIR)),
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )
    template = env.get_template("domain.conf.j2")

    args.output_dir.mkdir(parents=True, exist_ok=True)

    for name, spec in domains.items():
        context = build_context(spec, common, args.output_dir)
        out_path = args.output_dir / f"{context['primary_code']}.conf"
        out_path.write_text(template.render(**context))
        print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
