## Getting Started
Let's start by generating github actions resources so that we can implement a standard SDLC process to make changes to our terraform confguration via automation that runs on Git triggers. The intention here is that the github actions resources would normally be created by Account Factory customizations on a per account basis. The getting_started script mocks that out for you, so that the github actions process can work against the core `terraform` resources that make up the solution.

### Step 1
First you can run the init script to create the github actions related resourcs:
```
./getting_started
```

### Step 2
Next you can run terraform to create the core infrastructure resources:
```
cd terraform
terraform init
terraform apply
```