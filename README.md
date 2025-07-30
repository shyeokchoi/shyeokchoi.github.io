[Minimal Mistakes Jekyll theme](https://mmistakes.github.io/minimal-mistakes/)

# Running This Blog Locally

## Option 1: Using Docker (Recommended)

### Prerequisites

- Docker installed on your system

### Run the Blog with Docker

```bash
# Build the Docker image
docker build -t jekyll-blog .

# Run the container
docker run -p 4000:4000 -v $(pwd):/app jekyll-blog
```

The blog will be available at `http://localhost:4000`

## Option 2: Local Installation

### Prerequisites

Jekyll Installation

For first-time setup:

```bash
bundle install
```

### Run the Blog Locally

```bash
bundle exec jekyll serve
```
