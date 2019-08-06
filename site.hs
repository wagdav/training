{-# LANGUAGE OverloadedStrings #-}

import Hakyll

import Control.Exception
import Control.Monad (filterM)
import Data.List (isSuffixOf)
import System.Exit
import System.FilePath
import qualified System.Process as Process

import Data.Time
import Data.Time.Calendar
import Data.Time.Calendar.WeekDate
import Data.Time.Format (defaultTimeLocale)

main :: IO ()
main =
  hakyllWith config $ do
    match ("CNAME" .||. "images/*" .||. "images/rdga/*" .||. "data/*") $ do
      route idRoute
      compile copyFileCompiler
    match "css/*" $ do
      route idRoute
      compile compressCssCompiler
    match (fromList nodeModulesJs .||. fromList nodeModulesImages) $ do
      route assets
      compile copyFileCompiler
    match (fromList nodeModulesCss) $ do
      route assets
      compile compressCssCompiler
    match "404.md" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler >>=
        loadAndApplyTemplate "templates/default.html" defaultContext >>=
        relativizeUrls
    match (fromList ["about.md", "events.md"]) $ do
      route cleanRoute
      compile $
        pandocCompiler >>=
        loadAndApplyTemplate "templates/default.html" defaultContext >>=
        relativizeUrls >>=
        cleanIndexUrls
    -- Build tags
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")
    match "posts/*" $ do
      route cleanRoute
      compile $
        pandocCompiler >>=
        loadAndApplyTemplate "templates/post.html" (postCtx tags) >>=
        loadAndApplyTemplate "templates/default.html" (postCtx tags) >>=
        relativizeUrls >>=
        cleanIndexUrls
    -- Post tags
    tagsRules tags $ \tag pattern -> do
      let title = "Posts tagged " ++ tag
        -- Copied from posts, need to refactor
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll pattern
        let ctx =
              mconcat
                [ constField "title" title
                , listField "posts" (postCtx tags) (return posts)
                , defaultContext
                ]
        makeItem "" >>= loadAndApplyTemplate "templates/archive.html" ctx >>=
          loadAndApplyTemplate "templates/default.html" ctx >>=
          relativizeUrls >>=
          cleanIndexUrls
    create ["archive.html"] $ do
      route cleanRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let archiveCtx =
              mconcat
                [ listField "posts" (postCtx tags) (return posts)
                , constField "title" "Archives"
                , defaultContext
                ]
        makeItem "" >>= loadAndApplyTemplate "templates/archive.html" archiveCtx >>=
          loadAndApplyTemplate "templates/default.html" archiveCtx >>=
          relativizeUrls >>=
          cleanIndexUrls
    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- take 10 <$> (recentFirst =<< loadAll "posts/*")
        let indexCtx =
              mconcat
                [ listField "posts" (postCtx tags) (return posts)
                , defaultContext
                ]
        getResourceBody >>= applyAsTemplate indexCtx >>=
          loadAndApplyTemplate "templates/default.html" indexCtx >>=
          relativizeUrls >>=
          cleanIndexUrls
    match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
postCtx :: Tags -> Context String
postCtx tags =
  mconcat [dateField "date" "%B %e, %Y", tagsField "tags" tags, defaultContext]

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
      where
        p = toFilePath ident

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls cleanIndex)

cleanIndex :: String -> String
cleanIndex url
  | idx `isSuffixOf` url = take (length url - length idx) url
  | otherwise = url
  where
    idx = "index.html"

nodeModulesJs, nodeModulesCss, nodeModulesImages :: [Identifier]
nodeModulesJs =
  [ "node_modules/leaflet/dist/leaflet.js"
  , "node_modules/leaflet-fullscreen/dist/Leaflet.fullscreen.min.js"
  , "node_modules/@mapbox/leaflet-omnivore/leaflet-omnivore.min.js"
  ]

nodeModulesCss =
  [ "node_modules/metrics-graphics/dist/metricsgraphics.css"
  , "node_modules/leaflet/dist/leaflet.css"
  , "node_modules/leaflet-fullscreen/dist/leaflet.fullscreen.css"
  ]

nodeModulesImages = ["node_modules/leaflet-fullscreen/dist/fullscreen.png"]

assets :: Routes
assets = gsubRoute "node_modules" (const "assets")

config :: Configuration
config = defaultConfiguration {deploySite = deploy}
  where
    deploy :: Configuration -> IO ExitCode
    deploy _ = do
      e <-
        try $ do
          run "yarn" ["install"]
          run "stack" ["exec", "site", "rebuild"]
          run "ghp-import" ["_site", "-m", "Automatic update"]
          run "git" ["push", "origin", "gh-pages"]
      case e of
        Right () -> return ExitSuccess
        Left (SomeException error) -> do
          putStrLn $ "OUPS, something went wrong:"
          putStrLn $ show error
          return $ ExitFailure 1
    run = Process.callProcess
