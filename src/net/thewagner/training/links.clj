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

(defn resolve
  "Resolves a file path, `to-file`, relative to another file's directory,
  `from-file`. Returns the canonical path of the resolved file."
  [from href]
  (let [from-file (io/file from)
        to-file (io/file (href->file-name href))]
    (normalize (.getPath (io/file (.getParent from-file) to-file)))))

(defn post-process [context]
  (let [db (:app/db context)
        uri (:uri context)]
    {[:a] (fn [node]
            (let [href (.getAttribute node "href")
                  this-file-name (first (d/q '[:find [?file-name]
                                               :in $ ?uri
                                               :where [_ :page/uri ?uri ?tx]
                                                      [?tx :tx-source/file-name ?file-name]]
                                             db uri))
                  link-file-name (resolve this-file-name href)
                  link-uri (first (d/q '[:find [?uri]
                                         :in $ ?file-name
                                         :where [_ :page/uri ?uri ?tx]
                                                [?tx :tx-source/file-name ?file-name]]
                                       db link-file-name))]
              (.setAttribute node "href" link-uri)))}))
