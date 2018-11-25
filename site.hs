{-# LANGUAGE OverloadedStrings #-}
import           Hakyll
import           System.FilePath
import           Data.List                      ( isSuffixOf )
import qualified System.Process                as Process
import           System.Exit


main :: IO ()
main = hakyllWith config $ do
    match ("CNAME" .||. "images/*" .||. "data/*") $ do
        route idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route idRoute
        compile compressCssCompiler

    match (fromList nodeModulesJs) $ do
        route assets
        compile copyFileCompiler

    match (fromList nodeModulesCss) $ do
        route assets
        compile compressCssCompiler

    match "404.md" $ do
        route $ setExtension "html"
        compile
            $   pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match (fromList ["about.md"]) $ do
        route cleanRoute
        compile
            $   pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls
            >>= cleanIndexUrls

    -- Build tags
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    match "posts/*" $ do
        route cleanRoute
        compile
            $   pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    (postCtx tags)
            >>= loadAndApplyTemplate "templates/default.html" (postCtx tags)
            >>= relativizeUrls
            >>= cleanIndexUrls


    -- Post tags
    tagsRules tags $ \tag pattern -> do
        let title = "Posts tagged " ++ tag

        -- Copied from posts, need to refactor
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll pattern
            let ctx = mconcat
                    [ constField "title" title
                    , listField "posts" (postCtx tags) (return posts)
                    , defaultContext
                    ]
            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls
                >>= cleanIndexUrls

    create ["archive.html"] $ do
        route cleanRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx = mconcat
                    [ listField "posts" (postCtx tags) (return posts)
                    , constField "title" "Archives"
                    , defaultContext
                    ]

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls
                >>= cleanIndexUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- take 10 <$> (recentFirst =<< loadAll "posts/*")
            let
                indexCtx =
                    mconcat
                        [ listField "posts" (postCtx tags) (return posts)
                        , defaultContext
                        ]

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls
                >>= cleanIndexUrls

    match "templates/*" $ compile templateBodyCompiler

    create ["data/distance.json"] $ do
        route idRoute
        compile $ do
            posts <- chronological =<< loadAll "posts/*"

            let elementCtx = mconcat
                    [ dateField "day" "%Y-%m-%d"
                    , defaultContext
                    ]

            let dataCtx = mconcat
                    [ listField "posts" elementCtx (return posts)
                    , defaultContext
                    ]

            makeItem ""
                >>= loadAndApplyTemplate "templates/data.json" dataCtx

--------------------------------------------------------------------------------
postCtx :: Tags -> Context String
postCtx tags = mconcat
    [dateField "date" "%B %e, %Y", tagsField "tags" tags, defaultContext]

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
  where
    createIndexRoute ident =
        takeDirectory p </> takeBaseName p </> "index.html"
        where p = toFilePath ident

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls cleanIndex)

cleanIndex :: String -> String
cleanIndex url | idx `isSuffixOf` url = take (length url - length idx) url
               | otherwise            = url
    where idx = "index.html"


nodeModulesJs, nodeModulesCss :: [Identifier]
nodeModulesJs =
    [ "node_modules/jquery/dist/jquery.min.js"
    , "node_modules/metrics-graphics/dist/metricsgraphics.min.js"
    , "node_modules/d3/build/d3.min.js"
    , "node_modules/leaflet/dist/leaflet.js"
    , "node_modules/@mapbox/leaflet-omnivore/leaflet-omnivore.min.js"
    ]
nodeModulesCss =
    [ "node_modules/metrics-graphics/dist/metricsgraphics.css"
    , "node_modules/leaflet/dist/leaflet.css"
    ]

assets :: Routes
assets = gsubRoute "node_modules" (const "assets")

config :: Configuration
config = defaultConfiguration { deploySite = deploy }
  where
    deploy :: Configuration -> IO ExitCode
    deploy _ = run "yarn" ["install"]
            && run "stack" ["exec", "site", "rebuild"]
            && run "ghp-import" ["_site", "-m", "Automatic update"]
            && run "git" ["push", "origin", "gh-pages"]

    run = Process.rawSystem

    (&&) :: Monad m => m ExitCode -> m ExitCode -> m ExitCode
    cmd1 && cmd2 = do
        r <- cmd1
        case r of
            ExitSuccess -> cmd2
            _           -> return r
