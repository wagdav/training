(ns net.thewagner.training.links-test
  (:require [clojure.test :refer [deftest is testing]]
            [net.thewagner.training.links :as sut]))

(deftest links
  (testing "files in the same directory"
    (is (= (sut/resolve "posts/from.md", "/to.md")
           "posts/to.md"))
    (is (= (sut/resolve "posts/from.md", "to.md")
           "posts/to.md"))
    (is (= (sut/resolve "posts/from.md", "././to.md")
           "posts/to.md"))
    (is (= (sut/resolve "posts/sub/from.md", "../to.md")
           "posts/to.md"))))

