# The conformance example app (shelf). Build it with the package folder as
# the context:
#   docker build -f example/Dockerfile .
FROM dart:stable AS build
WORKDIR /pkg
# The package from this repo's own source, not from pub.dev.
COPY pubspec.yaml ./
RUN dart pub get
COPY lib/ lib/
COPY example/ example/
RUN dart pub get --offline && dart compile exe example/conformance.dart -o /server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server /app/server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/server"]
