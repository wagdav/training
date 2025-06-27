(ns net.thewagner.training.dev
  (:require [net.thewagner.training.core :as blog]
            [powerpack.dev :as dev]))

; 1. This is how Powerpack gets a hold of your configuration in development.
; 2. Evaluate this form to start the site
; 3. Evaluate this form to stop the site
; 4. Evaluate this form to reload all your code, rebuild the database and start the site.
; 5. Evaluate this form to grab a copy of the app instance. You can inspect it to find what configuration is being used, etc. You do not need this, it's just for the curious.))
(defmethod dev/configure! :default []
  blog/config)  ;; 1

(comment
  (dev/start)   ;; 2
  (dev/stop)    ;; 3
  (dev/reset)   ;; 4

  (def app (dev/get-app)) ;; 5


  (require '[datomic.api :as d])
  (def db (d/db (:datomic/conn app)))

  (->> (d/entity db [:page/uri "/posts/2024-06-07-A-travers-Romanel-2024/"])
       (into {}))

  (get-uris db)

  ; print schema
  (clojure.pprint/pprint
    (map #(->> % first (d/entity db) d/touch)
      (d/q '[:find ?v
             :where [_ :db.install/attribute ?v]]
         db)))

  ; print uris
  (d/q '[:find [?uri ...]
         :where [?e :page/uri ?uri]]
       db))
