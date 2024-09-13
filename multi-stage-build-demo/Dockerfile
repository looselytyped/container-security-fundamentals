# ——— Build/Test image ——————————————————————————————————————————————————————
# Name the builder image "as builder"
FROM amazoncorretto:19-alpine3.17 as code-builder

WORKDIR /code
COPY *.gradle gradle.* gradlew ./
COPY gradle ./gradle
RUN ./gradlew build || return 0

COPY app/ app/

# Alternatively ...
# RUN ./gradlew resolveDependencies
RUN ["./gradlew", "-q", "--no-daemon", "jar"]

# ——— Build JRE ————————————————————————————————————————————————
# From https://jaehong21.com/posts/java/java-jdeps-jlink/
FROM amazoncorretto:19-alpine3.17 as jre-builder

# needed for jlink
RUN apk add --no-cache binutils

COPY --from=code-builder /code/app/build/libs/app.jar /app.jar

# Dependency analysis
RUN $JAVA_HOME/bin/jdeps \
  --ignore-missing-deps \
  --print-module-deps \
  -q --recursive \
  --multi-release 17 \
  /app.jar > /deps.info

# Build small JRE image
RUN $JAVA_HOME/bin/jlink \
  --verbose \
  --add-modules $(cat /deps.info) \
  --strip-debug \
  --no-man-pages --no-header-files \
  --compress=2 \
  --output /customjre

# ——— Final production image ————————————————————————————————————————————————
FROM alpine:3.17

ENV JAVA_HOME=/jre
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# copy JRE from the base image
COPY --from=jre-builder /customjre $JAVA_HOME

# Add app user
ARG APPLICATION_USER=app
RUN adduser --no-create-home -u 1000 -D ${APPLICATION_USER}
USER 1000

# Configure working directory
WORKDIR /app

COPY --chown=1000:1000 --from=code-builder /code/app/build/libs/app.jar app.jar

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["entrypoint.sh"]
CMD ["default"]
