FROM nnichols/clojure-dependency-update-action@sha256:06c47e969b386796a09f296d80af705c1d8b578cae41ebe018b08a0f657d4081

COPY dependency-check.sh /dependency-check.sh

ENTRYPOINT ["bash", "/dependency-check.sh"]
