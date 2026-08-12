package org.haxe.roguelike;

import android.content.pm.ActivityInfo;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

import org.libsdl.app.SDLActivity;

/**
 * Roguelike on Android.
 *
 * Uses the HashLink runtime (AOT-compiled game + libhl) with SDL3 for
 * windowing/input. Boots directly into immersive fullscreen, landscape, at the
 * device's native display resolution.
 */
public class MainActivity extends SDLActivity {

    @Override
    protected String[] getLibraries() {
        // SDL3 first (separate JNI_OnLoad), then the game library (libheapsapp.so).
        return new String[]{"SDL3", "heapsapp"};
    }

    @Override
    protected String getMainFunction() {
        // Entry point provided by the AOT-compiled game (hlc_main.c main()).
        return "main";
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // The game always plays in landscape.
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        // Immersive fullscreen at native resolution + keep the screen awake.
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        // The decor view may not be attached yet right after onCreate, so defer
        // the system-bar hide until the view hierarchy is ready.
        View decor = getWindow().getDecorView();
        if (decor != null)
            decor.post(this::hideSystemBars);
    }

    /**
     * SDL re-applies an orientation from the initial window size and can
     * override the manifest. Force landscape here so the game is always
     * landscape on any device.
     */
    @Override
    public void setOrientationBis(int w, int h, boolean resizable, String hint) {
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        // Re-hide system bars after the user swipes them back (immersive sticky).
        if (hasFocus)
            hideSystemBars();
    }

    private void hideSystemBars() {
        Window window = getWindow();
        if (window == null) return;

        View decor = window.getDecorView();
        if (decor == null) return; // not attached yet

        if (Build.VERSION.SDK_INT >= 30) {
            // Native immersive fullscreen (all Android 11+ devices, incl. 15/16).
            window.setDecorFitsSystemWindows(false);
            WindowInsetsController controller = window.getInsetsController();
            if (controller != null) {
                controller.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
                controller.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            decor.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
        }
    }
}
