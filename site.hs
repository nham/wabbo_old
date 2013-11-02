--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend, mconcat)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "about.markdown" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    (postCtx tags)
            >>= loadAndApplyTemplate "templates/default.html" (postCtx tags)
            >>= relativizeUrls
    

    match "index.html" $ do                                                         
        route idRoute                                                               
        compile $ do                                                                
            posts <- recentFirst =<< loadAll "posts/*"                              
            let indexCtx =                                                          
                    listField "posts" (postCtx tags) (return posts) `mappend`
                    constField "title" "Posts"               `mappend`
                    defaultContext                                                  
                                                                                    
            getResourceBody                                                         
                >>= applyAsTemplate indexCtx                                        
                >>= loadAndApplyTemplate "templates/default.html" indexCtx          
                >>= relativizeUrls



    tagsRules tags $ \tag pattern -> do
        let title = "Posts tagged " ++ tag

        route idRoute
        compile $ do                                                                
            posts <- recentFirst =<< loadAll pattern
            let ctx =                                                          
                    listField "posts" (postCtx tags) (return posts) `mappend`
                    constField "title" title               `mappend`
                    defaultContext                                                  
                                                                                    
            makeItem ""                                                         
                >>= loadAndApplyTemplate "templates/post-list.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx          
                >>= relativizeUrls


    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Tags -> Context String
postCtx tags = mconcat
    [ dateField "date" "%B %e, %Y"
    , tagsField "tags" tags
    , defaultContext
    ]
