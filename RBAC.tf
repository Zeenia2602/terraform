terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.61.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

resource "confluent_environment" "terraform_rbac" {
  display_name = "Terraform_rbac"

}

resource "confluent_kafka_cluster" "standard" {
  display_name = "Kafka_terraform_rbac_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  standard {}
  environment {
    id = confluent_environment.terraform_rbac.id
  }
}


#----- Information regarding the "manager-rbac" service account -------

resource "confluent_service_account" "manager-rbac" {
  display_name = "emp_manager"
  description  = "Service account to manage the 'Kafka_terraform_rbac_cluster' kafka cluster"
}

resource "confluent_role_binding" "kafka-cluster-admin-rbac" {
  principal   = "User:${confluent_service_account.manager-rbac.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.standard.rbac_crn
}

resource "confluent_api_key" "manager-rbac-api-key" {
  display_name = "manager-rbac-api-key"
  description  = "Kafka API Key that is owned by 'manager-rbac' service account"
  owner {
    id          = confluent_service_account.manager-rbac.id
    api_version = confluent_service_account.manager-rbac.api_version
    kind        = confluent_service_account.manager-rbac.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.terraform_rbac.id
    }
  }

  depends_on = [
    confluent_role_binding.kafka-cluster-admin-rbac
  ]

}


#---- Creating a Kafka topic -----

resource "confluent_kafka_topic" "test_rbac" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "employees"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.manager-rbac-api-key.id
    secret = confluent_api_key.manager-rbac-api-key.secret
  }
}


#---- Information regarding the "producer" service account ------

resource "confluent_service_account" "emp-producer-rbac" {
  display_name = "emp_producer"
  description  = "Service account to produce to 'employees' topic"
}

resource "confluent_api_key" "emp-producer-rbac-api-key-rbac" {
  display_name = "emp-producer-rbac-api-key-rbac"
  description  = "Kafka API Key owned by 'employee producer' service account"
  owner {
    id          = confluent_service_account.emp-producer-rbac.id
    api_version = confluent_service_account.emp-producer-rbac.api_version
    kind        = confluent_service_account.emp-producer-rbac.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.terraform_rbac.id
    }
  }
}


#---- Creating the service account for consumer ------

resource "confluent_service_account" "emp-consumer-rbac" {
  display_name = "emp-consumer"
  description  = "Service account to consumer the 'employees' topic"
}

resource "confluent_api_key" "emp-consumer-rbac-api-key-rbac" {
  display_name = "emp-consumer-rbac-api-key-rbac"
  description  = "Kafka API Key owned by the 'emp-consumer-rbac' service account"

  owner {
    id          = confluent_service_account.emp-consumer-rbac.id
    api_version = confluent_service_account.emp-consumer-rbac.api_version
    kind        = confluent_service_account.emp-consumer-rbac.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.terraform_rbac.id
    }
  }
}

#----- Creating role - binding -----

#Write into the topic
resource "confluent_role_binding" "emp-producer-developer-write" {
  principal   = "User:${confluent_service_account.emp-producer-rbac.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.test_rbac.topic_name}"

}

#Read from topic
resource "confluent_role_binding" "emp-consumer-read-topic" {
  principal   = "User:${confluent_service_account.emp-consumer-rbac.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.test_rbac.topic_name}"

}

#Read from consumer group
resource "confluent_role_binding" "emp-consumer-group-developer-read" {
  principal   = "User:${confluent_service_account.emp-consumer-rbac.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=confluent_cli_consumer"

}

