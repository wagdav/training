(ns net.thewagner.training.ingest-test
  (:require [clojure.test :refer [deftest is testing]]
            [net.thewagner.training.ingest :as sut]))

(deftest filename-parse-test
  (testing "Parses date from filename"
    (is (= (sut/get-publication-date "posts/2025-07-07-Some-Title.md")
           #inst "2025-07-07")))

  (testing "Returns if file-name doesn't contain a date"
    (is (nil? (sut/get-publication-date "about.md"))))

  (testing "Returns slug from page title post URI"
    (is (= (sut/get-uri "posts/2025-05-19-Toscana-Gravel.md" "Toscana Gravel 2025")
           "/blog/2025/05/19/toscana-gravel-2025/")))

  (testing "Returns slug from page title"
    (is (= (sut/get-uri "posts/2024-06-17-Ardeche.md" "Ardèche Tour 2024")
           "/blog/2024/06/17/ardeche-tour-2024/")))

  (testing "Returns nil for pages"
    (is (nil? (sut/get-uri "posts/about.md" "About")))))
