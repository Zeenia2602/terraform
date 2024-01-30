terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.61.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = "NE4AVLBVTAY47XMI"
  cloud_api_secret = "ObWryyUttLaKhWvC6ynyjm3z5mv9JuFd/6r6+F+MbU4KkrgogL49fxUAPXRfFQ38"
}

resource "confluent_environment" "terraform" {
  display_name = "Terraform"

}

resource "confluent_kafka_cluster" "basic" {
  display_name = "Kafka_terraform_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  basic {}
  environment {
    id = confluent_environment.terraform.id
  }
}


#----- Information regarding the "manager" service account -------

resource "confluent_service_account" "manager" {
  display_name = "employee_manager"
  description  = "Service account to manage the 'Kafka_terraform_cluster' kafka cluster"
}

resource "confluent_role_binding" "kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

resource "confluent_api_key" "manager-api-key" {
  display_name = "manager-api-key"
  description  = "Kafka API Key that is owned by 'manager' service account"
  owner {
    id          = confluent_service_account.manager.id
    api_version = confluent_service_account.manager.api_version
    kind        = confluent_service_account.manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = confluent_environment.terraform.id
    }
  }

  depends_on = [
    confluent_role_binding.kafka-cluster-admin
  ]

}


#---- Creating a Kafka topic -----

resource "confluent_kafka_topic" "test" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "emp_test"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-api-key.id
    secret = confluent_api_key.manager-api-key.secret
  }
}


#---- Information regarding the "producer" service account ------

resource "confluent_service_account" "emp-producer" {
  display_name = "employee_producer"
  description  = "Service account to produce to 'employees' topic"
}

resource "confluent_api_key" "emp-producer-api-key" {
  display_name = "emp-producer-api-key"
  description  = "Kafka API Key owned by 'employee producer' service account"
  owner {
    id          = confluent_service_account.emp-producer.id
    api_version = confluent_service_account.emp-producer.api_version
    kind        = confluent_service_account.emp-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = confluent_environment.terraform.id
    }
  }
}


#---- Creating the service account for consumer ------

resource "confluent_service_account" "emp-consumer" {
  display_name = "employee-consumer"
  description  = "Service account to consumer the 'employees' topic"
}

resource "confluent_api_key" "emp-consumer-api-key" {
  display_name = "emp-consumer-api-key"
  description  = "Kafka API Key owned by the 'emp-consumer' service account"

  owner {
    id          = confluent_service_account.emp-consumer.id
    api_version = confluent_service_account.emp-consumer.api_version
    kind        = confluent_service_account.emp-consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = confluent_environment.terraform.id
    }
  }
}

#---- Providing cluster acl-----

#DESCRIBE
resource "confluent_kafka_acl" "emp-describe-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.manager.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-api-key.id
    secret = confluent_api_key.manager-api-key.secret
  }

  depends_on = [
    confluent_role_binding.kafka-cluster-admin
  ]
}

#CREATE
resource "confluent_kafka_acl" "emp-create-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.manager.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-api-key.id
    secret = confluent_api_key.manager-api-key.secret
  }

  depends_on = [
    confluent_role_binding.kafka-cluster-admin
  ]
}

#IDEMPOTENT_WRITE
resource "confluent_kafka_acl" "emp-idempotent-write-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.manager.id}"
  host          = "*"
  operation     = "IDEMPOTENT_WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-api-key.id
    secret = confluent_api_key.manager-api-key.secret
  }

  depends_on = [
    confluent_role_binding.kafka-cluster-admin
  ]
}

#CLUSTER_ACTION
resource "confluent_kafka_acl" "emp-cluster_action-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.manager.id}"
  host          = "*"
  operation     = "CLUSTER_ACTION"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-api-key.id
    secret = confluent_api_key.manager-api-key.secret
  }
  depends_on = [
    confluent_role_binding.kafka-cluster-admin
  ]


}


#---- Providing producer acl for topic -----

#WRITE
resource "confluent_kafka_acl" "emp-producer-write-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.test.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.emp-producer.id}"
  host          = "*"
  operation     = "WRITE"
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

#DESCRIBE
resource "confluent_kafka_acl" "emp-describe-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.test.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.emp-producer.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-api-key.id
    secret = confluent_api_key.manager-api-key.secret
  }
  depends_on = [
    confluent_role_binding.kafka-cluster-admin
  ]
}

#DELETE the topic 
resource "confluent_kafka_acl" "emp-topic-delete" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.test.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.emp-producer.id}"
  host          = "*"
  operation     = "DELETE"
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

#----- Provice consumer acl for topic ------

#READ
resource "confluent_kafka_acl" "emp-consumer-read-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.test.topic_name
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

#READ using Consumer group
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

#DESCRIBE consumer group 
resource "confluent_kafka_acl" "emp-consumer-group-describe" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "GROUP"
  resource_name = "confluent_cli_consumer_"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.emp-consumer.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-api-key.id
    secret = confluent_api_key.manager-api-key.secret
  }

  depends_on = [
    confluent_role_binding.kafka-cluster-admin
  ]
}

#DELETE consumer group 
resource "confluent_kafka_acl" "emp-consumer-group-delete" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  resource_type = "GROUP"
  resource_name = "confluent_cli_consumer_"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.emp-consumer.id}"
  host          = "*"
  operation     = "DELETE"
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
