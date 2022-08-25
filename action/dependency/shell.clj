#!/usr/bin/env bb

(ns dependency.shell
  (:require [clojure.java.shell :as shell]))

(defn sh
  [& args]
  (let [{:keys [exit out err]} (apply shell/sh args)]
    (if (zero? exit)
      (do
        (println out)
        out)
      (do (println "Error!")
          (println err)
          (println out)
          (System/exit 1)))))

(defn sh-surpress-fails
  [& args]
  (let [{:keys [out]} (apply shell/sh args)]
    (println out)
        out))
