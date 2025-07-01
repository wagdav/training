(ns net.thewagner.training.ingest)

(defn get-page-kind [file-name]
  (cond
    (re-find #"^posts/" file-name)
    :page.kind/blog-post

    (re-find #"^index\.md" file-name)
    :page.kind/frontpage

    (re-find #"^pages/" file-name)
    :page.kind/page))

(defn create-tx [file-name txes]
  (let [kind (get-page-kind file-name)]
    (for [tx txes]
      (cond-> tx
        (and (:page/uri tx) kind)
        (assoc :page/kind kind)))))

