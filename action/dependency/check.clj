#!/usr/bin/env bb

(ns dependency.check
  (:require [clojure.java.shell :as shell]
            [clojure.string :as str]
            [clojure.tools.cli :as cli]
            [dependency.antq :as antq]
            [dependency.git :as git]
            [dependency.shell :as sh]))

(defn branch-date!
  []
  (-> (sh/sh "date" "+%Y-%m-%d-%H-%M-%S")
      str/split-lines
      first))

(defn batch-upgrade-deps!
  [{:keys [branch] :as opts} upgrades]
  (let [new-branch (str git/new-branch-stem (branch-date!))]
    (git/create-or-checkout! new-branch)
    (doseq [{:keys [library] :as upgrade} upgrades]
        (println (str "::group::" library))
        (antq/upgrade-single-library! [] upgrade)
        (git/add!)
        (git/commit! upgrade)
        (println "::endgroup::"))
    (git/push! opts new-branch)
    (git/submit-pull-request! new-branch branch)
    (git/checkout! branch)))

(defn upgrade-deps!
  [{:keys [branch] :as opts} upgrades]
  (for [{:keys [library new-version] :as upgrade} upgrades]
    (let [new-branch (str git/new-branch-stem library "-" new-version)]
      (println (str "::group::" library))
      (git/create-or-checkout! new-branch)
      (antq/upgrade-single-library! [] upgrade)
      (git/add!)
      (git/commit! upgrade)
      (git/push! opts new-branch)
      (git/submit-pull-request! new-branch branch)
      (git/checkout! branch)
      (println "::endgroup::"))))

(defn main*
  [{:keys [github-token batch]
    :as   opts}]
  (antq/preload!)
  #_(shell/with-sh-env {:github-token github-token}
    (git/configure! opts))
  (let [upgrades (antq/parse-upgrades (antq/find-upgrades!))]
    (if (seq upgrades)
      (do (println (str "Processing " (count upgrades) " upgrade(s)"))
          (if batch
            (batch-upgrade-deps! opts upgrades)
            (upgrade-deps! opts upgrades))
          (println (str "Upgrades completed. Exiting"))
          (System/exit 0))
      (do (println "No upgrades detected. Exiting")
          (System/exit 0)))))

(def cli-options
  [["-e" "--git-email EMAIL" "The email address used to create the version commit with"
    :default "41898282+github-actions[bot]@users.noreply.github.com"
    :validate [#(not (str/blank? %)) "Email cannot be an empty string"]]
   ["-u" "--git-username USER" "The name to use for the version commit. e.g. github.actor"
    :default "github-actions[bot]"
    :validate [#(not (str/blank? %)) "Username cannot be an empty string"]]
   ["-t" "--github-token TOKEN" "A GitHub auth token to be able to create the pull request"
    :validate [#(not (str/blank? %)) "GitHub Token cannot be an empty string"]]
   ["-b" "--branch BRANCH" "The git branch that will act as the target of the pull request"
    :default "master"
    :validate [#(not (str/blank? %)) "GitHub Branch cannot be an empty string"]]
   ["-x" "--excludes EXCLUDES" "A list of space-delimited artifact names to skip over"
    :default []
    :parse-fn #(str/split % #" ")]
   ["-d" "--directories DIRECTORIES" "A list of space-delimited directories to search over"
    :default "."
    :parse-fn #(str/split % #" ")]
   ["-s" "--skips SKIPS" "A list of space-delimited project types to skip"
    :default "github-action"
    :parse-fn #(str/split % #" ")]
   [nil "--batch" "Updates all outdated dependencies in a single pull request."]
   ["-r" "--github-repository REPOSITORY" "The name of the GitHub Repository to update"
    :validate [#(not (str/blank? %)) "GitHub Repository cannot be an empty string"]]])

(defn -main
  [& args]
  (let [{:keys [options errors]} (cli/parse-opts *command-line-args* cli-options)]
    (if (seq errors)
      (do (println "Errors detected! Aborting")
          (println errors)
          (System/exit 1))
      (do (println "Configuration verified. Proceeding")
          (main* options)
          (System/exit 0)))))

(-main)
