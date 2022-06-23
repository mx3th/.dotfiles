-- Main
import XMonad
import System.IO (hPutStrLn)
import System.Exit
import qualified XMonad.StackSet as W

-- Actions
import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.MouseResize
import XMonad.Actions.WithAll (sinkAll, killAll)
import XMonad.Actions.CopyWindow (kill1, wsContainingCopies, copyToAll, killAllOtherCopies)
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)

-- Data
import Data.Semigroup
import Data.Monoid
import Data.Maybe (fromJust, isJust)
import qualified Data.Map as M

-- Hooks
import XMonad.Hooks.DynamicProperty
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, isDialog, doCenterFloat, doRectFloat)
import XMonad.Hooks.WindowSwallowing

-- Layouts
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.ResizableTile
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowNavigation
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

-- Utilities
import XMonad.Util.Dmenu
import XMonad.Util.EZConfig(additionalKeysP)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Scratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import Graphics.X11.ExtraTypes.XF86

------------------------------------------------------------------------
-- My Strings
------------------------------------------------------------------------
myTerminal :: String
myTerminal = "kitty"          -- Default terminal

myModMask :: KeyMask
myModMask = mod4Mask          -- Super Key (--mod4Mask= super key --mod1Mask= alt key --controlMask= ctrl key --shiftMask= shift key)

myBorderWidth :: Dimension
myBorderWidth = 0             -- Window border

------------------------------------------------------------------------
-- Space between Tiling Windows
------------------------------------------------------------------------
mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border 30 10 10 10) True (Border 10 10 10 10) True

------------------------------------------------------------------------
-- Layout Hook
------------------------------------------------------------------------
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts full
               $ mkToggle (NBFULL ?? NOBORDERS ?? MIRROR ?? EOT) myDefaultLayout
             where
               myDefaultLayout =      withBorder myBorderWidth tall
                                  ||| full
                                  ||| grid
                                  ||| mirror

------------------------------------------------------------------------
-- Tiling Layouts
------------------------------------------------------------------------
tall     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Tall</fc>"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 8
           $ mySpacing 5
           $ ResizableTall 1 (3/100) (1/2) []               
grid     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Grid</fc>"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 12
           $ mySpacing 5
           $ mkToggle (single MIRROR)
           $ Grid (16/10)   
mirror     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Mirror</fc>"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 6
           $ mySpacing 5
           $ Mirror  
           $ ResizableTall 1 (3/100) (1/2) []            
full     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Full</fc>"]
           $ Full                     

------------------------------------------------------------------------
-- Workspaces
------------------------------------------------------------------------

myWorkspaces :: [String]
myWorkspaces = ["\xf8a3", "\xf8a6", "\xf8a9", "\xf8ac", "\xf8af", "\xf8b2", "\xf8b5", "\xf8b8"]

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

