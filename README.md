Deploy Rails app as a Docker container with Capistrano
======================================================

This is a sample rails source tree.

- Build application images on the server where the app runs
- Use capistrano to fetch source and organize tasks
- Log container IDs and stop the previous app container

Tasks
-----

### deploy:docker:build

builds an application image. runs after deploy:updating.

### deploy:docker:run

runs the application container. sets the container id as `cid`. this task is supposed to be invoked in `deploy:restart`.

### deploy:docker:stop

stops the last container in the containers.log (see below.)

### deploy:docker:log

logs container ids and source SHA-1 in `containers.log` file.


To complete your deployment
---------------------------

You have to write a task that configure your web server at the end of deployments.
