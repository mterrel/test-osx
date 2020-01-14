---
title: React for Infrastructure?
author: Manish Vachharajani
authorTitle: Co-founder, Unbounded Systems
authorURL: https://twitter.com/mvachhar
authorTwitter: mvachhar
authorImageURL: /img/profiles/manish.jpg
image: blog/assets/reactplus.png
description: "What is Infrastructure as Code? A bunch of YAML files in a git repository are not code. Here is how we get real infrastructure as code with abstraction, modularity, composability, and reusability."
---

![React Plus Logos](assets/reactplus.png)

What is "Infrastructure as Code"?
If someone checks a bunch of YAML files into a Git repository, do they suddenly become code?
That seems more like "Infrastructure as Files" to me.
I suppose that's better than infrastructure as a gaggle of shell scripts and some commands run by hand in the middle of the night in a coffee-fueled haze, but it is a far cry from code.
How about a system to define infrastructure that really is like code?
<!-- truncate -->

> How about a system to define infrastructure that really is like code?

Real code -- well-written code -- uses concepts that are largely absent from today's Infrastructure as Code technologies.
These concepts are abstraction, modularity, composability, and reusability.
In code, you can import a library (reusability) and use its functionality to build your own library (composability).
Moreover, you don't need to know the implementation of the library to use it (abstraction).
You can even divide up the coding effort among different teams by agreeing on an interface (modularity).  


