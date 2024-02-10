I have created resources on Confluent cloud via terraform.

Resources:

    1 evironmen
    1 kafka cluster
    3 service accounts
    1 Cloud API key.

I have assigned the ACL and RBAC permissions to these resources.

**Steps to perform ACL and RBAC using Terraform:**

1. Create a Cloud API Key on Confluent Cloud and assidn the **_OrganizationAdmin_** role to service account you have created for Cloud API key.
2. Create a resource on Confluent Cloud via Terraform
    1. **Terraform Code Snippet for RABC**

           resource "confluent_role_binding" "emp-producer-developer-write" {
              principal   = "User:${confluent_service_account.emp-producer-rbac.id}"
              role_name   = "DeveloperWrite"
              crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.test_rbac.topic_name}"
            
            }
   
    2. **Terraform Code Snippet for ACL**
    
           resource "confluent_kafka_acl" "emp-consumer-group-read" {
              kafka_cluster {
                id = confluent_kafka_cluster.basic.id
              }
            
              resource_type = "GROUP"
              resource_name = "confluent_cli_consumer_"
              pattern_type  = "LITERAL"
              principal     = "User:${confluent_service_account.emp-consumer.id}"
              host          = "*"
              operation     = "READ"
              permission    = "DENY"
              rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
              credentials {
                key    = confluent_api_key.manager-api-key.id
                secret = confluent_api_key.manager-api-key.secret
              }
            
              depends_on = [
                confluent_role_binding.kafka-cluster-admin
              ]
            }
       
3. Download and install the providers defined in the configuration:
   1. _terraform init_
      
   
   **OUTPUT**

![image](https://github.com/Zeenia2602/terraform/assets/87160157/91436d35-0578-4245-b7ab-d67130efc720)


4. Validate the terraform script:
   1.  _terraform validate_

   **OUTPUT**
   
   ![image](https://github.com/Zeenia2602/terraform/assets/87160157/c055600d-0423-4c74-8e91-2ee9984be5ee)


5. If you want your script to be in proper format use the following command:
   1. _terraform fmt_
   
6. To see what your script going to do, run the following command:
    1. _terraform plan_
   
   **OUTPUT**

   ![image](https://github.com/Zeenia2602/terraform/assets/87160157/63a72af8-f4af-4688-aa72-f9d8167ee205)

 
7. Run the terraform script:
   1. _terraform apply_
    
    **OUTPUT**

    ![image](https://github.com/Zeenia2602/terraform/assets/87160157/0dc510cf-3473-4c00-b814-9da24f6c4e9e)
 
       
