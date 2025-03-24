.PHONY: build destroy

# Ask for user input and store in variables
build:
	@read -p "Enter full path for serviceaccount.json : " gcp_key; \
	echo  "Enter serviceaccount name "; \
	read -p "(the part before '@' sign of the email provided by gcp can be found in IAM & admin/serviceaccount): " service_account; \
	read -p "Enter your project_id : " project_id; \
	read -p "Enter region : " region; \
	read -p "Enter zone : " zone; \
	read -p "Enter your public IP address : " ip_address; \
	read -p "Enter bucket name (deployment) : " deployment_bucket_name; \
	read -p "Enter bucket name (datalake) : " datalake_bucket_name; \
	read -p "Enter dataset name (bigQuery) : " dataset_name; \
	read -p "Enter API key (TomTom) : " TOMTOM_KEY; \
	read -p "Enter API key (LocationIQ) : " LOCATIONIQ_KEY; \
	echo "Build Start"; \
	echo "Making a copy of serviceaccount.json at src/airflow as k.json"; \
	cp $$gcp_key ./src/airflow/k.json ; \
	sleep 0.5; \
	echo "Generating SSH key $$HOME/.ssh/gcp_key ..."; \
	sleep 0.5; \
	if [ ! -f ~/.ssh/gcp_key ]; then \
		ssh-keygen -t rsa -b 4096 -f $$HOME/.ssh/gcp-key -C "airflow_instance"; \
		echo "Key generated successfully"; \
	else  \
		echo "Key already exists"; \
	fi; \
	sleep 0.5; \
	ssh_key=$$HOME/.ssh/gcp_key.pub; \
	echo "Exporting terraform variables"; \
	sleep 0.5; \
	export TF_VAR_gcp_key=$$gcp_key; \
	export TF_VAR_service_account=$$service_account; \
	export TF_VAR_project_id=$$project_id; \
	export TF_VAR_region=$$region; \
	export TF_VAR_zone=$$zone; \
	export TF_VAR_ssh_user='airflow'; \
	export TF_VAR_ssh_key=$$ssh_key; \
	export TF_VAR_ip_address=$$ip_address; \
	export TF_VAR_deployment_bucket_name=$$deployment_bucket_name; \
	export TF_VAR_datalake_bucket_name=$$datalake_bucket_name; \
	export TF_VAR_dataset_name=$$dataset_name; \
	sleep 0.5; \
	echo "Generating .env file for docker container"; \
	echo "TOMTOM_KEY=$$TOMTOM_KEY\nLOCATIONIQ_KEY=$$LOCATIONIQ_KEY\nBUCKET_NAME=$$datalake_bucket_name\nDATASET_NAME=$$dataset_name\nAIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT=google-cloud-platform://?extra__google_cloud_platform__project=$$project_id&extra__google_cloud_platform__key_path=/usr/local/airflow/k.json\nDBT_BIGQUERY_PROJECT=$$project_id\nDBT_BIGQUERY_DATASET=$$dataset_name" > ./src/airflow/.env; \
	sleep 0.5; \
	echo "Zipping source code for upload to compute instance"; \
	zip -r src.zip ./src/airflow; \
	echo ""; \
	echo "Running Terraform"; \
	echo ""; \
	echo "Cloud ressource provisionned successfully"; \
	echo ""; \
	echo "Wait for astro cosmos starting airflow then run : "; \
	echo "ssh -i $$HOME/.ssh/gcp_key -L 8080:127.0.0.1:8080 airflow@{IP_address_of_compute_instance} - to access airflow UI from your browser at localhost:8080"

destroy:
	@echo "Destroying Cloud ressource data on relative ressources will be destroyed"; \
	cd terraform; \
	terraform destroy;
