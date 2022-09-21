### WARNING: This is the first version of Stellar Invictus when it was text-based. The new & current Stellar Invictus is a private repository.

<div align="center">
  <br>
  <img
    alt="Logo"
    src="https://s3-eu-west-1.amazonaws.com/static.stellar-invictus.com/assets/logos/stellar_side_black.png"
    width=500px
  />
  <h1>Stellar Invictus</h1>
  <strong>A Sandbox Game Right In Your Browser</strong>
</div>
<br/>
Welcome to the [stellar-invictus.com](https://stellar-invictus.com) codebase. We are so excited to have you. With your help, we can build out Stellar Invictus to be more stable and better serve our community.

## What is Stellar Invictus?

Stellar Invictus is a sandbox browsergame to be played right in the browser where players fly spaceships, fight each other and trade. The game offers many ways to explore its universe.

## Contributing

We encourage you to contribute to stellar-invictus!

We expect contributors to abide by our underlying [code of conduct](CODE_OF_CONDUCT.md). All conversations and discussions on GitHub (issues, pull requests) must be respectful and harassment-free.

We also have a [slack](https://join.slack.com/t/stellarinvictus/shared_invite/enQtNjAwMzczMjUzMTI1LWQ4NjljMWFhYjhmYWFlZDhjYjJiMDgxYmYwODA1YTIwZTA2YmE3MzA1NzI3MmVhZjRlOGJhN2Y1ZjhkYTRiYWY) for developers!

### How to contribute

1.  Fork the project & clone locally. Follow the initial setup [here](#getting-started).
2.  Create a branch, naming it either a feature or bug: `git checkout -b feature/that-new-feature` or `bug/fixing-that-bug`
3.  Code and commit your changes. Bonus points if you write a [good commit message](https://chris.beams.io/posts/git-commit/): `git commit -m 'Add some feature'`
4.  Push to the branch: `git push origin feature/that-new-feature`
5.  [Create a pull request](#create-a-pull-request) for your branch 🎉

## Contribution guideline

### Create an issue

Nobody's perfect. Something doesn't work? Or could be done better? Let us know by creating an issue.

PS: a clear and detailed issue gets lots of love, all you have to do is follow the issue template!

#### Clean code with tests

Some existing code may be poorly written or untested, so we must have more scrutiny going forward. We test with [rspec](http://rspec.info/), let us know if you have any questions about this!

#### Create a pull request

- Try to keep the pull requests small. A pull request should try its very best to address only a single concern.
- Make sure all tests pass and add additional tests for the code you submit.
- Document your reasoning behind the changes. Explain why you wrote the code in the way you did. The code should explain what it does.
- If there's an existing issue related to the pull request, reference to it by adding something like `References/Closes/Fixes/Resolves #305`, where 305 is the issue number. [More info here](https://github.com/blog/1506-closing-issues-via-pull-requests)
- If you follow the pull request template, you can't go wrong.

_Please note: all commits in a pull request will be squashed when merged, but when your PR is approved and passes our CI, it will be live on production!_

### The bottom line

We are all humans trying to work together to improve the community. Always be kind and appreciate the need for tradeoffs. ❤️

## Codebase

### The stack

We run on a Rails backend with mostly JQuery JavaScript on the front end ( like, a lot of JQuery ).

## Getting Started

This section provides a high-level requirement & quick start guide.

### Prerequisites

- [Ruby](https://www.ruby-lang.org/en/): we recommend using [rbenv](https://github.com/rbenv/rbenv) to install the Ruby version listed under .ruby-version.
- [PostgreSQL](https://www.postgresql.org/) 9.4 or higher.

### Docker Installation

1. Install `docker` and `docker-compose`
1. `git clone the project`
1. `cp .env.sample .env` and set environment variables
1. run `docker-compose build`
1. run `docker-compose run --entrypoint "/bin/sh -c 'rails db:setup'" app`
1. run `docker-compose up`
1. That's it! Navigate to `localhost:3000`

## Core team

- [@venarius](https://github.com/venarius)

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. Please see the [LICENSE](./LICENSE.md) file in our repository for the full text.

Like many open source projects, we require that contributors provide us with a Contributor License Agreement (CLA). By submitting code to the project, you are granting us a right to use that code under the terms of the CLA.

Our version of the CLA was adapted from the Microsoft Contributor License Agreement, which they generously made available to the public domain under Creative Commons CC0 1.0 Universal.

<br/>

<p align="center">
  <strong>Happy Coding</strong>
</p>
