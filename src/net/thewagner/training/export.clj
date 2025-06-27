(ns net.thewagner.training.export
  (:require [net.thewagner.training.core :as blog]
            [powerpack.export :as export]))

(defn ^:export export! [& args]
  (-> blog/config
      (assoc :site/base-url "https://training.thewagner.net")
      export/export!))
