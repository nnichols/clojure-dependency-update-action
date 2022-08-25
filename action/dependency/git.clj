#!/usr/bin/env bb

(ns dependency.git
  (:require [dependency.shell :as shell]))

(def new-branch-stem "dependencies/clojure/")

(defn set-user-email!
  [email]
  (shell/sh "git" "config" "--global" "user.email" email))

(defn set-user-name!
  [username]
  (shell/sh "git" "config" "--global" "user.name" username))

(defn ->bump-message
  [{:keys [library old-version new-version]}]
  (format "Bumped %s from %s to %s" library old-version new-version))

(defn ->diff-message
  [{:keys [diff]}]
  (format "Inspect dependency changes here: %s" diff))

(defn add!
  []
  (shell/sh "git" "add" "."))

(defn commit!
  [{:keys [library old-version new-version diff] :as change}]
  (shell/sh "git" "commit" "-m" (->bump-message change) "-m" (->diff-message change)))

(defn ->authed-url
  [git-username github-token github-repository]
  (format "https://%s:%s@github.com/%s.git" git-username github-token github-repository))

(defn push!
  [{:keys [git-username github-token github-repository branch]}]
  (shell/sh "git" "push" "-u" (->authed-url git-username github-token github-repository) branch))

(defn submit-pull-request!
  [branch-name base-branch]
  (println (str "Submitting a pull request against branch: " base-branch))
  (shell/sh "gh" "pr" "create" "--fill" "--head" branch-name "--base" base-branch))

(defn checkout!
  [branch]
  (println (str "Checking out branch: " branch))
  (shell/sh "git" "checkout" branch))

(defn create-or-checkout!
  [branch]
  (println (str "Checking out branch: " branch))
  (shell/sh "sh" "-c" (str "git checkout " branch " || git checkout -b " branch)))

(defn configure!
  [{:keys [git-email git-username branch]}]
  (println "::group::git-configuration")
  (set-user-email! git-email)
  (set-user-name! git-username)
  (checkout! branch)
  (println "::endgroup::"))
