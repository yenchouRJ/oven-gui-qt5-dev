import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: stick_material
        objectName: "STICK"
        baseColor: "#ff2a2c0c"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: cerry_material
        objectName: "CERRY"
        baseColor: "#ffffeff7"
        roughness: 0.20000000298023224
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: stick_001_material
        objectName: "STICK.001"
        baseColor: "#ff2a2c0c"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: cerry_001_material
        objectName: "CERRY.001"
        baseColor: "#ff880700"
        roughness: 0.20000000298023224
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: ayam_material
        objectName: "AYAM"
        baseColor: "#ff883a1e"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: stick_002_material
        objectName: "STICK.002"
        baseColor: "#ff2a2c0c"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: cerry_002_material
        objectName: "CERRY.002"
        baseColor: "#ff880700"
        roughness: 0.20000000298023224
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: root
        objectName: "ROOT"
        // Model {
        //     id: cylinder_052
        //     objectName: "Cylinder.052"
        //     position: Qt.vector3d(-0.234925, 0.161845, 3.12338)
        //     rotation: Qt.quaternion(0.330519, 0.0215542, 0.938679, 0.0957779)
        //     scale: Qt.vector3d(1.33013, 1.33013, 1.33013)
        //     source: "meshes/cylinder_004_mesh.mesh"
        //     materials: [
        //         stick_material
        //     ]
        // }
        // Model {
        //     id: sphere_002
        //     objectName: "Sphere.002"
        //     position: Qt.vector3d(-0.317092, 0.389541, 3.17667)
        //     rotation: Qt.quaternion(0.824895, 0.122617, 0.548214, -0.0630439)
        //     source: "meshes/sphere_001_mesh.mesh"
        //     materials: [
        //         cerry_material
        //     ]
        // }
        // Node {
        //     id: bezierCircle_001
        //     objectName: "BezierCircle.001"
        //     position: Qt.vector3d(14.5697, -7.94049, -20.4893)
        //     rotation: Qt.quaternion(0.97976, 0.151772, 0.12898, 0.0199799)
        //     scale: Qt.vector3d(0.602388, 0.602389, 0.602388)
        // }
        // Node {
        //     id: bezierCircle_002
        //     objectName: "BezierCircle.002"
        //     position: Qt.vector3d(-17.7414, 38.8998, -10.8122)
        //     rotation: Qt.quaternion(0.97976, 0.151772, 0.12898, 0.0199799)
        //     scale: Qt.vector3d(0.537316, 0.537316, 0.537316)
        // }
        // Model {
        //     id: cylinder_001
        //     objectName: "Cylinder.001"
        //     position: Qt.vector3d(-0.234925, 0.161845, 3.12338)
        //     rotation: Qt.quaternion(0.330519, 0.0215542, 0.938679, 0.0957779)
        //     scale: Qt.vector3d(1.33013, 1.33013, 1.33013)
        //     source: "meshes/cylinder_001_mesh.mesh"
        //     materials: [
        //         stick_001_material
        //     ]
        // }
        // Model {
        //     id: sphere_001
        //     objectName: "Sphere.001"
        //     position: Qt.vector3d(-0.317092, 0.389541, 3.17667)
        //     rotation: Qt.quaternion(0.824895, 0.122617, 0.548214, -0.0630439)
        //     source: "meshes/sphere_002_mesh.mesh"
        //     materials: [
        //         cerry_001_material
        //     ]
        // }
        Model {
            id: cube_020
            objectName: "Cube.020"
            position: Qt.vector3d(-0.467505, 27.313, -8.45292)
            rotation: Qt.quaternion(1.15202e-07, 5.02429e-15, 0.707107, 0.707107)
            scale: Qt.vector3d(6.2061, 6.2061, 6.2061)
            source: "meshes/cube_001_mesh.mesh"
            materials: [
                ayam_material
            ]
        }
        // Model {
        //     id: cylinder_002
        //     objectName: "Cylinder.002"
        //     position: Qt.vector3d(-0.234925, 0.161845, 3.12338)
        //     rotation: Qt.quaternion(0.330519, 0.0215542, 0.938679, 0.0957779)
        //     scale: Qt.vector3d(1.33013, 1.33013, 1.33013)
        //     source: "meshes/cylinder_002_mesh.mesh"
        //     materials: [
        //         stick_002_material
        //     ]
        // }
        // Model {
        //     id: sphere_003
        //     objectName: "Sphere.003"
        //     position: Qt.vector3d(-0.317092, 0.389541, 3.17667)
        //     rotation: Qt.quaternion(0.824895, 0.122617, 0.548214, -0.0630439)
        //     source: "meshes/sphere_003_mesh.mesh"
        //     materials: [
        //         cerry_002_material
        //     ]
        // }
    }

    // Animations:
}
