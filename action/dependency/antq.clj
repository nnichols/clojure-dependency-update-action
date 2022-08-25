#!/usr/bin/env bb

(ns dependency.antq
  (:require [clojure.string :as str]
            [dependency.shell :as shell]))

(def latest-antq
  "{:deps {antq/antq {:mvn/version \"RELEASE\"}}}")

(defn preload!
  []
  (shell/sh "clojure"
            "-Stree"
            "-Sdeps"
            latest-antq
            "-m"
            "antq.core"))

(def antq-report-format
  "--error-format={{name}},{{version}},{{latest-version}},{{diff-url}}")

(def antq-reporter
  "--reporter=format")

(defn find-upgrades!
  []
  (shell/sh-surpress-fails "clojure"
            "-Sdeps"
            latest-antq
            "-m"
            "antq.core"
            antq-reporter
            antq-report-format))

(defn ->upgrade
  [upgrade]
  (let [[library old-version new-version diff] (str/split upgrade #",")]
    {:library     library
     :old-version old-version
     :new-version new-version
     :diff        diff}))

(defn parse-upgrades
  [upgrades]
  (let [split-upgrades (str/split-lines upgrades)]
    (->> split-upgrades
         (remove #(str/includes? % "Timed out"))
         (remove #(str/blank? %))
         (map ->upgrade))))

(defn upgrade-single-library!
  [directories {:keys [library old-version new-version diff]}]
  (println (format "Upgrading %s from %s to %s" library old-version new-version))
  (println (format "Inspect the diff here: %s" diff))
  (shell/sh "clojure"
            "-Sdeps"
            latest-antq
            "-m"
            "antq.core"
            "--upgrade"
            "--force"
            (str "--focus=" library)))


