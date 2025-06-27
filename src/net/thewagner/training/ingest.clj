(ns net.thewagner.training.ingest
  (:require [clojure.string :as string]
            [clojure.instant :as instant]
            [powerpack.ingest :as ingest])
  (:import [java.text Normalizer Normalizer$Form]))

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

(defn normalize-string [s]
  (-> s
      (Normalizer/normalize Normalizer$Form/NFD)
      (.replaceAll "[^\\p{ASCII}]" "")))

(defn get-slug [title]
  (-> title
      normalize-string
      (string/lower-case)
      (string/replace " " "-")))

(defn get-uri [file-name title]
  (when-let [date-prefix (re-find #"\d\d\d\d-\d\d-\d\d" file-name)]
    (str
      "/blog/"
      (string/replace date-prefix "-" "/")
      "/"
      (get-slug title)
      "/")))

(defn create-tx [file-name txes]
  (let [kind (get-page-kind file-name)
        date-published (get-publication-date file-name)]
    (for [tx txes]
      (cond-> (dissoc tx :page/tags :page/distance :page/trace :page/elevation_gain :page/time)
        (and (not (:page/kind tx)) (:page/uri tx) kind)
        (assoc :page/kind kind)

        (and (:page/uri tx) date-published)
        (assoc :page/datePublished date-published)

        (:page/title tx)
        (assoc :page/uri (get-uri file-name (:page/title tx)))))))


(defmethod ingest/parse-file :gpx [db file-name file]
  [{:page/uri (str "/" file-name)
    :page/body (slurp file)
    :page/kind :page.kind/gpx}])

(comment
  (doseq [file (file-seq (clojure.java.io/file "./content/posts"))]
    (when (.isFile file)
      (let [[header body] (string/split (slurp file) #"\R\R" 2)
            ts (->> (string/split-lines header)
                    (remove #(= % "---")))
            ts' (for [t ts
                      :let [[_ k v] (re-find #"([a-z_]*): (.*)" t)]]
                  (str ":page/" k " " v))]
        (spit file (string/join "\n" (concat ts' [:page/body ""] [body])))))))
