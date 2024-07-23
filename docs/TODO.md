- [ ] Terraform multiear le environments, repeat config for multiple environments
- [ ] IAM 
- [ ] test using default service account for cloud build trigger (modules/frontend/main.tf)
- [ ] use more granual permissions for cloud build service account (modules/frontend/main.tf)
- [ ] fix the tf state managmenet, rn its just using a bucket in dev
- [ ] ci/cd for terraform as well?
- [ ] figure out how to do the imports for the project properly, run command or have tf blocks?  
- [ ] create google secret manager? or somehow figure out how to store django auto generated secret key 
- [ ] pass in sql database user password, other secret shit through .tfvars or something idk figure out 
- [ ] enable all the apis through terraform https://stackoverflow.com/questions/59055395/can-i-automatically-enable-apis-when-using-gcp-cloud-with-terraform 
- [ ] go through other TODOs in the repo scattered 
- [ ] create parent folder in bootstrap script
- [ ] bootstrap folder should auto generate vars.tfvars in ./terraform directory instead
- [ ] bootstrap script should take care of auto generating backend.tf
- [ ] cannot use variables in backend.tf, google_storage_bucket.tf_state
- [ ] bootstrap should also autogenerate providers.tf file 
- [ ] create a submodule called "cicd" that could be used between frontend, graphql, rest_backend, etc.  -> where can we store these modules, make it even MORE REUSABLE ACROSS SEVERAL PROEJCTS, IE. other contract/cybersex?
- [ ] move secrets into secret manager for graphql_backend


TODO before DEMO: 
- [ ] update the hardcoded frontend code with the new backend urls 
- [ ] manually create a user/however they have been creating users in the backend database to login to frontend and test
- [ ] diagram with services
- [ ] techdebt/ upcoming todo list  





IAM, DNS, organize Terraform, complete integrations with graphql and django, prduction environment, database migration, billing, terraform credentials, setup vms for chase with connectivity 


Billing ID: 

spin up VM for chase for db migration 