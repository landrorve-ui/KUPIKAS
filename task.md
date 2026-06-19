## Tasks for you to work on


[x] - build docker images for: backend port 3333, queue-job port 3334, trigger-job port 3335, migration

[x] - kubernetes with backend, queue-job, trigger-job,
      database will be auroradb outside of kubernetes cluster.

      all backend, queue-job, trigger-job can scaleup/down, so need loadbalancing

[x] - teraform to build infra aws, config probally, kubernetes in private subnets

[x] - github actions to run workflows: build docker images, push ecr, migrate db, deploy all services