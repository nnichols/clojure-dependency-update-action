FROM nnichols/clojure-dependency-update-action

COPY dependency-check.sh /dependency-check.sh

ENTRYPOINT ["bash", "/dependency-check.sh"]
