
# This code is auto generated and any changes will be lost if it is regenerated.

terraform {
    required_version = ">= 0.12.0"
}

# -- Copyright: Copyright (c) 2020, 2021, Oracle and/or its affiliates.
# ---- Author : Andrew Hopkinson (Oracle Cloud Solutions A-Team)
# ------ Connect to Provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ------ Retrieve Regional / Cloud Data
# -------- Get a list of Availability Domains
data "oci_identity_availability_domains" "AvailabilityDomains" {
    compartment_id = var.compartment_ocid
}
data "template_file" "AvailabilityDomainNames" {
    count    = length(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains)
    template = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains[count.index]["name"]
}
# -------- Get a list of Fault Domains
data "oci_identity_fault_domains" "FaultDomainsAD1" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 0)["name"]
    compartment_id = var.compartment_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD2" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 1)["name"]
    compartment_id = var.compartment_ocid
}
data "oci_identity_fault_domains" "FaultDomainsAD3" {
    availability_domain = element(data.oci_identity_availability_domains.AvailabilityDomains.availability_domains, 2)["name"]
    compartment_id = var.compartment_ocid
}
# -------- Get Home Region Name
data "oci_identity_region_subscriptions" "RegionSubscriptions" {
    tenancy_id = var.tenancy_ocid
}
data "oci_identity_regions" "Regions" {
}
data "oci_identity_tenancy" "Tenancy" {
    tenancy_id = var.tenancy_ocid
}

locals {
#    HomeRegion = [for x in data.oci_identity_region_subscriptions.RegionSubscriptions.region_subscriptions: x if x.is_home_region][0]
    home_region = lookup(
        {
            for r in data.oci_identity_regions.Regions.regions : r.key => r.name
        },
        data.oci_identity_tenancy.Tenancy.home_region_key
    )
}
# ------ Get List Service OCIDs
data "oci_core_services" "RegionServices" {
}
# ------ Get List Images
data "oci_core_images" "InstanceImages" {
    compartment_id           = var.compartment_ocid
}

# ------ Home Region Provider
provider "oci" {
    alias            = "home_region"
    tenancy_ocid     = var.tenancy_ocid
    user_ocid        = var.user_ocid
    fingerprint      = var.fingerprint
    private_key_path = var.private_key_path
    region           = local.home_region
}

# ------ Create Compartment - Root True
# ------ Root Compartment
locals {
    Cockroachdb_Ref_Arch_id              = var.compartment_ocid
}

output "Cockroachdb_Ref_ArchId" {
    value = local.Cockroachdb_Ref_Arch_id
}

# ------ Create Virtual Cloud Network
resource "oci_core_vcn" "Cockroachdb_Vcn001" {
    # Required
    compartment_id = local.Cockroachdb_Ref_Arch_id
    cidr_block     = "10.0.0.0/16"
    # Optional
    dns_label      = "vcn001"
    display_name   = "cockroachdb-vcn001"
}

locals {
    Cockroachdb_Vcn001_id                       = oci_core_vcn.Cockroachdb_Vcn001.id
    Cockroachdb_Vcn001_dhcp_options_id          = oci_core_vcn.Cockroachdb_Vcn001.default_dhcp_options_id
    Cockroachdb_Vcn001_domain_name              = oci_core_vcn.Cockroachdb_Vcn001.vcn_domain_name
    Cockroachdb_Vcn001_default_dhcp_options_id  = oci_core_vcn.Cockroachdb_Vcn001.default_dhcp_options_id
    Cockroachdb_Vcn001_default_security_list_id = oci_core_vcn.Cockroachdb_Vcn001.default_security_list_id
    Cockroachdb_Vcn001_default_route_table_id   = oci_core_vcn.Cockroachdb_Vcn001.default_route_table_id
}


