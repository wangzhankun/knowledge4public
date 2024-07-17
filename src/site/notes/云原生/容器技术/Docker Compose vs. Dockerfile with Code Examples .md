---
{"dg-publish":true,"page-title":"Docker Compose vs. Dockerfile with Code Examples |","url":"https://blog.purestorage.com/purely-informational/docker-compose-vs-dockerfile-with-code-examples/","tags":["云原生/docker"],"permalink":"/云原生/容器技术/Docker Compose vs. Dockerfile with Code Examples /","dgPassFrontmatter":true}
---

转载自 https://blog.purestorage.com/purely-informational/docker-compose-vs-dockerfile-with-code-examples/

A Dockerfile describes how to build a Docker image, while Docker Compose is a command for running a Docker container.

## **What Is a Dockerfile?**

A Dockerfile is a text document that contains all the commands a user needs to build a Docker image, a file used to execute code in a Docker container. When a user runs the Docker run command and specifies WordPress, Docker uses this file, the Dockerfile, to build the image. 

## **What Is Docker Compose?**

Docker Compose is a tool for defining and running Docker containers by reading configuration data from a YAML file, which is a human-readable data-serialization language commonly used for configuration files and in applications where data is being stored or transmitted. 

## **Dockerfile vs. Docker Compose: Key Differences**

### **Dockerfile vs. Docker Compose: Overview**

Although both were invented by Docker and are part of the Docker universe, Dockerfile and Docker Compose are two different things with different functions. A [Dockerfile](https://docs.docker.com/engine/reference/builder/#:~:text=A%20Dockerfile%20is%20a%20text,can%20use%20in%20a%20Dockerfile%20.) is a text document with a series of commands used to build a Docker image. Docker Compose is a tool for defining and running multi-container applications. 

### **When to Use and How to Run a Dockerfile: Example**

A Dockerfile can be used by anyone wanting to build a Docker image. To use a Dockerfile to build a Docker image, you need to use docker build commands, which use a “context,” or the set of files located in the specified PATH or URL. The build process can refer to any of the files in the context, and the URL parameter can refer to Git repositories, pre-packaged tarball contexts, or plain text files.

According to [Docker](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/):

> “A Docker image consists of read-only layers, each of which represents a Dockerfile instruction. The layers are stacked and each one is a delta of the changes from the previous layer.”

In this Dockerfile:

![Dockerfile](https://blog.purestorage.com/wp-content/uploads/2022/08/Dockerfile.png)

Each instruction creates one layer:

FROM creates a layer from the ubuntu:18.04 Docker image.

COPY adds files from your Docker client’s current directory.

RUN builds your application with make.

CMD specifies what command to run within the container.

Running an image and generating a container adds a new writable layer, the “container layer,” on top of the underlying layers. All changes made to the running container, such as writing new files, modifying existing files, and deleting files, are written to this writable container layer.

![Dockerfile](https://blog.purestorage.com/wp-content/uploads/2022/08/Dockerfile2.png)

For more information about Dockerfiles and how to use them, see Docker’s [documentation](https://docs.docker.com/engine/reference/builder/#:~:text=A%20Dockerfile%20is%20a%20text,can%20use%20in%20a%20Dockerfile%20.). 

### **When to Use and How to Run Docker Compose: Example**

Use Docker Compose to run multi-container applications. 

To use Docker Compose, you need to use a YAML file to configure your application’s services. Then, with a single command, you can create and start all the services from your configuration. 

To use Docker Compose:

1.  Use a Dockerfile to define your app’s environment so it can be reproduced anywhere.
2.  Define the services that make up your app in docker-compose.yml so you can run them together in an isolated environment.
3.  Use *docker compose up* and *Docker compose command* to start and run your entire app. 

Here’s an example of a docker-compose.yml:

For more information about Docker Compose, see Docker’s [documentation](https://docs.docker.com/compose/compose-file/). 

### **Does Docker Compose replace Dockerfile?**

No—Docker Compose does not replace Dockerfile. Dockerfile is part of a process to build Docker images, which are part of containers, while Docker Compose is used for orchestrating. 

### **Is Docker-Compose the Same as Docker Compose?**

Docker Compose is the name of the tool, while docker-compose is the name of the actual command—i.e., the code—used in Docker Compose. 

### **Should You Use Docker Compose in Production?**

Yes. Docker Compose works in all environments: production, staging, development, testing, as well as CI workflows. 

## **Why Choose Pure for Your Containerization Needs** 

Pure offers various solutions that make container usage and orchestration as easy as possible for your company. 

These solutions include [container storage as a service for hybrid cloud](https://www.purestorage.com/solutions/infrastructure/containers.html), which combines the agility of public cloud with the reliability and security of on-premises infrastructure, and [Portworx](https://www.purestorage.com/products/cloud-native-applications/portworx.html)®, the most complete Kubernetes data service platform. 

Get started with Pure today. [Contact us](https://www.purestorage.com/contact.html) to learn more. 

![](https://pixel.welcomesoftware.com/px.gif?key=YXJ0aWNsZT1jNTk2YzQ2YzE5ODMxMWVkOWNiMDZhYTA0NDViZDMwNw==)