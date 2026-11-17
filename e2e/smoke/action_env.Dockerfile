FROM python:3.11.17-bookworm AS build
RUN echo "$NO_PROXY" > /no_proxy.txt

FROM scratch
COPY --from=build /no_proxy.txt /