------------------------------------------------------------------------
-- Scratch Pads
------------------------------------------------------------------------
myScratchPads :: [NamedScratchpad]
myScratchPads =
  [
      NS "discord"              "discord"              (appName =? "discord")                   (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "nautilus"             "nautilus"             (className =? "Org.gnome.Nautilus")      (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "thunar"               "thunar"               (className =? "Thunar")      		    (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "spotify"              "spotify"              (appName =? "spotify")                   (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "whatsapp-for-linux"   "whatsapp-for-linux"   (appName =? "whatsapp-for-linux")        (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "ranger"               launchRang             (title =? "rangersp")                    (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
  ]
  where
    launchRang = myTerminal ++ " -T rangersp -e ranger"

------------------------------------------------------------------------
-- Custom Keys
------------------------------------------------------------------------
myKeys :: [(String, X ())]
myKeys =

    [
    -- Xmonad
        ("M-C-r", spawn "xmonad --recompile && xmonad --restart")                   -- Recompile & Restarts xmonad
      , ("M-C-q", io exitSuccess)                                                   -- Quits xmonad
      , ("M-C-p", spawn "/home/mx3/.config/xmonad/scripts/lock.sh")                 -- Lock screen

    -- System
      , ("<XF86AudioMute>",         spawn "pamixer -t") 			                -- Mute
      , ("<XF86AudioRaiseVolume>",  spawn "pamixer -i 5")  			                -- Volume Up
      , ("<XF86AudioLowerVolume>",  spawn "pamixer -d 5")  			                -- Volume Down
      , ("<XF86AudioPlay>",         spawn "playerctl play-pause")                   -- playerctl play/pause
      , ("<XF86AudioStop>",         spawn "playerctl stop")                         -- playerctl stop
      , ("<XF86AudioPrev>",         spawn "playerctl previous")                     -- playerctl previous
      , ("<XF86AudioNext>",         spawn "playerctl next")                         -- playerctl next
      , ("<Print>",                 spawn "scrot")                                  -- Screenshot

    -- Run Prompt
      , ("M-p", spawn "dmenu_run")                                                  -- Run Dmenu (rofi -show drun)
      , ("M-r", spawn "rofi -show drun")                                            -- Rofi Launcher

    -- Apps
      , ("M-<Return>", spawn myTerminal)                                            -- Terminal
      , ("M-b", spawn "firefox")                                                    -- Firefox
      , ("M-f", spawn "kitty ranger")                                               -- Ranger
      , ("M-S-r", spawn "redshift -O 3800K")                                        -- Redshift On
      , ("M-x", spawn "redshift -x")                                                -- Redshift Off

    -- Window navigation
      , ("M-<Space>", sendMessage NextLayout)                                       -- Rotate through the available layout algorithms
      , ("M-<Left>", windows W.swapMaster)                                          -- Swap the focused window and the master window
      , ("M-<Up>", windows W.swapUp)                                                -- Swap the focused window with the previous window
      , ("M-<Down>", windows W.swapDown)                                            -- Swap the focused window with the next window     
      , ("M-S-<Tab>", rotSlavesDown)                                                -- Rotate all windows except master and keep focus in place
      , ("M-<Tab>", rotAllDown)                                                     -- Rotate all windows
      , ("M1-f", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts)        -- Toggles full width
      , ("M-c", toggleCopyToAll)                                                    -- Copy window to all workspaces
      , ("M-q", kill1)                                                              -- Quit the currently focused client
      , ("M-S-q", killAll)                                                          -- Quit all windows on current workspace

    -- Increase/decrease spacing (gaps)
      , ("M-C-j", decWindowSpacing 4)                                               -- Decrease window spacing
      , ("M-C-k", incWindowSpacing 4)                                               -- Increase window spacing
      , ("M-C-h", decScreenSpacing 4)                                               -- Decrease screen spacing
      , ("M-C-l", incScreenSpacing 4)                                               -- Increase screen spacing

    -- Scratchpads
      , ("M-s",   namedScratchpadAction myScratchPads "spotify")                    -- Spotify
      , ("M-d",   namedScratchpadAction myScratchPads "discord")                    -- Discord
      , ("M-S-f", namedScratchpadAction myScratchPads "ranger")                     -- Ranger

    ]  

------------------------------------------------------------------------
-- Moving between WS
------------------------------------------------------------------------
      where toggleCopyToAll = wsContainingCopies >>= \ws -> case ws of
							[] -> windows copyToAll
							_ -> killAllOtherCopies
            nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
            nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))
------------------------------------------------------------------------
-- Floats
------------------------------------------------------------------------
myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     [ className =? "confirm"                           --> doFloat
     , className =? "file_progress"                     --> doFloat
     , className =? "mpv"                               --> doCenterFloat
     , className =? "dialog"                            --> doFloat
     , className =? "download"                          --> doFloat
     , className =? "error"                             --> doFloat
     , className =? "notification"                      --> doFloat
     , className =? "toolbar"                           --> doFloat
     , isFullscreen -->  doFullFloat
     , isDialog --> doCenterFloat
     ] <+> namedScratchpadManageHook myScratchPads

myHandleEventHook :: Event -> X All
myHandleEventHook = swallowEventHook (className =? "kitty") (return True) 

------------------------------------------------------------------------
-- Startup Hooks
------------------------------------------------------------------------
myStartupHook = do
    spawnOnce "wal -R"
    spawnOnce "picom"
    spawnOnce "dunst"
    spawnOnce "xinput set-prop 'Logitech USB Receiver' 'libinput Accel Speed' -0.55"
    spawnOnce "polybar -r base"
    spawnOnce "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    --spawnOnce "/usr/lib/xfce-polkit/xfce-polkit"

------------------------------------------------------------------------
-- Main Do
------------------------------------------------------------------------
main :: IO ()
main = do
        xmonad $ ewmh def
                { manageHook = myManageHook <+> manageDocks
                , modMask            = mod4Mask
                , layoutHook         = myLayoutHook
                , workspaces         = myWorkspaces
                , terminal           = myTerminal
                , borderWidth        = myBorderWidth
                , startupHook        = myStartupHook
                , handleEventHook    = myHandleEventHook
                } `additionalKeysP` myKeys
