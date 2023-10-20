# Coaching - Building and Automating a Dockerized Python Web Application using Trunk Based Development

Creating a feature-flagged Python web application and deploying it through a pipeline involves multiple stages, including writing the application, integrating the feature flag, and setting up a CI/CD pipeline for deployment. 

Step-by-step guide using Flask for the web app, a basic feature flag, GitHub for source control, and GitHub Actions for the CI/CD pipeline.

Step 1: Writing the Flask Application
First, we'll create a simple Flask application. If you don't have Flask installed, you can install it using 
pip install Flask
Now, create a file named app.py and write your Flask application. Below is a simple web application with a feature flag for demonstration:

```python
# app.py
from flask import Flask
import os

app = Flask(__name__)

# Feature flag
NEW_FEATURE = os.getenv("NEW_FEATURE") == "true"


@app.route('/')
def hello_world():
    if NEW_FEATURE:
        return 'New Feature is ON!'
    else:
        return 'Old Feature is running.'


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
```

In this script, we check for an environment variable "NEW_FEATURE" to toggle between features.

Step 2: Dockerizing the Flask Application

For easier deployment, you can containerize your application with Docker. Create a file named Dockerfile in your project directory and add the following content:



````Dockerfile
# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project
COPY . /app/

# Run the application
CMD ["python", "app.py"]
```````

And don't forget to define your Flask dependency in a requirements.txt file:
``````
Flask==2.0.2 # Use the current version you're working with
``````


Step 3: Setting Up GitHub Actions for CI/CD

In your GitHub repository, navigate to the "Actions" tab and create a new workflow, or manually create a github/workflows directory in your project, then add a workflow file, e.g., ci-cd-pipeline.yml.

Define the following workflow in the ci-cd-pipeline.yml. This configuration sets up a CI/CD pipeline that automatically deploys your Dockerized application when you push to the repository.

``````
name: CI/CD Pipeline
on:
  push:
    branches:
      - main  # Or your default branch

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Check out code
        uses: actions/checkout@v2

      - name: Build and push Docker image
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: your-dockerhub-username/your-repo:latest  # Replace with your Docker Hub username and repository name

  deploy:
    runs-on: ubuntu-latest
    needs: build  # Ensures the build job completes before this runs
    steps:
      # Steps to deploy the application (e.g., SSH into your server, pull the latest Docker image, and restart your service)
      # The specific steps can vary depending on your hosting environment and whether you're using a service like AWS ECS, Kubernetes, etc.

      - name: SSH and deploy  # Example step
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            docker pull your-dockerhub-username/your-repo:latest
            docker stop my-running-container || true
            docker rm my-running-container || true
            docker run -d --name my-running-container -e NEW_FEATURE=true -p 80:5000 your-dockerhub-username/your-repo:latest
``````

In the deploy job, replace the placeholders with your server's actual SSH details and Docker image information.


Step 4: Pushing Your Code

Add the files to your local Git repository:

```
git add .
```
Commit the changes:
``````
git commit -m "Add a feature-flagged Flask app with CI/CD"
``````
Push your changes to GitHub:
``````
git push origin main
``````
After you push your code, GitHub Actions triggers the CI/CD pipeline based on your workflow definition. It builds a Docker image from your application, pushes it to Docker Hub (or another registry), and deploys it by pulling the image on your server and running it as a container.

Please ensure you have the necessary secrets (SSH_HOST, SSH_USERNAME, SSH_KEY) stored in your repository's secrets section. 

This example is quite basic, and a real-world scenario would require more robust error checking, rollback strategies, handling of sensitive data, and potentially different strategies for blue/green or canary deployments.

