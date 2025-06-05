/**
 * Edge Impulse FOMO to MQTT
 * This only works on boards with lots of RAM
 * (e.g. ESP32S3 with OPI RAM)
 *
 * BE SURE TO SET "TOOLS > CORE DEBUG LEVEL = INFO"
 * to turn on debug messages/private/var/folders/gc/6_ybdx0x0zl3q1l5j7jclly00000gn/T/.arduinoIDE-unsaved2025321-37376-1vszn9v.x60kj/sketch_apr21a/sketch_apr21a.ino
 */
#define WIFI_SSID "Kaylee"
#define WIFI_PASS ""

#include <alien_OD_inferencing.h>
#include <PubSubClient.h>
#include <eloquent_esp32cam.h>
#include <eloquent_esp32cam/extra/esp32/wifi.h>
#include <eloquent_esp32cam/edgeimpulse/fomo.h>

using eloq::camera;
using eloq::wifi;
using eloq::ei::fomo;


/**
 * 
 */
void setup() {
    delay(3000);
    Serial.begin(115200);
    Serial.println("__EDGE IMPULSE FOMO TO MQTT__");

    // camera settings
    // replace with your own model!
    camera.pinout.eye_s3();
    camera.brownout.disable();
    // PSRAM FOMO works on any resolution
    // (up to your PSRAM limits, of course)
    // but it works faster on RGB 5656
    // at YOLO (96x96) resolution
    camera.pixformat.rgb565();
    camera.resolution.yolo();

    // configure MQTT broker
    fomo.mqtt.server("172.20.10.7", 1883);
    // fomo.mqtt.auth("user", "password");
    fomo.mqtt.clientName("kaylee-fomo-mqtt");

    // init camera
    while (!camera.begin().isOk())
        Serial.println(camera.exception.toString());

    // connect to WiFi
    while (!wifi.connect().isOk())
      Serial.println(wifi.exception.toString());

    // connect to MQTT
    while (!fomo.mqtt.connect().isOk())
      Serial.println(fomo.mqtt.exception.toString());

    // run function when no object is detected
    fomo.daemon.whenYouDontSeeAnything([]() {
      // do nothing
    });

    // run function when you see any object
    fomo.daemon.whenYouSeeAny([](int i, bbox_t bbox) {
      Serial.printf(
          "#%d) Found %s at (x = %d, y = %d) (size %d x %d). "
          "Proba is %.2f",
          i + 1,
          bbox.label,
          bbox.x,
          bbox.y,
          bbox.width,
          bbox.height,
          bbox.proba
        );

        // "fomo-any" is the MQTT topic
        fomo.mqtt.publish("fomo-any");
    });

    // run function when you see a specific object
    fomo.daemon.whenYouSee("alien", [](int i, bbox_t bbox) {
      Serial.printf(
          "Alien found at (x = %d, y = %d) (size %d x %d).",
          bbox.x,
          bbox.y,
          bbox.width,
          bbox.height
        );

        // "fomo-penguin" is the MQTT topic
        fomo.mqtt.publish("fomo-alien");
    });

    // start daemon
    fomo.daemon.start();

    Serial.println("Camera OK");
    Serial.println("Put object in front of camera");
}


void loop() {
  return;
}
