ARG MELTANO_IMAGE=meltano/meltano:latest
FROM $MELTANO_IMAGE

WORKDIR /project

# Set db environment variable
# ENV MELTANO_DATABASE_URI=postgresql://<user>:<password>@<host>:<port>/<db>

# Install any additional requirements
COPY ./requirements.txt . 
RUN pip install -r requirements.txt

# Install all plugins into the `.meltano` directory
COPY ./meltano.yml . 
COPY ./tap-smoke-test ./tap-smoke-test
RUN meltano install

# Pin `discovery.yml` manifest by copying cached version to project root
RUN cp -n .meltano/cache/discovery.yml . 2>/dev/null || :

# Don't allow changes to containerized project files
ENV MELTANO_PROJECT_READONLY 1


# Set environment variables for frontend
ENV MELTANO_UI_SESSION_COOKIE_SECURE=true
ENV MELTANO_UI_FORWARDED_ALLOW_IPS="*"
ENV FORWARDED_ALLOW_IPS="*"

# Copy over remaining project files
COPY . .

# Expose default port used by `meltano ui`
EXPOSE 5000

# Smoke test
RUN mkdir output
RUN meltano elt tap-smoke-test target-jsonl

ENTRYPOINT ["meltano"]
