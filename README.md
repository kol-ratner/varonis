## Getting Started
Let's start by generating github actions resources so that we can implement a standard SDLC process to make changes to our terraform confguration via automation that runs on Git triggers. 

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