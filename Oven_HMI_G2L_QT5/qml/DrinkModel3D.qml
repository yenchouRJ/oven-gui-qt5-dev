import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: root
    // Current drink identifier used to select a model.
    property string drinkId: ""

    Loader3D {
        id: modelLoader
        source: getModelSource(root.drinkId)
        
        // Apply drink-specific transforms after the model loads.
        onLoaded: {
            var item = modelLoader.item
            if (item) {
                applyTransform(root.drinkId, item)
            }
        }
    }

    // Model path mapping.
    function getModelSource(id) {
        // Use QRC paths for cross-platform stability.
        switch (id) {
            case "pizza":       return "qrc:/qml/models/pizza/Pizza.qml"
            case "chicken":     return "qrc:/qml/models/chicken/Chicken.qml"
            case "turkey":      return "qrc:/qml/models/turkey/Turkey.qml"
            case "meatball":    return "qrc:/qml/models/meatball/Meatball.qml"
            case "fish":        return "qrc:/qml/models/fish/Fish.qml"
            case "bread":       return "qrc:/qml/models/bread/Bread.qml"
            
            // Default model. (Qt5 port: original referenced a missing
            // coffee_cup/Coffee_cup.qml; fall back to an existing model.)
            default: return "qrc:/qml/models/pizza/Pizza.qml"
        }
    }

    // Model scale and position adjustments.
    function applyTransform(id, item) {
        // Defaults.
        item.scale = Qt.vector3d(20, 20, 20)
        item.position = Qt.vector3d(0, 0, 0)

        // Per-model overrides.
        switch (id) {
            case "pizza":
                item.scale = Qt.vector3d(90, 90, 90)
                break
            case "chicken":
                item.scale = Qt.vector3d(30, 30, 30)
                item.position = Qt.vector3d(-30, 20, -10)
                break
            case "meatball":
                item.scale = Qt.vector3d(70, 70, 70)
                break
            case "fish":
                item.scale = Qt.vector3d(40, 40, 40)
                item.position = Qt.vector3d(10, 25, 0)
                break
            case "bread":
                item.scale = Qt.vector3d(70, 70, 70)
                item.position = Qt.vector3d(0, -20, 0)
                break

        }
    }

    // Lighting presets for each model.
    function updateLighting(id, dirLight, pointLight1, pointLight2) {
        // Default lighting scheme.
        dirLight.color = "#ffffff" 
        dirLight.brightness = 3.5
        
        // Fill light (left).
        pointLight1.color = "#eef5ff" 
        pointLight1.brightness = 2.0
        pointLight1.position = Qt.vector3d(-200, 100, 200)

        // Rim light (right/back).
        pointLight2.color = "#ffffff"
        pointLight2.brightness = 4.0
        pointLight2.position = Qt.vector3d(100, 250, -100)

        // Per-model tweaks.
        switch (id) {
            case "espresso":
                // Increase contrast for the glass cup.
                dirLight.brightness = 4.5
                pointLight2.brightness = 5.0
                break
            
            case "latte":
                // Latte cup is taller; raise the rim light.
                pointLight2.position = Qt.vector3d(100, 300, -100)
                break
        }
    }
}
