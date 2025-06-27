(ns net.thewagner.training.core
  (:require [datomic.api :as d]
            [net.thewagner.training.ingest :as ingest]
            [powerpack.markdown :as md]))

(defn get-blog-posts [db]
  (->> (d/q '[:find [?e ...]
              :where
              [?e :page/kind :page.kind/blog-post]]
            db)
       (map #(d/entity db %))
       (sort-by :page/datePublished #(compare %2 %1))))

(defn layout [{:keys [title]} & content]
  [:html
   [:head
    (when title [:title title])]
   [:body
    content]
   [:hr]
   [:footer#contentinfo.body
     [:a {:rel "license" :href "http://creativecommons.org/licenses/by/4.0/"}
       [:img {:alt "Creative Commons License" :style "border-width:0" :src "https://i.creativecommons.org/l/by/4.0/88x31.png"}]]
     [:br]
     "The contents of this website is licensed under a "
     [:a {:rel "license" :href "http://creativecommons.org/licenses/by/4.0/"}
       "Creative Commons Attribution 4.0 International License"]]])

(defn render-date-abbr [date]
  [:abbr.published
    {:title (-> (java.text.SimpleDateFormat. "yyyy-MM-dd'T'HH:mm:ssZ")
                (.format date))}
    (-> (java.text.SimpleDateFormat. "E dd MMMM yyyy")
        (.format date))])

(defn render-date-time [date]
  [:time.published
    {:datetime (-> (java.text.SimpleDateFormat. "yyyy-MM-dd'T'HH:mm:ssZ")
                   (.format date))}
    (-> (java.text.SimpleDateFormat. "E dd MMMM yyyy")
        (.format date))])

(def header
  [:header#banner.body
   [:a {:href "/"} "Activities"]
   [:nav
    [:ul
     [:li [:a {:href "/pages/about/"} "About"]]
     [:li [:a {:href "/pages/events/"} "Events"]]]]])

(defn render-blog-post [context page]
  (layout {:title (:page/title page)}
    [:link {:crossorigin=""
            :integrity "sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
            :href "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
            :rel "stylesheet"}]
    [:link {:href "https://api.mapbox.com/mapbox.js/plugins/leaflet-fullscreen/v1.0.1/leaflet.fullscreen.css"
            :rel "stylesheet"}]
    header
    [:article
      [:h1.entry-title [:a {:href (:page/uri page)} (:page/title page)]]
      [:div.entry-content
        [:p.post-info
          (render-date-time (:page/datePublished page))
          [:span.vcard.author [:a {:href "#"} "David Wagner"]]]]
      (md/render-html (:page/body page))]
    [:script {:src "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
              :integrity "sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
              :crossorigin ""}]
    [:script {:src "https://api.mapbox.com/mapbox.js/plugins/leaflet-fullscreen/v1.0.1/Leaflet.fullscreen.min.js"}]
    [:script {:src "https://cdnjs.cloudflare.com/ajax/libs/leaflet-gpx/2.1.2/gpx.min.js"}]
    [:script {:src "/index.js"}]))

(defn render-frontpage [context page]
  (layout {:title "Activities"}
    header
    (md/render-html (:page/body page))
    [:table
     (for [blog-post (get-blog-posts (:app/db context))]
       [:tr
         [:td [:a {:href (:page/uri blog-post)} (or (:page/title blog-post) (:page/uri blog-post))]]
         [:td (render-date-abbr (:page/datePublished blog-post))]])]))

(defn render-page* [context page]
  (layout {:title (:page/title page)}
    header
    (md/render-html (:page/body page))))

(defn render-page [context page]
  (case (:page/kind page)
    :page.kind/blog-post (render-blog-post context page)
    :page.kind/frontpage (render-frontpage context page)
    :page.kind/page (render-page* context page)
    :page.kind/gpx {:status 200
                    :headers {"Content-Type" "application/xml"}
                    :body (:page/body page)}))

(def config
  {:site/title "Activities"
   :powerpack/content-file-suffixes ["md" "edn" "gpx"]
   :powerpack/create-ingest-tx #'ingest/create-tx
   :powerpack/log-level :debug
   :powerpack/render-page #'render-page
   :optimus/bundles {"app.css"
                     {:public-dir "public"
                      :paths ["/main.css"]}
                     "app.js"
                     {:public-dir "public"
                      :paths ["/index.js"]}}})
