import QtQuick 2.15
import QtQuick3D 1.15
import QtQuick.Timeline 1.0

Node {
    id: rOOT

    Model {
        id: cylinder_052
        x: -0.234925
        y: 0.161845
        z: 3.12338
        eulerRotation.x: 165.733
        eulerRotation.y: 38.0519
        eulerRotation.z: 172.427
        scale.x: 1.33013
        scale.y: 1.33013
        scale.z: 1.33013
        source: "meshes/cylinder_052.mesh"

        PrincipledMaterial {
            id: sTICK_material
            baseColor: "#ff060601"
            metalness: 0
            roughness: 0.5
            cullMode: Material.NoCulling
        }
        materials: [
            sTICK_material
        ]
    }

    Model {
        id: sphere_002
        x: -0.317092
        y: 0.389541
        z: 3.17667
        eulerRotation.x: 19.8514
        eulerRotation.y: 66.9112
        eulerRotation.z: 4.45062
        source: "meshes/sphere_002.mesh"

        PrincipledMaterial {
            id: cERRY_material
            baseColor: "#ffffdcee"
            metalness: 0
            roughness: 0.2
            cullMode: Material.NoCulling
        }
        materials: [
            cERRY_material
        ]
    }



    Model {
        id: cylinder_001
        x: -0.234925
        y: 0.161845
        z: 3.12338
        eulerRotation.x: 165.733
        eulerRotation.y: 38.0519
        eulerRotation.z: 172.427
        scale.x: 1.33013
        scale.y: 1.33013
        scale.z: 1.33013
        source: "meshes/cylinder_001.mesh"
        materials: [
            sTICK_material
        ]
    }

    Model {
        id: sphere_001
        x: -0.317092
        y: 0.389541
        z: 3.17667
        eulerRotation.x: 19.8514
        eulerRotation.y: 66.9112
        eulerRotation.z: 4.45062
        source: "meshes/sphere_001.mesh"

        PrincipledMaterial {
            id: cERRY_001_material
            baseColor: "#ff3f0100"
            metalness: 0
            roughness: 0.2
            cullMode: Material.NoCulling
        }
        materials: [
            cERRY_001_material
        ]
    }

    Model {
        id: cube_020
        x: -0.467505
        y: 27.313
        z: -8.45292
        eulerRotation.x: 90
        eulerRotation.y: 9.33467e-06
        eulerRotation.z: 180
        scale.x: 6.2061
        scale.y: 6.2061
        scale.z: 6.2061
        source: "meshes/cube_020.mesh"

        PrincipledMaterial {
            id: aYAM_material
            baseColor: "#ff3f0b03"
            metalness: 0
            roughness: 0.5
            cullMode: Material.NoCulling
        }
        materials: [
            aYAM_material
        ]
    }

    Model {
        id: cylinder_002
        x: -0.234925
        y: 0.161845
        z: 3.12338
        eulerRotation.x: 165.733
        eulerRotation.y: 38.0519
        eulerRotation.z: 172.427
        scale.x: 1.33013
        scale.y: 1.33013
        scale.z: 1.33013
        source: "meshes/cylinder_002.mesh"
        materials: [
            sTICK_material
        ]
    }

    Model {
        id: sphere_003
        x: -0.317092
        y: 0.389541
        z: 3.17667
        eulerRotation.x: 19.8514
        eulerRotation.y: 66.9112
        eulerRotation.z: 4.45062
        source: "meshes/sphere_003.mesh"
        materials: [
            cERRY_001_material
        ]
    }

    Timeline {
        id: timeline0
        startFrame: 0
        endFrame: 4167
        currentFrame: 0
        enabled: true
        animations: [
            TimelineAnimation {
                duration: 4167
                from: 0
                to: 4167
                running: true
            }
        ]

        KeyframeGroup {
            target: cylinder_052
            property: "position"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-0.234925, 0.161845, 3.12338)
            }
        }

        KeyframeGroup {
            target: cylinder_052
            property: "eulerRotation"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-9.52984, 140.701, 6.04042)
            }
        }

        KeyframeGroup {
            target: cylinder_052
            property: "scale"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(1.33013, 1.33013, 1.33013)
            }
        }
    }

    Timeline {
        id: timeline1
        startFrame: 0
        endFrame: 4167
        currentFrame: 0
        enabled: false
        animations: [
            TimelineAnimation {
                duration: 4167
                from: 0
                to: 4167
                running: true
            }
        ]

        KeyframeGroup {
            target: sphere_002
            property: "position"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-0.317092, 0.389541, 3.17667)
            }
        }

        KeyframeGroup {
            target: sphere_002
            property: "eulerRotation"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(15.7485, 67.4655, 1.81189)
            }
        }

        KeyframeGroup {
            target: sphere_002
            property: "scale"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(1, 1, 1)
            }
        }
    }

    Timeline {
        id: timeline2
        startFrame: 0
        endFrame: 4167
        currentFrame: 0
        enabled: false
        animations: [
            TimelineAnimation {
                duration: 4167
                from: 0
                to: 4167
                running: true
            }
        ]

        KeyframeGroup {
            target: cylinder_001
            property: "position"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-0.234925, 0.161845, 3.12338)
            }
        }

        KeyframeGroup {
            target: cylinder_001
            property: "eulerRotation"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-9.52984, 140.701, 6.04042)
            }
        }

        KeyframeGroup {
            target: cylinder_001
            property: "scale"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(1.33013, 1.33013, 1.33013)
            }
        }
    }

    Timeline {
        id: timeline3
        startFrame: 0
        endFrame: 4167
        currentFrame: 0
        enabled: false
        animations: [
            TimelineAnimation {
                duration: 4167
                from: 0
                to: 4167
                running: true
            }
        ]

        KeyframeGroup {
            target: sphere_001
            property: "position"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-0.317092, 0.389541, 3.17667)
            }
        }

        KeyframeGroup {
            target: sphere_001
            property: "eulerRotation"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(15.7485, 67.4655, 1.81189)
            }
        }

        KeyframeGroup {
            target: sphere_001
            property: "scale"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(1, 1, 1)
            }
        }
    }

    Timeline {
        id: timeline4
        startFrame: 0
        endFrame: 4167
        currentFrame: 0
        enabled: false
        animations: [
            TimelineAnimation {
                duration: 4167
                from: 0
                to: 4167
                running: true
            }
        ]

        KeyframeGroup {
            target: cylinder_002
            property: "position"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-0.234925, 0.161845, 3.12338)
            }
        }

        KeyframeGroup {
            target: cylinder_002
            property: "eulerRotation"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-9.52984, 140.701, 6.04042)
            }
        }

        KeyframeGroup {
            target: cylinder_002
            property: "scale"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(1.33013, 1.33013, 1.33013)
            }
        }
    }

    Timeline {
        id: timeline5
        startFrame: 0
        endFrame: 4167
        currentFrame: 0
        enabled: false
        animations: [
            TimelineAnimation {
                duration: 4167
                from: 0
                to: 4167
                running: true
            }
        ]

        KeyframeGroup {
            target: sphere_003
            property: "position"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(-0.317092, 0.389541, 3.17667)
            }
        }

        KeyframeGroup {
            target: sphere_003
            property: "eulerRotation"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(15.7485, 67.4655, 1.81189)
            }
        }

        KeyframeGroup {
            target: sphere_003
            property: "scale"

            Keyframe {
                frame: 4166.67
                value: Qt.vector3d(1, 1, 1)
            }
        }
    }
}
