resource "null_resource" "test" {
  triggers = {
    abc = timestamp()
  }
  provisioner "local-exec" {
    command = "echo env is ${var.env}"
  }
}