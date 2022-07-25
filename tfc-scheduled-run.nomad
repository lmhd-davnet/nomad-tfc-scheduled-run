job "tfc-scheduled-run" {
  periodic {
    cron             = "@daily"
    prohibit_overlap = true
  }

  datacenters = ["davnet"]
  type        = "batch"

  group "run" {
    count = 1

    task "lmhd" {
      driver = "exec"

      vault {
        policies = [
          "default",
          "tfc-lmhd-manage-workspaces",
        ]
      }

      artifact {
        source = "https://raw.githubusercontent.com/lmhd-davnet/nomad-tfc-scheduled-run/main/run.sh"
      }

      template {
        data = <<-EOF
          {{ with secret "kv/data/terraform/tfc/lmhd/manage-workspaces" }}
          TOKEN={{ .Data.data.token }}
          ORG=lmhd
          {{ end }}
        EOF

        destination = "secrets/tfc.env"
        env         = true
      }

      config {
        command = "run.sh"
      }

      resources {
        cpu    = 100
        memory = 10
      }
    }

    task "hashi_strawb_testing" {
      driver = "exec"

      vault {
        policies = [
          "default",
          "tfc-hashi_strawb_testing-manage-workspaces",
        ]
      }

      artifact {
        source = "https://raw.githubusercontent.com/lmhd-davnet/nomad-tfc-scheduled-run/main/run.sh"
      }

      template {
        data = <<-EOF
          {{ with secret "kv/data/terraform/tfc/hashi_strawb_testing/manage-workspaces" }}
          TOKEN={{ .Data.data.token }}
          ORG=hashi_strawb_testing
          {{ end }}
        EOF

        destination = "secrets/tfc.env"
        env         = true
      }

      config {
        command = "run.sh"
      }

      resources {
        cpu    = 100
        memory = 10
      }
    }
  }
}
