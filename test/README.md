# gitlab_backup Testing

The test directory contains a fully functional Docker Stack that can be used
to test the image.  We also provide a Terraform configuration to make things
easier to run on your workstation and test on a CI server.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html)
* A machine that runs [Docker](https://www.docker.com/) and can become a swarm.  
  We've mostly tested this on Mac and Linux but think it will work on Windows
  10, properly configured.

## Testing it

1. Make sure your machine isn't already a Docker swarm, we assume a completely
  clean machine as this is the procedure we use on our CI server
1. Clone this repository
1. Go to the test directory in a command window
1. Run `terraform init`
1. Run  `terrafrom apply`. This will create the Docker Stack and test it.
1. If you're done testing run `terrafrom destroy`
