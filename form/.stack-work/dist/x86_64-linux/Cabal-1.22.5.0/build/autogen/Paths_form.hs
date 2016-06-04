module Paths_form (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
catchIO = Exception.catch

version :: Version
version = Version [0,0,0] []
bindir, libdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/home/ubuntu/workspace/form/.stack-work/install/x86_64-linux/lts-5.15/7.10.3/bin"
libdir     = "/home/ubuntu/workspace/form/.stack-work/install/x86_64-linux/lts-5.15/7.10.3/lib/x86_64-linux-ghc-7.10.3/form-0.0.0-GN0M9h8gTo57lvrP5BRePp"
datadir    = "/home/ubuntu/workspace/form/.stack-work/install/x86_64-linux/lts-5.15/7.10.3/share/x86_64-linux-ghc-7.10.3/form-0.0.0"
libexecdir = "/home/ubuntu/workspace/form/.stack-work/install/x86_64-linux/lts-5.15/7.10.3/libexec"
sysconfdir = "/home/ubuntu/workspace/form/.stack-work/install/x86_64-linux/lts-5.15/7.10.3/etc"

getBinDir, getLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "form_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "form_libdir") (\_ -> return libdir)
getDataDir = catchIO (getEnv "form_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "form_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "form_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
