(ns net.thewagner.training.ingest
  (:require [clojure.string :as string]
            [clojure.instant :as instant]))

(defn get-page-kind [file-name]
  (cond
    (re-find #"^posts/" file-name)
    :page.kind/blog-post

    (re-find #"^index\.md" file-name)
    :page.kind/frontpage

    (re-find #"^pages/" file-name)
    :page.kind/page))

(defn get-publication-date [file-name]
  (when-let [date-prefix (re-find #"\d\d\d\d-\d\d-\d\d" file-name)]
    (try
      (instant/read-instant-date date-prefix)
      (catch Exception e nil))))

(defn create-tx [file-name txes]
  (let [kind (get-page-kind file-name)
        date-published (get-publication-date file-name)]
    (for [tx txes]
      (cond-> tx
        (and (:page/uri tx) kind)
        (assoc :page/kind kind)

        (and (:page/uri tx) date-published)
        (assoc :page/datePublished date-published)))))
