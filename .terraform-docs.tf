/**
 * # Environment Infrastructure `core` module
 *
 * This directory contains the [Terraform root module](https://learn.hashicorp.com/tutorials/terraform/module)
 * containing [HCL configuration](https://www.terraform.io/language/syntax/configuration)
 * and [Helm chart variables](https://helm.sh/docs/chart_template_guide/variables/)
 * for a Platykus environment running on an [AWS EKS cluster](https://aws.amazon.com/eks/).
 *
 * ## Organization
 *
 * This module is organized as follows.
 *
 * - the [`cluster`](cluster) directory is a submodule containing configuration
 *   for all platform cluster AWS resources
 * - the [`stack`](stack) directory is a submodule containing configuration
 *   for all platform stack AWS and Helm resources
 *
 * > Warning! Do not edit this README.md file directly!
 * >
 * > It has been generated with [terraform-docs](https://terraform-docs.io/)
 * > as configured by the [.terraform-docs.yml](.terraform-docs.yml) file.
 * >
 * > Make changes to this documentation in [.terraform-docs.tf](.terraform-docs.tf)
 * > and run `make docs` to regenerate this README.md file.
 */
