---
title: "Deploying and Hosting a React App and its Back-end on Google Cloud with Adapt.js"
author: Manish Vachharajani
authorTitle: Co-founder, Unbounded Systems
authorURL: https://twitter.com/mvachhar
authorTwitter: mvachhar
authorImageURL: /img/profiles/manish.jpg
image: blog/assets/react-node-gcp-gke.png
description: "A simple way to deploy, host, and manage a full-stack React App and Node.js Express API back-end using Google Cloud."
---

![React Node.js GKE GCP](assets/react-node-gcp-gke.png)

With all the different cloud service offerings, hosting solutions, and automation tools, figuring out how to get your app up and running in the cloud can be quite a challenge.
In this article, I'll show you how to host your React front-end, Node.js back-end, and database on Google Cloud Platform (GCP) using a single command from an open source tool called [Adapt](https://adaptjs.org).

<!-- truncate -->

Before we can do this, though, we have to install some software and set up your Google Cloud account, so let's get started!

## Installing the tools

In this example we are going to deploy to a Google Kubernetes Engine (GKE) cluster on Google Cloud Platform.
To do this we're going to need a few tools.
If you don't already have the [Google Cloud SDK](https://cloud.google.com/sdk/) (`gcloud` command) and [Docker](https://docker.com) installed, you'll need to install them first, along with [Node.js](https://nodejs.org) and [Yarn](https://yarnpkg.com):

- Google Cloud SDK ([installation instructions](https://cloud.google.com/sdk/docs/quickstarts))
- Docker ([installation instructions](https://docs.docker.com/install/#supported-platforms))
- Node.js and Yarn ([installation instructions](https://adaptjs.org/docs/user/install/requirements))

Next, installing Adapt is the easy part, just do:
<!-- doctest command -->

```bash
npm install -g @adpt/cli
```
<!-- doctest output { matchRegex: "\\+ @adpt/cli@" } -->

:::note
If you get an `EACCES` error from `npm install`, retry the command as administrator (e.g. `sudo npm install -g @adpt/cli`).
Or, you can use `npx` as explained at the bottom of [this page](https://adaptjs.org/docs/getting_started/install)
:::

## Setting up Your Project

For this article, I'm going to set up a simple Adapt project that has a "Hello World!" React front-end, a "Hello World!" Express back-end, and a Postgres database in a single monorepo.
We'll look at how to customize this setup for your application a bit later.  
If you already have your React application ready, you can follow along here and then copy your React application into the directory we create.
You can also use the example here as a guide for setting up your existing repository, or using multiple repositories.

Adapt provides a starter template that you can use to quickly set up a new project.  
For this example, we are going to use the [`hello-react-node-postgres` starter](https://gitlab.com/adpt/starters/hello-react-node-postgres).  
There are [other starters](https://gitlab.com/adpt/starters) as well, or you can write your own, any git URL will work.
To set up our starter, simply type:
<!-- doctest command -->

```bash
adapt new hello-react-node-postgres ./myapp
```

This will create a directory called `myapp` and set it up with all the files required to start a new React app (using [create-react-app](https://create-react-app.dev)), an Express back-end, and an Adapt project.
The React app is in the `./myapp/frontend` directory, the back-end is in `./myapp/backend` directory and the Adapt project is in `./myapp/deploy`.

## Setting up Google Cloud

First, there's a bunch of one-time setup in order to get your first Kubernetes cluster created on GKE.
Once the cluster is created, you can deploy (and re-deploy) apps to it without having to repeat the steps from this section.

I'll assume you haven't set up Google Cloud before, so you may be able to omit some steps in this section if you've done them before.

1. Create an account

    If you don't already have a Google Cloud account, first set one up [using these instructions](https://console.cloud.google.com/getting-started).
    Make sure you enter your billing information, if necessary (e.g., there is no free trial).

1. Log in

    If you haven't previously logged in using the `gcloud` CLI, do that now:

    ```bash
    gcloud auth login
    ```

1. Create a project

    We'll create a new Google Cloud project so everything we create in this tutorial is easy to clean up at the end.
    For this step, you'll need to choose a project ID that's unique across all of Google Cloud -
    not unique to your account, not unique to your organization, but unique to all of Google Cloud Platform, globally, around the world.

    Run the following command, which will create the project and set it as our default project. Replace `your_project_id` with the project ID you chose.

    ```bash
    gcloud projects create --set-as-default your_project_id
    ```

    :::tip
    If you get an error that says the project ID you specified is already in use, just pick a new ID and run the command again.
    :::

    Now, set a variable with the project name you chose so we can use it in later steps. Again, replace `your_project_id` with the one you chose.

    ```bash
    MYPROJECTID=your_project_id
    ```

1. Set compute zone and enable the Kubernetes Engine API

    The first command sets our default [compute zone](https://cloud.google.com/compute/docs/regions-zones/#available) where our resources will be created.
    The second command to enable the API may take quite a while, so be patient.
    Google says it can take "several minutes".

    <!-- doctest command -->
    ```bash
    gcloud config set compute/zone us-central1-b
    gcloud services enable container.googleapis.com
    ```

    :::tip
    If you get a **Billing must be enabled** error, follow the link provided in the error to enable billing, then re-run the command.
    :::

1. Create a Kubernetes cluster

    :::warning
    This is where Google will start charging you.
    Don't worry, we'll clean everything up at the end.
    :::

    Now create a Kubernetes cluster called `mycluster`.
    For this tutorial, we'll create a small, single node, non-production cluster to keep the cost down.

    <!-- doctest command -->
    ```bash
    gcloud container clusters create mycluster --enable-ip-alias --machine-type "g1-small" --disk-size "30" --num-nodes "1" --no-enable-cloud-monitoring --no-enable-cloud-logging
    ```

    It will take a few minutes before the cluster is up, but the command will give you some status along the way.  

1. Get the cluster credentials

    Now, we have to set up credentials for the Kubernetes cluster and Docker.  
    Just run the following commands, answer yes when it asks you if it is OK to update your configuration.

    <!-- doctest command -->
    ```bash
    gcloud container clusters get-credentials mycluster
    gcloud auth configure-docker --quiet
    ```

## Creating a Deployment for your App

Now that we have a running Kubernetes cluster, we are ready to deploy our app!

<!-- doctest command -->
```bash
cd myapp/deploy
export KUBE_DOCKER_REPO=gcr.io/${MYPROJECTID}
adapt run k8s-test --deployID app-test
```

This will run the Adapt project, which builds our Hello World React app and deploys a test version of the app to the cluster.

You can access the application by looking up the IP address of the exposed service via the [GCP console](https://console.cloud.google.com).  
Navigate to `Compute > Kubernetes Engine > Clusters` in the menu.  
Then, click on `Services & Ingress` in the left pane.
In the `Endpoints` column, one of the addresses should be a clickable link.
Click the link and you should see "Hello World!" from your newly deployed React app.

You'll also notice that we've deployed some additional internal services, including the Node.js Express back-end and a Postgres database service, in addition to the React front-end.
We'll see how to make use of those in a moment.

## Writing Code and Updating the Deployment

Now that we have Hello World running, we can edit the React app code and easily push the changes to GKE.
For example, try changing the `Hello World` text in the `myapp/frontend/src/App.js` file.

Then, when you're ready to push your changes, type:

```bash
adapt update app-test  # Make sure you are in the myapp/deploy directory
```

## Turning Hello World into a full-stack MovieDB app

To expand on our Hello World app, you can follow [these instructions](https://adaptjs.org/docs/getting_started/update) to turn Hello World into a full-stack movie database search app that uses the Node.js Express back-end and Postgres database we deployed.
Once you've followed the instructions and updated your app, the app's back-end actually connects to the Postgres database to provide the movie search results.
Adapt has helpfully loaded some sample data into the test database it deployed so you can see it in action.

Once again, the last step will be to run:

```bash
adapt update app-test
```

Adapt takes care of the heavy lifting of configuring a test database, building Docker containers, pushing them to registries, writing YAML files, and all the other tedious deployment tasks.
Adapt even takes care of providing credentials for the Postgres database to the Node.js back-end through the common [`PG*`](https://www.postgresql.org/docs/current/libpq-envars.html) environment variables.

The architecture that's deployed by Adapt is fully configurable using React-like components.
If you want to customize or add services to your deployment, check out [https://adaptjs.org](https://adaptjs.org).

## Debugging in GKE

To debug your app running in GKE, you can inspect the state of the Kubernetes resources directly.
Here are a few helpful Kubernetes commands to get you going.

List running pods and services:

```bash
kubectl get pod
kubectl get svc
```

For any particular pod, you can get detailed status or logs:

```bash
kubectl describe pod <name of pod>
kubectl logs <name of pod>
```

These pod logs will contain any output from your app's `console.log` calls.

## Using an existing database

This example uses a test database provided by Adapt's `<TestPosgres />` component, which is great for doing system and end-to-end testing.
To have a persistent database that won't get reloaded on restart or failure, edit the production style sheet style sheet (in `myapp/deploy/styles.tsx`) and put the IP address and credentials of your existing database in the `<PostgresProvider />` style rule.

If you don't have an existing database, you can create one using a service like [Cloud SQL](https://cloud.google.com/sql/docs/postgres/).

## Cleaning Up

First, destroy the app components that Adapt deployed to the GKE cluster:

<!-- doctest command -->
```bash
adapt destroy app-test
```

Then destroy the GKE cluster:

<!-- doctest command -->
```bash
gcloud container clusters delete mycluster --quiet # This will take a while
```

You can delete images pushed to the Google Container Registry in the Google Cloud Console:

Select your project's ID from the project drop down, then navigate to `Tools > Container Registry > Images` in the menu.
There you can delete all the images you don't want to keep around to save on any storage costs.

If you want, you can also delete the whole project with:

```bash
gcloud projects delete ${MYPROJECTID}
```

This should free up all resources used by the project and stop any further charges.
