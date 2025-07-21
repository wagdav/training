(ns net.thewagner.training.links
  (:require [clojure.java.io :as io]
            [datomic.api :as d]))

(defn- href->file-name
  "Recover a filename from a naively linked anchor"
  [href]
  (->> (java.net.URI. href)
       (.relativize (java.net.URI. "/"))
       .toString))

(defn- normalize [path]
  (.toString (.normalize (java.net.URI. path))))

(defn external-link? [href]
  (#{"http" "https"} (.getScheme (java.net.URI. href))))

(defn resolve
  "Resolves a file path, `to-file`, relative to another file's directory,
  `from-file`. Returns the canonical path of the resolved file."
  [from href]
  (let [from-file (io/file from)
        to-file (io/file (href->file-name href))]
    (normalize (.getPath (io/file (.getParent from-file) to-file)))))

(def get-file-name-by-uri
  '[:find ?file-name .
    :in $ ?uri
    :where [_ :page/uri ?uri ?tx]
           [?tx :tx-source/file-name ?file-name]])

(def get-uri-by-file-name
  '[:find ?uri .
    :in $ ?file-name
    :where [_ :page/uri ?uri ?tx]
           [?tx :tx-source/file-name ?file-name]])

(defn post-process [context]
  (let [db (:app/db context)
        uri (:uri context)]
    {[:a] (fn [node]
            (let [href (.getAttribute node "href")]
              (when-not (external-link? href) ; leave external links alone
                (let [this-file-name (d/q get-file-name-by-uri db uri)
                      link-file-name (resolve this-file-name href)
                      link-uri (d/q get-uri-by-file-name db link-file-name)]
                  (when (and link-file-name link-uri)
                    (.setAttribute node "href" link-uri))))))}))
