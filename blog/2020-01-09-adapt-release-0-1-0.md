---
title: "Announcing Adapt 0.1.0"
author: Manish Vachharajani
authorTitle: Co-founder, Unbounded Systems
authorURL: https://twitter.com/mvachhar 
authorTwitter: mvachhar 
authorImageURL: /img/profiles/manish.jpg
image: blog/assets/adapt-release-0.1.0.png
description: "Adapt 0.1.0 makes it easier than ever to deploy your apps, now with Google Kubernetes Engine (GKE) and local Docker host deployments, plus auto-push to Docker registries."
---

![Adapt 0.1.0, GKE and Docker](assets/adapt-release-0.1.0.png)

After what feels like more work than it should have been (isn't that always the way), we are excited to announce the release of [Adapt.js](https://adaptjs.org) 0.1.0.  There have been a whole raft of bug fixes and usability improvements in this release, but the 3 major new features are improved Kubernetes support, including Google Kubernetes Engine (GKE), support for making a local [Docker](https://docker.com) deployment for testing and development, and support for remote Docker registries.  We've also automated the release process which will make it easier to deliver regular releases for those of you that like to stay on the bleeding edge of development.

<!--truncate-->

## What is Adapt.js?

Adapt.js is a developer-friendly way of specifying and deploying your application back-end.  Adapt.js specifications look and feel like [React](https://reactjs.org) projects, but instead of rendering widgets in a browser, you render various artifacts, like Docker images, [Node.js](https://nodejs.org) services, [Kubernetes](https://kubernetes.io) Pods, or anything else needed to build and deploy your application back-end.  Learn more about it [here](https://adaptjs.org).

## Improved Kubernetes Support (including GKE)

Prior to this release, the Adapt cloud library had its own logic to directly authenticate against and work with the Kubernetes API.  
This included custom code to compute the differences between the props of the [`<k8s.Resource>`](https://adaptjs.org/docs/api/cloud/cloud.k8s.resource) object and what was in the cluster to decide how to update.

If you've spent any time working with Kubernetes, you know that this isn't a good idea.  First, you'll never match exactly what [`kubectl`](https://kubernetes.io/docs/reference/kubectl/overview/) will do on its own.  Besides which, even the `kubectl` logic is [broken](https://kubernetes.io/blog/2019/01/14/apiserver-dry-run-and-kubectl-diff/) which is why you really want a server-side computation that involves any custom admission controllers, which the latest versions of Kubernetes support.

The new Kubernetes implementation now uses `kubectl` instead of direct API calls.
We use it to compute the diff between your configured state of resources and what's actually running on the server to decide when to push an update.  That means that updates from Adapt happen exactly when they would if you were pushing YAML files manually to Kubernetes.

Even better, now that `kubectl` is doing all the authentication, you can easily use remote Kubernetes clusters from Google, Amazon or Azure.  We've tested deploying to [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/) and we'd love feedback on Amazon's [EKS](https://aws.amazon.com/eks/) or Azure's [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/).  Here is the [How-To guide on setting up GKE and using Adapt](https://adaptjs.org/blog/2020/01/10/simple-hosting-react-app-on-google-cloud) to deploy your first app.

If you are using Kubernetes support today, you will need to use the new [`ClusterInfo`](https://adaptjs.org/docs/api/cloud/cloud.k8s.clusterinfo) configuration object instead of a raw JavaScript object representing your `kubeconfig` like before.  [`makeClusterInfo`](https://adaptjs.org/docs/api/cloud/cloud.k8s.makeclusterinfo) is a helper function that will do just that, using the standard way that `kubectl` finds its configuration.  All our official starters have been updated to use `makeClusterInfo` for their respective Kubernetes styles.

## Local Docker Deployment

Next up is a set of Docker components and enhancements to make it easy to deploy your app locally to your laptop or workstation for development and testing.
We now have a [<`DockerContainer`>](https://adaptjs.org/docs/api/cloud/cloud.docker.dockercontainer) component that supports many of the things you'd want when you start a Docker container, including custom environment variables and connection to specialized Docker networks.

Now, the Docker library now has the same abstract interface as the Kubernetes library which means it is super easy to build a style sheet that will deploy locally with Docker for development, but on Kubernetes for test and production.  To do this, you want a style rule to replace an abstract [`<cloud.Service>`](https://adaptjs.org/docs/api/cloud/cloud.service) component with a [`<docker.ServiceContainerSet>`](https://adaptjs.org/docs/api/cloud/cloud.docker.servicecontainerset) component that will translate the abstract `<cloud.Service>` object into a local Docker deployment (`<k8s.ServiceDeployment` is the equivalent component in the Kuberntes library). The rule looks something like this.

```tsx
<Style>
  {Service} {Adapt.rule<ServiceProps>(({ handle, ...props }) =>
            <ServiceContainerSet dockerHost={process.env.DOCKER_HOST} {...props} />}
</Style>
```

All the starters have been updated to use this style rule for the default deployment style as well, so no Kubernetes required anymore for [getting started](https://adaptjs.org/docs/getting_started/) with a new project.

## Support for Remote Docker Registries

In order to support deployments where Docker containers are built locally, but deployed remotely (the common case), Adapt now has support for Docker images that are remote via the new [`<docker.RegistryDockerImage>`](https://adaptjs.org/docs/api/cloud/cloud.docker.registrydockerimage) component.  This component can represent an image that is already in a remote registry, or with the right props, push a local image, including one built with a [`<docker.LocalDockerImage>`](https://adaptjs.org/docs/api/cloud/cloud.docker.localdockerimage) component, to the specified remote registry.

But wait, there's more!  If you're using Kubernetes, the [`<k8s.ServiceDeployment>`](https://adaptjs.org/docs/api/cloud/cloud.k8s.servicedeployment) component will automatically push any local Docker images to the correct registry as specified in the new `ClusterInfo` configuration, which you can set via [`makeClusterInfo`](https://adaptjs.org/docs/api/cloud/cloud.k8s.makeclusterinfo).

## Adapt on Docker Hub

We've also started publishing our releases to Docker Hub.
So if you want to quickly and easily switch between different Adapt CLI versions, or just don't want to install Adapt directly on your system, take a look at [Adapt on Docker Hub](https://hub.docker.com/r/adaptjs/adapt) for instructions.

## `CURRENT` for Starters

If you're writing your own Adapt starter templates, it's now easier to make those starters work with different versions of Adapt.
You can now use the special version `CURRENT` in your starter's `package.json` for any `@adpt` packages.
Then, when you create a new project from your starter, `adapt new` will automatically substitute the Adapt CLI's version into `package.json`.
See the docs on [creating an Adapt starter](https://adaptjs.org/docs/user/starters/creating-starter) for more info.

## Automated Releases from `master`

Finally, we've automated our release process, so that means that we can easily cut new `next` preview releases.
If you're excited to work with the latest Adapt features, look for new `next` releases to start coming out weekly.

## What's Next

For the next release we'll be focusing on support for non-Kubernetes deployment options so that you can use a major cloud provider at zero cost until your service sees traffic.
Our first target is Amazon's [Fargate for ECS](https://aws.amazon.com/fargate/) service, which is free to set up and then only costs you for the traffic you send to your service.
That way, you can experiment with your app for minimal cost on AWS.
