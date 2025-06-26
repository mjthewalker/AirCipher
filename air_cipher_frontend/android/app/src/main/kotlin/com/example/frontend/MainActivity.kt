package com.example.frontend

import android.os.Bundle
import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Acquire multicast so broadcasts work on hotspot
        (applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager)
            ?.apply {
                multicastLock = createMulticastLock("webrtcLock").also {
                    it.setReferenceCounted(true)
                    it.acquire()
                }
            }
    }

    override fun onDestroy() {
        multicastLock?.release()
        super.onDestroy()
    }
}
