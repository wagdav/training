(ns net.thewagner.training.core
  (:require [datomic.api :as d]
            [net.thewagner.training.ingest :as ingest]
            [powerpack.markdown :as md]
            [clojure.string :as string]))

(defn get-blog-posts [db]
  (->> (d/q '[:find [?e ...]
              :where
              [?e :page/kind :page.kind/blog-post]]
            db)
       (map #(d/entity db %))))

(defn layout [{:keys [title]} & content]
  [:html
   [:head
    (when title [:title title])]
   [:body
    content]])

(def header
  [:header#banner.body
   [:a {:href "/"} "Activities"]
   [:nav
    [:ul
     [:li [:a {:href "/pages/about/"} "About"]]
     [:li [:a {:href "/pages/events/"} "Events"]]]]])

(defn render-blog-post [context page]
  (layout {:title "Blog post title"}
    header
    (md/render-html (:page/body page))))

(defn render-frontpage [context page]
  (layout {:title "Activities"}
    header
    (md/render-html (:page/body page))
    [:ul
     (for [blog-post (get-blog-posts (:app/db context))]
       [:li [:a {:href (:page/uri blog-post)} (:page/uri blog-post)]])]))

(defn render-page* [context page]
  (layout {:title "Page title"}
    header
    (md/render-html (:page/body page))))

(defn render-page [context page]
  (case (:page/kind page)
    (:page.kind/blog-post (render-blog-post context page))
    (:page.kind/frontpage (render-frontpage context page))
    (:page.kind/page (render-page* context page))))

(def config
  {:site/title "Training"
   :powerpack/render-page #'render-page
   :powerpack/create-ingest-tx #'ingest/create-tx
   :powerpack/log-level :debug
   :optimus/bundles {"app.css"
                     {:public-dir "public"
                      :paths ["/main.css"]}}})
