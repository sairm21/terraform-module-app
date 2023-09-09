resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "echo env is ${var.env}"
  }
}