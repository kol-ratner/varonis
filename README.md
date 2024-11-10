## Getting Started
Let's start by generating github actions resources so that we can implement a standard SDLC process to make changes to our terraform confguration via automation that runs on Git triggers. The intention here is that the github actions resources would normally be created by Account Factory customizations on a per account basis. The getting_started script mocks that out for you, so that the github actions process can work against the core `terraform` resources that make up the solution.

### Step 1
First create a `.env` file at the root of the repo with the following variables, be sure to populate the values with your aws access key and secret:
```
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_REGION="eu-west-1"
```

### Step 2
Next you can run the init script to create the github actions related resources:
```
./getting_started
```