# ------ Create Internet Gateway
resource "oci_core_internet_gateway" "Okit_Ig001" {
    # Required
    compartment_id = local.Cockroachdb_Ref_Arch_id
    vcn_id         = local.Cockroachdb_Vcn001_id
    # Optional
    enabled        = true
    display_name   = "okit-ig001"
}

locals {
    Okit_Ig001_id = oci_core_internet_gateway.Okit_Ig001.id
}

# ------ Create NAT Gateway
resource "oci_core_nat_gateway" "Okit_Ng001" {
    # Required
    compartment_id = local.Cockroachdb_Ref_Arch_id
    vcn_id         = local.Cockroachdb_Vcn001_id
    # Optional
    display_name   = "okit-ng001"
    block_traffic  = false
}

locals {
    Okit_Ng001_id = oci_core_nat_gateway.Okit_Ng001.id
}

# ------ Create Security List
# ------- Update VCN Default Security List
resource "oci_core_default_security_list" "Okit_Sl001" {
    # Required
    manage_default_resource_id = local.Cockroachdb_Vcn001_default_security_list_id
    egress_security_rules {
        # Required
        protocol    = "all"
        destination = "0.0.0.0/0"
        # Optional
        destination_type  = "CIDR_BLOCK"
    }
    ingress_security_rules {
        # Required
        protocol    = "6"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        tcp_options {
            min = "22"
            max = "22"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "1"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
        icmp_options {
            type = "3"
            code = "4"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "1"
        source      = "10.0.0.0/16"
        # Optional
        source_type  = "CIDR_BLOCK"
        icmp_options {
            type = "3"
        }
    }
    ingress_security_rules {
        # Required
        protocol    = "all"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
    }
    ingress_security_rules {
        # Required
        protocol    = "all"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
    }
    # Optional
    display_name   = "okit-sl001"
}

locals {
    Okit_Sl001_id = oci_core_default_security_list.Okit_Sl001.id
}


# ------ Create Security List
resource "oci_core_security_list" "Okit_Sl002" {
    # Required
    compartment_id = local.Cockroachdb_Ref_Arch_id
    vcn_id         = local.Cockroachdb_Vcn001_id
    egress_security_rules {
        # Required
        protocol    = "all"
        destination = "0.0.0.0/0"
        # Optional
        destination_type  = "CIDR_BLOCK"
    }
    ingress_security_rules {
        # Required
        protocol    = "all"
        source      = "10.0.0.0/16"
        # Optional
        source_type  = "CIDR_BLOCK"
    }
    ingress_security_rules {
        # Required
        protocol    = "all"
        source      = "0.0.0.0/0"
        # Optional
        source_type  = "CIDR_BLOCK"
    }
    # Optional
    display_name   = "okit-sl002"
}

locals {
    Okit_Sl002_id = oci_core_security_list.Okit_Sl002.id
}


# ------ Create Route Table
# ------- Update VCN Default Route Table
resource "oci_core_default_route_table" "Okit_Rt001" {
    # Required
    manage_default_resource_id = local.Cockroachdb_Vcn001_default_route_table_id
    route_rules    {
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        network_entity_id = local.Okit_Ig001_id
        description       = "Route to IG"
    }
    # Optional
    display_name   = "okit-rt001"
}

locals {
    Okit_Rt001_id = oci_core_default_route_table.Okit_Rt001.id
    }


# ------ Create Route Table
resource "oci_core_route_table" "Okit_Rt002" {
    # Required
    compartment_id = local.Cockroachdb_Ref_Arch_id
    vcn_id         = local.Cockroachdb_Vcn001_id
    route_rules    {
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        network_entity_id = local.Okit_Ng001_id
        description       = ""
    }
    # Optional
    display_name   = "okit-rt002"
}

locals {
    Okit_Rt002_id = oci_core_route_table.Okit_Rt002.id
}


# ------ Create Subnet
# ---- Create Public Subnet
resource "oci_core_subnet" "Cockroachdb_Public_Sn" {
    # Required
    compartment_id             = local.Cockroachdb_Ref_Arch_id
    vcn_id                     = local.Cockroachdb_Vcn001_id
    cidr_block                 = "10.0.0.0/24"
    # Optional
    display_name               = "cockroachdb-public-sn"
    dns_label                  = "sn001"
    security_list_ids          = [local.Okit_Sl001_id]
    route_table_id             = local.Okit_Rt001_id
    dhcp_options_id            = local.Cockroachdb_Vcn001_dhcp_options_id
    prohibit_public_ip_on_vnic = false
}

locals {
    Cockroachdb_Public_Sn_id              = oci_core_subnet.Cockroachdb_Public_Sn.id
    Cockroachdb_Public_Sn_domain_name     = oci_core_subnet.Cockroachdb_Public_Sn.subnet_domain_name
}

# ------ Create Subnet
# ---- Create Public Subnet
resource "oci_core_subnet" "Cockroachdb_Private_Sn" {
    # Required
    compartment_id             = local.Cockroachdb_Ref_Arch_id
    vcn_id                     = local.Cockroachdb_Vcn001_id
    cidr_block                 = "10.0.1.0/24"
    # Optional
    display_name               = "cockroachdb-private-sn"
    dns_label                  = "sn002"
    security_list_ids          = [local.Okit_Sl002_id]
    route_table_id             = local.Okit_Rt002_id
    dhcp_options_id            = local.Cockroachdb_Vcn001_dhcp_options_id
    prohibit_public_ip_on_vnic = true
}

locals {
    Cockroachdb_Private_Sn_id              = oci_core_subnet.Cockroachdb_Private_Sn.id
    Cockroachdb_Private_Sn_domain_name     = oci_core_subnet.Cockroachdb_Private_Sn.subnet_domain_name
}

# ------ Get List Images
data "oci_core_images" "Cockroachdb1Images" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = "7.9"
    shape                    = "VM.Standard.E2.1"
}

# ------ Create Instance
resource "oci_core_instance" "Cockroachdb1" {
    # Required
    compartment_id      = local.Cockroachdb_Ref_Arch_id
    shape               = "VM.Standard.E2.1"
    # Optional
    display_name        = "cockroachdb1"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Cockroachdb_Private_Sn_id
        # Optional
        assign_public_ip = false
        display_name     = "cockroachdb1 vnic 00"
        hostname_label   = "cockroachdb1"
        skip_source_dest_check = "false"
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    fault_domain = "FAULT-DOMAIN-1"
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("#cloud-config\npackages:\n  - nginx\n\nwrite_files:\n  # Add aliases to bash (Note: At time of writing the append flag does not appear to be working)\n  - path: /etc/.bashrc\n    append: true\n    content: |\n      alias lh='ls -lash'\n      alias lt='ls -last'\n      alias env='/usr/bin/env | sort'\n      alias whatsmyip='curl -X GET https://www.whatismyip.net | grep ipaddress'\n  # Create nginx index.html\n  - path: /usr/share/nginx/html/index1.html\n    permissions: '0644'\n    content: |\n      <html>\n      <head>\n      <title>OCI Loadbalancer backend {hostname}</title>\n      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n      <meta http-equiv=\"refresh\" content=\"10\" />\n      <style>\n      body {\n      background-image: url(\"bg.jpg\");\n      background-repeat: no-repeat;\n      background-size: contain;\n      background-position: center;\n      }\n      h1 {\n      text-align: center;\n      width: 100%;\n      }\n      </style>\n      </head>\n      <body>\n      <h1>OCI Regional Subnet Loadbalancer Backend {hostname}</h1>\n      </body>\n      </html>\n\nruncmd:\n  # Enable nginx\n  - sudo systemctl enable nginx.service\n  - sudo cp -v /usr/share/nginx/html/index1.html /usr/share/nginx/html/index.html\n  - sudo sed -i \"s/{hostname}/$(hostname)/g\" /usr/share/nginx/html/index.html\n  - sudo systemctl start nginx.service\n  # Set Firewall Rules\n  - sudo firewall-offline-cmd  --add-port=80/tcp\n  - sudo firewall-offline-cmd --add-port=26257/tcp\n  - sudo firewall-offline-cmd --add-port=8080/tcp\n  - sudo systemctl restart firewalld\n# Download and install CockroachDB\n  - sudo wget -qO- https://binaries.cockroachdb.com/cockroach-v19.2.5.linux-amd64.tgz | tar  xvz\n  - sudo cp -i cockroach-v19.1.1.linux-amd64/cockroach /usr/local/bin\n  - cockroach start --insecure --advertise-addr=cockroachdb1 --join=cockroachdb1,cockroachdb2,cockroachdb3 --cache=.25 --max-sql-memory=.25 --background\n  - cockroach init --insecure --host=cockroachdb1\n  # Add additional environment information because append does not appear to work in write_file\n  - sudo bash -c \"echo 'source /etc/.bashrc' >> /etc/bashrc\"\n\nfinal_message: \"**** The system is finally up, after $UPTIME seconds ****\"")
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.Cockroachdb1Images.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
}

locals {
    Cockroachdb1_id            = oci_core_instance.Cockroachdb1.id
    Cockroachdb1_public_ip     = oci_core_instance.Cockroachdb1.public_ip
    Cockroachdb1_private_ip    = oci_core_instance.Cockroachdb1.private_ip
}

output "cockroachdb1PublicIP" {
    value = local.Cockroachdb1_public_ip
}

output "cockroachdb1PrivateIP" {
    value = local.Cockroachdb1_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments


# ------ Get List Images
data "oci_core_images" "Cockroachdb2Images" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = "7.9"
    shape                    = "VM.Standard.E2.1"
}

# ------ Create Instance
resource "oci_core_instance" "Cockroachdb2" {
    # Required
    compartment_id      = local.Cockroachdb_Ref_Arch_id
    shape               = "VM.Standard.E2.1"
    # Optional
    display_name        = "cockroachdb2"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Cockroachdb_Private_Sn_id
        # Optional
        assign_public_ip = false
        display_name     = "cockroachdb2 vnic 00"
        hostname_label   = "cockroachdb2"
        skip_source_dest_check = "false"
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    fault_domain = "FAULT-DOMAIN-2"
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("#cloud-config\npackages:\n  - nginx\n\nwrite_files:\n  # Add aliases to bash (Note: At time of writing the append flag does not appear to be working)\n  - path: /etc/.bashrc\n    append: true\n    content: |\n      alias lh='ls -lash'\n      alias lt='ls -last'\n      alias env='/usr/bin/env | sort'\n      alias whatsmyip='curl -X GET https://www.whatismyip.net | grep ipaddress'\n  # Create nginx index.html\n  - path: /usr/share/nginx/html/index1.html\n    permissions: '0644'\n    content: |\n      <html>\n      <head>\n      <title>OCI Loadbalancer backend {hostname}</title>\n      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n      <meta http-equiv=\"refresh\" content=\"10\" />\n      <style>\n      body {\n      background-image: url(\"bg.jpg\");\n      background-repeat: no-repeat;\n      background-size: contain;\n      background-position: center;\n      }\n      h1 {\n      text-align: center;\n      width: 100%;\n      }\n      </style>\n      </head>\n      <body>\n      <h1>OCI Regional Subnet Loadbalancer Backend {hostname}</h1>\n      </body>\n      </html>\n\nruncmd:\n  # Enable nginx\n  - sudo systemctl enable nginx.service\n  - sudo cp -v /usr/share/nginx/html/index1.html /usr/share/nginx/html/index.html\n  - sudo sed -i \"s/{hostname}/$(hostname)/g\" /usr/share/nginx/html/index.html\n  - sudo systemctl start nginx.service\n  # Set Firewall Rules\n  - sudo firewall-offline-cmd  --add-port=80/tcp\n  - sudo firewall-offline-cmd --add-port=26257/tcp\n  - sudo firewall-offline-cmd --add-port=8080/tcp\n  - sudo systemctl restart firewalld\n# Download and install CockroachDB\n  - sudo wget -qO- https://binaries.cockroachdb.com/cockroach-v19.1.1.linux-amd64.tgz | tar  xvz\n  - sudo cp -i cockroach-v19.1.1.linux-amd64/cockroach /usr/local/bin\n  - cockroach start --insecure --advertise-addr=cockroachdb2 --join=cockroachdb1,cockroachdb2,cockroachdb3 --cache=.25 --max-sql-memory=.25 --background\n  # Add additional environment information because append does not appear to work in write_file\n  - sudo bash -c \"echo 'source /etc/.bashrc' >> /etc/bashrc\"\n\nfinal_message: \"**** The system is finally up, after $UPTIME seconds ****\"")
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.Cockroachdb2Images.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
}

locals {
    Cockroachdb2_id            = oci_core_instance.Cockroachdb2.id
    Cockroachdb2_public_ip     = oci_core_instance.Cockroachdb2.public_ip
    Cockroachdb2_private_ip    = oci_core_instance.Cockroachdb2.private_ip
}

output "cockroachdb2PublicIP" {
    value = local.Cockroachdb2_public_ip
}

output "cockroachdb2PrivateIP" {
    value = local.Cockroachdb2_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments


# ------ Get List Images
data "oci_core_images" "Cockroachdb3Images" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = "7.9"
    shape                    = "VM.Standard.E2.1"
}

# ------ Create Instance
resource "oci_core_instance" "Cockroachdb3" {
    # Required
    compartment_id      = local.Cockroachdb_Ref_Arch_id
    shape               = "VM.Standard.E2.1"
    # Optional
    display_name        = "cockroachdb3"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Cockroachdb_Private_Sn_id
        # Optional
        assign_public_ip = false
        display_name     = "cockroachdb3 vnic 00"
        hostname_label   = "cockroachdb3"
        skip_source_dest_check = "false"
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    fault_domain = "FAULT-DOMAIN-3"
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("#cloud-config\npackages:\n  - nginx\n\nwrite_files:\n  # Add aliases to bash (Note: At time of writing the append flag does not appear to be working)\n  - path: /etc/.bashrc\n    append: true\n    content: |\n      alias lh='ls -lash'\n      alias lt='ls -last'\n      alias env='/usr/bin/env | sort'\n      alias whatsmyip='curl -X GET https://www.whatismyip.net | grep ipaddress'\n  # Create nginx index.html\n  - path: /usr/share/nginx/html/index1.html\n    permissions: '0644'\n    content: |\n      <html>\n      <head>\n      <title>OCI Loadbalancer backend {hostname}</title>\n      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n      <meta http-equiv=\"refresh\" content=\"10\" />\n      <style>\n      body {\n      background-image: url(\"bg.jpg\");\n      background-repeat: no-repeat;\n      background-size: contain;\n      background-position: center;\n      }\n      h1 {\n      text-align: center;\n      width: 100%;\n      }\n      </style>\n      </head>\n      <body>\n      <h1>OCI Regional Subnet Loadbalancer Backend {hostname}</h1>\n      </body>\n      </html>\n\nruncmd:\n  # Enable nginx\n  - sudo systemctl enable nginx.service\n  - sudo cp -v /usr/share/nginx/html/index1.html /usr/share/nginx/html/index.html\n  - sudo sed -i \"s/{hostname}/$(hostname)/g\" /usr/share/nginx/html/index.html\n  - sudo systemctl start nginx.service\n  # Set Firewall Rules\n  - sudo firewall-offline-cmd  --add-port=80/tcp\n  - sudo firewall-offline-cmd --add-port=26257/tcp\n  - sudo firewall-offline-cmd --add-port=8080/tcp\n  - sudo systemctl restart firewalld\n# Download and install CockroachDB\n  - sudo wget -qO- https://binaries.cockroachdb.com/cockroach-v19.1.1.linux-amd64.tgz | tar  xvz\n  - sudo cp -i cockroach-v19.1.1.linux-amd64/cockroach /usr/local/bin\n  - cockroach start --insecure --advertise-addr=cockroachdb3 --join=cockroachdb1,cockroachdb2,cockroachdb3 --cache=.25 --max-sql-memory=.25 --background\n  # Add additional environment information because append does not appear to work in write_file\n  - sudo bash -c \"echo 'source /etc/.bashrc' >> /etc/bashrc\"\n\nfinal_message: \"**** The system is finally up, after $UPTIME seconds ****\"")
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.Cockroachdb3Images.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
}

locals {
    Cockroachdb3_id            = oci_core_instance.Cockroachdb3.id
    Cockroachdb3_public_ip     = oci_core_instance.Cockroachdb3.public_ip
    Cockroachdb3_private_ip    = oci_core_instance.Cockroachdb3.private_ip
}

output "cockroachdb3PublicIP" {
    value = local.Cockroachdb3_public_ip
}

output "cockroachdb3PrivateIP" {
    value = local.Cockroachdb3_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments


# ------ Get List Images
data "oci_core_images" "BastionImages" {
    compartment_id           = var.compartment_ocid
    operating_system         = "Oracle Linux"
    operating_system_version = "7.9"
    shape                    = "VM.Standard.E2.1"
}

# ------ Create Instance
resource "oci_core_instance" "Bastion" {
    # Required
    compartment_id      = local.Cockroachdb_Ref_Arch_id
    shape               = "VM.Standard.E2.1"
    # Optional
    display_name        = "bastion"
    availability_domain = data.oci_identity_availability_domains.AvailabilityDomains.availability_domains["1" - 1]["name"]
    agent_config {
        # Optional
    }
    create_vnic_details {
        # Required
        subnet_id        = local.Cockroachdb_Public_Sn_id
        # Optional
        assign_public_ip = true
        display_name     = "bastion vnic 00"
        hostname_label   = "bastion"
        skip_source_dest_check = "false"
    }
#    extended_metadata {
#        some_string = "stringA"
#        nested_object = "{\"some_string\": \"stringB\", \"object\": {\"some_string\": \"stringC\"}}"
#    }
    metadata = {
        ssh_authorized_keys = ""
        user_data           = base64encode("")
    }
    source_details {
        # Required
        source_id               = data.oci_core_images.BastionImages.images[0]["id"]
        source_type             = "image"
        # Optional
        boot_volume_size_in_gbs = "50"
#        kms_key_id              = 
    }
    preserve_boot_volume = false
}

locals {
    Bastion_id            = oci_core_instance.Bastion.id
    Bastion_public_ip     = oci_core_instance.Bastion.public_ip
    Bastion_private_ip    = oci_core_instance.Bastion.private_ip
}

output "bastionPublicIP" {
    value = local.Bastion_public_ip
}

output "bastionPrivateIP" {
    value = local.Bastion_private_ip
}

# ------ Create Block Storage Attachments

# ------ Create VNic Attachments


# ------ Create Loadbalancer
resource "oci_load_balancer_load_balancer" "Cockroachdb_Lb001" {
    # Required
    compartment_id = local.Cockroachdb_Ref_Arch_id
    shape          = "100Mbps"
    display_name   = "cockroachdb-lb001"
    subnet_ids     = [
                    local.Cockroachdb_Public_Sn_id                    ]
    # Optional
    is_private     = false
}

locals {
    Cockroachdb_Lb001_id            = oci_load_balancer_load_balancer.Cockroachdb_Lb001.id
    Cockroachdb_Lb001_ip_address    = oci_load_balancer_load_balancer.Cockroachdb_Lb001.ip_address_details[0]["ip_address"]
    Cockroachdb_Lb001_url           = format("http://%s", oci_load_balancer_load_balancer.Cockroachdb_Lb001.ip_address_details[0]["ip_address"])
}

output "cockroachdb-lb001IPAddress" {
    value = local.Cockroachdb_Lb001_ip_address
}

output "cockroachdb-lb001URL" {
    value = format("http://%s", local.Cockroachdb_Lb001_ip_address)
}

locals {
    Cockroachdb_Lb001_backend_set_name = "Cockroachdb_Lb001BackendSet"
    Cockroachdb_Lb001_listener_name    = "Cockroachdb_Lb001Listener"
}

# ------ Create Loadbalancer Backend Set
resource "oci_load_balancer_backend_set" "Cockroachdb_Lb001BackendSet" {
    # Required
    health_checker {
        # Required
        protocol            = "HTTP"
        # Optional
        interval_ms         = 5000
        port                = "80"
#        response_body_regex = 
#        retries             = 100
#        return_code         = 200
        timeout_in_millis   = 3000
        url_path            = "/"
    }
    load_balancer_id = local.Cockroachdb_Lb001_id
    name             = substr(local.Cockroachdb_Lb001_backend_set_name, 0, 32)
    policy           = "ROUND_ROBIN"
}

locals {
    Cockroachdb_Lb001BackendSet_id   = oci_load_balancer_backend_set.Cockroachdb_Lb001BackendSet.id
    Cockroachdb_Lb001BackendSet_name = oci_load_balancer_backend_set.Cockroachdb_Lb001BackendSet.name
}

# ------ Create Loadbalancer Backend
resource "oci_load_balancer_backend" "Cockroachdb_Lb001Backend1" {
    # Required
    backendset_name  = local.Cockroachdb_Lb001BackendSet_name
    ip_address       = local.Cockroachdb1_private_ip
    load_balancer_id = local.Cockroachdb_Lb001_id
    port             = "80"
    # Optional
#    backup           = 
#    drain            = 
#    offline          = 
#    weight           = 
}
resource "oci_load_balancer_backend" "Cockroachdb_Lb001Backend2" {
    # Required
    backendset_name  = local.Cockroachdb_Lb001BackendSet_name
    ip_address       = local.Cockroachdb2_private_ip
    load_balancer_id = local.Cockroachdb_Lb001_id
    port             = "80"
    # Optional
#    backup           = 
#    drain            = 
#    offline          = 
#    weight           = 
}
resource "oci_load_balancer_backend" "Cockroachdb_Lb001Backend3" {
    # Required
    backendset_name  = local.Cockroachdb_Lb001BackendSet_name
    ip_address       = local.Cockroachdb3_private_ip
    load_balancer_id = local.Cockroachdb_Lb001_id
    port             = "80"
    # Optional
#    backup           = 
#    drain            = 
#    offline          = 
#    weight           = 
}

# ------ Create Loadbalancer Listener
resource "oci_load_balancer_listener" "Cockroachdb_Lb001Listener" {
    # Required
    default_backend_set_name = local.Cockroachdb_Lb001BackendSet_name
    load_balancer_id         = local.Cockroachdb_Lb001_id
    name                     = substr(local.Cockroachdb_Lb001_listener_name, 0, 32)
    port                     = "80"
    protocol                 = "HTTP"
    # Optional
    connection_configuration {
        # Required
        idle_timeout_in_seconds = 1200
    }
#    hostname_names           = []
#    path_route_set_name      = 
#    rule_set_names           = []
#    ssl_configuration {
#        # Required
#        certificate_name        = 
#        # Optional
#        verify_depth            = 
#        verify_peer_certificate = 
#    }
}

locals {
    Cockroachdb_Lb001Listener_id            = oci_load_balancer_listener.Cockroachdb_Lb001Listener.id
}
