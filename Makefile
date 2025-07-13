
.PHONY dev-to-stg
dev-to-stg:
	@echo "Deploying from dev to staging environment..."
	rsync -av tf-project-dev/ \
		tf-project-stg \
		--exclude-from files_to_exclude.txt
	@echo "Deployment to staging completed."

.PHONY stg-to-prd
stg-to-prd:
	@echo "Deploying from staging to production environment..."
	rsync -av tf-project-stg/ \
		tf-project-prd \
		--exclude-from files_to_exclude.txt
	@echo "Deployment to production completed."