If we really had Infrastructure as Code, we wouldn't see every deployment system rolling its own complex deployment implementations.
But today, everyone rolls their own.
Using [AWS Fargate](https://aws.amazon.com/fargate/)? Great!
It has a [blue-green deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html) mechanism built in.
Want to use the same logic to blue-green something that isn't using Fargate?
Too bad!

With proper Infrastructure as Code, you should have an abstract, reusable, component that knows how to blue-green deploy anything that meets a certain interface.
And you should then be able to instantiate that blue-green component, and specify what you want to blue-green ([Kubernetes](https://kubernetes.io) [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod/), [AWS EC2 Instances](https://aws.amazon.com/ec2/), etc.). Just like you do in real code.

We set out to address this problem head on by creating a open source system that lets you specify your entire application architecture with reusable library components, while still making it easy to stitch together custom components when you need them. You know, just like you do with actual code.

We wanted these libraries to be modular, composable and reusable.
We wanted everyone to be able to contribute components so that you can stitch the best ones together with your own to create your own unique architecture.
And we wanted it to be easy to get started and easy to use, but still powerful enough for mission critical applications.

We call this system [Adapt](https://adaptjs.org), which is essentially [ReactJS](https://reactjs.org), but for infrastructure.

Why use a web front-end technology?
Because the requirements for a good Infrastructure as Code system look a lot like those for a good front-end framework:
- A declarative specification of what to instantiate. (React apps use a [DOM](https://en.wikipedia.org/wiki/Document_Object_Model).)
- A declarative syntax when possible. (React uses [JSX](https://reactjs.org/docs/introducing-jsx.html).)
- Imperative code to stitch together declarative snippets. (React allows JavaScript to assemble JSX snippets.)
- Specification of state-based infrastructure updates like blue-green deploy or fail-over. (React was built to make this easy.)
- Components that can encapsulate these state-based updates. ([React hooks](https://reactjs.org/docs/hooks-intro.html) let components do exactly this.)
- Components that are easy to write, easy to use, and easy to compose. (The whole point of React components.)
- A robust module system for distributing and reusing components. (React is based on JavaScript which has a rich module ecosystem.)
- A single specification that can work from development through production. (Adapt has some new technology for this one.)

Let's take a quick look at how all these things work in Adapt (or you can just [get started](https://adaptjs.org/docs/getting_started/), no React experience required).

## Adapt

All infrastructure specifications in Adapt are JavaScript programs, just like React.
(Or [TypeScript](https://www.typescriptlang.org/) programs if you prefer.)
This solves all kinds of otherwise complicated problems, like:

- How do you define a module?
- How do you version the module?
- How do you distribute the module?

Moreover, it provides all the power of a full programming language in your specifications, so you can do things like only creating infrastructure based on certain conditions, easily interacting with external APIs and services, or just about anything you can dream up.
You have the full power of JavaScript and the entire [NPM](https://npmjs.org) library.

Execution of the JavaScript program results in a virtual DOM, where each element in the final DOM represents some piece of the overall infrastructure.
For example, a basic [Node.js](https://nodejs.org) application that connects to a [Postgres](https://www.postgresql.org) database would look like this:

```tsx
function App() {
    const pg = handle();
    return <Group>
        <Postgres handle={pg}>
        <NodeService srcDir="../backend" connectTo={pg} port={8080}>
    </Group>;
}
```

Just like in React, the function `App` is a component.
Its return value is a collection of elements that represent your infrastructure, which, in this example, is at a fairly high level of abstraction.
Here, all the details of how the Node.js service is built and deployed are hidden in the `<NodeService>` component.
Same for `<Postgres>`.

This abstraction allows fairly simple, but powerful, specification of infrastructure and operational behavior.
For example, the `<NodeService>` component could be very simple, like this:

```tsx
function NodeService(props) {
    const img = handle();
    return <Group>
      <LocalNodeImage handle={img} srcDir={props.srcDir} />
      <docker.Container image={img} expose={props.port} />
    </Group>;
}
```

This component will locally build the Node.js application from source code into a local [Docker](https://www.docker.com) image (via the `<LocalNodeImage>` component) and run that image in a local container.
Here, `<docker.Container>` is a primitive element whose behavior is defined by a plugin.
This is just like how the behavior of primitive elements `<div>` or `<p>` are determined by the browser.
Because all primitive component behaviors are defined by plugins, Adapt can be extended to work with any infrastructure or application  services that your code needs.

> Because all primitive component behaviors are defined by plugins, Adapt can be extended to work with any infrastructure or application  services that your code needs.

Fortunately, there is no need to actually write a `<NodeService>` component since the Adapt cloud library provides one, but as you can see, it isn't too difficult to build a custom version if you need to.

## State and Rebuilding

If you're familiar with React, you know there is a lot more to React than just some clever HTML-like syntax to assemble a web page.
In fact, the most powerful part of React is its state model and how it handles re-rendering a web page when state changes.
Adapt has the same capability, allowing it to alter infrastructure in response to state changes, triggered by changes in the external environment, such as increased server load, a zone outage, or a push to a GitHub repository.

For example, in the simple `<NodeService>` component above, we really want to wait for the `<LocalNodeImage>` component to be ready before deploying the `<docker.Container>`.
To do this, we use some state to keep track of when the `<LocalNodeImage>` is ready, and only after it is ready, render the `<docker.Container>` element.
Just like with React, we can use the `useState` hook like this:

```tsx
function NodeService(props) {
    const img = handle();
    const [imageIsReady, setImageIsReady] = useState(false);
    setImageIsReady(() => Adapt.isReady(img));
    return <Group>
        <LocalNodeImage handle={img} srcDir={props.srcDir}>
        {
            imageIsReady ?
            <docker.Container image={img} /> :
            null
        }
    <Group>
}
```

Of course, this is such a common operation, Adapt already provides a `<Sequence>` component to do this:

```tsx
function NodeService(props) {
    const img = handle();
    return <Sequence>
        <LocalNodeImage handle={img} srcDir={props.srcDir}>
        <docker.Container image={img} />
    </Sequence>
}
```

The `<Sequence>` component even deals with the tricky case where we want the `<docker.Container>` to keep running the old container until the new one is ready, along with a few other optimizations.
The important thing here is how we can abstract away complex sequencing and roll out behavior using a component.
Moreover, `<Sequence>` can deal with roll out and updates to any components that meet some basic interface requirements.
This means that all the logic around sequenced deploys and updates are reusable.

## Observations and Updates

As Adapt evolves, you will be able to update state based on long running observations.
For example, you might be able to dynamically enable a backup availability zone if the main one has failed.

```tsx
const mainZoneAvailable = useObservation(async () => http.get(`http://myMonitoringService/myService/healthy`));
setUseBackupZone(!mainZoneAvailable);
// ... render conditionally using the mainZoneAvailable flag
```

You would also be able to build out components that encapsulate complex functionality, like blue-green deployment, by periodically updating the state that controls how much blue you have vs. green:

```tsx
const [ blueAmount, setBlueAmount ] = useState(1);
const [ greenAmount, setGreenAmount ] = useState(0);
const timeElapsed = useObservation((oldValue) => oldValue + 10, { poll: "10m", default: 0 });
const fractionGreen = min(timeElapsed, 10)/10;
setBlueAmount(1 - fractionGreen);
setGreenAmount(fractionGreen);
// ... render using blueAmount and greenAmount
```

You could even monitor data from other applications.
For example, the `<BlueGreen>` component could wait for a manual approval from a code review application before continuing to roll out more than 5% of systems with new code.

Of course, all this functionality and complexity would be available in a `<BlueGreen>` component from a library, much like `Sequence` in the example above, so you wouldn't have to implement complex features yourself.

## But wait, there's more...

We think that combining simple, composable, declarative specifications, along with the ability for deployments to dynamically react to their environment is already enough to make Adapt exciting and substantially different than other solutions.
But there are other deployment challenges that Adapt addresses too.

Adapt allows you to create a single application architecture specification, then use style sheets to deploy that architecture using different underlying components for each of your environments.
For example, in your `dev` style sheet, you can replace `<Postgres>` in the above example with a `<TestPostgres>` component that starts a Docker container and preloads some test data.
Your `prod` style sheet replaces it with a `<PostgresProvider>` component that points to a production database that is managed outside Adapt.
In a more complex application, you could even style in a custom version of Adapt's `<ReactApp>` component, which normally just deploys to a docker container, with one that builds the React application, pushes it to [S3](https://aws.amazon.com/s3) and uses [AWS cloud front](https://aws.amazon.com/cloudfront/) as a [CDN](https://en.wikipedia.org/wiki/Content_delivery_network).

> In a more complex application, you could even style in a custom version of Adapt's `<ReactApp>` component that normally just deploys to a docker container, with one that builds the React application, pushes it to S3 and uses AWS cloud front as a CDN.

Of course, Adapt also deals with all the typical issues you'd expect a deployment system to handle, like keeping track of each deployment's history and state, deployment logs, and as time goes on much more.

Our goal is to take all the difficult, repetitive, and mundane parts of deployment and make them easy...maybe even fun.
That way, you can focus on delivering your application, not managing infrastructure.

## Give it a try!

If you want to try Adapt, head over to [adaptjs.org](https://adaptjs.org).
Don't worry, you don't need to know React to get started.
There are examples and a [getting started guide](https://adaptjs.org/docs/getting_started/) that will have you up and running with your first application in under 5 minutes.
