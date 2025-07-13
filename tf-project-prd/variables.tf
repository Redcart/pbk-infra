variable "project_id" {
  description = "Google Cloud Platform Project ID"
  type        = string
}

variable "project_number" {
  description = "Google Cloud Platform Project number"
  type        = string
}

variable "region" {
  description = "Google Cloud Platform region (Zurich)"
  type        = string
}

variable "global_region" {
  description = "Google Cloud Platform global region"
  type        = string
}

variable "gcp_credentials" {
  description = "Google Cloud Platform SA for Terraform key file path"
  type        = string
}

variable "sa_terraform" {
  description = "Google Cloud Platform SA for Terraform name"
  type        = string
}

variable "sa_gh_cicd" {
  description = "Google Cloud Platform SA for github actions CI/CD"
  type        = string
}

variable "sa_ingestion" {
  description = "Google Cloud Platform SA for ingestion"
  type        = string
}

variable "gcs_pbk_ingestion_bucket_name" {
  description = "Google Cloud Storage Bucket for ingestion"
  type        = string
}

variable "cs_pbk_ingestion_stations" {
  description = "Google Cloud Scheduler for stations ingestion"
  type        = string
}

variable "cs_pbk_ingestion_bikes" {
  description = "Google Cloud Scheduler for bikes capacitty ingestion"
  type        = string
}

variable "cf_pbk_ingestion" {
  description = "Google Cloud Run Function name for ingestion"
  type        = string
}

variable "cs_pbk_ingestion_stations_decoupled" {
  description = "Google Cloud Scheduler for stations extract"
  type        = string
}

variable "cs_pbk_ingestion_bikes_decoupled" {
  description = "Google Cloud Scheduler for bikes capacitty extract"
  type        = string
}

variable "cf_pbk_extract_decoupled" {
  description = "Google Cloud Run Function name for extract"
  type        = string
}

variable "bq_pbk_ingestion_dataset" {
  description = "Google Cloud BigQuery Dataset"
  type        = string
}

variable "bq_pbk_ingestion_stations_table" {
  description = "Google Cloud BigQuery Table for stations"
  type        = string
}

variable "bq_pbk_ingestion_bikes_capacity_table" {
  description = "Google Cloud BigQuery Table for bikes capacity"
  type        = string
}

variable "sa_composer" {
  description = "Google Cloud Platform SA for composer"
  type        = string
}

variable "gcs_pbk_composer_bucket_name" {
  description = "Google Cloud Storage Bucket for composer"
  type        = string
}

variable "api_url" {
  description = "url of Publibike API"
  type        = string
}