(ns net.thewagner.training.core
  (:require [powerpack.markdown :as md]))

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

(defn render-page [context page]
  (layout {:title "Activities"}
    header
    (md/render-html (:page/body page))))

(def config
  {:site/title "Training"
   :powerpack/render-page #'render-page
   :optimus/bundles {"app.css"
                     {:public-dir "public"
                      :paths ["/main.css"]}}})

