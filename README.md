# gcp-go-mmproxy
Startup script that  automatically installs and configures go-mmproxy on GCE instances running CentOS 7 and CentOS-stream 8. For details see https://medium.com/google-cloud/preserving-client-ips-through-google-clouds-global-tcp-and-ssl-proxy-load-balancers-3697d76feeb1

This script is also stored in a publicly accessible bucket gs://startup-script-proxy with the name gommproxy-startup.bash. You can use it by creating a VM instance with (for Centos 7):

gcloud compute instances create <instance-name> --image-project centos-cloud --image-family centos-7 --tags <Tag used for Load Balancer config> --zone us-central1-b --metadata=startup-script-url="gs://startup-script-proxy/gommproxy-startup.bash"
