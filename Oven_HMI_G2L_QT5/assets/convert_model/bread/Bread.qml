import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: material_076_material
        objectName: "Material.076"
        baseColor: "#ffe79755"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_075_material
        objectName: "Material.075"
        baseColor: "#ffaf642f"
        roughness: 0.25
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_077_material
        objectName: "Material.077"
        baseColor: "#ff975628"
        roughness: 0.25
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: principledMaterial
        metalness: 1
        roughness: 1
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: root
        objectName: "ROOT"
        Node {
            id: bakery
            objectName: "Bakery"
            position: Qt.vector3d(0.124018, 0.787242, -0.199507)
            scale: Qt.vector3d(1.8256, 1.8256, 1.8256)
            Model {
                id: cube_079
                objectName: "Cube.079"
                position: Qt.vector3d(0.0763726, -0.0254604, 0)
                rotation: Qt.quaternion(0.973448, 0.0945051, 0.20367, 0.0445748)
                scale: Qt.vector3d(0.225477, 0.225477, 0.225477)
                source: "meshes/mesh_mesh.mesh"
                materials: [
                    material_076_material
                ]
            }
            Model {
                id: cube_080
                objectName: "Cube.080"
                position: Qt.vector3d(0.0763726, -0.0254604, 0)
                rotation: Qt.quaternion(0.973448, 0.0945051, 0.20367, 0.0445748)
                scale: Qt.vector3d(0.278028, 0.278028, 0.278028)
                source: "meshes/mesh_mesh7.mesh"
                materials: [
                    material_075_material
                ]
            }
            Model {
                id: cube_099
                objectName: "Cube.099"
                position: Qt.vector3d(-0.452082, 0.168796, 0.416746)
                rotation: Qt.quaternion(0.66332, 0.60166, -0.374743, 0.239957)
                scale: Qt.vector3d(0.398745, 0.398745, 0.398745)
                source: "meshes/cube_201_mesh.mesh"
                materials: [
                    material_077_material
                ]
            }
        }
        // Node {
        //     id: empty
        //     objectName: "Empty"
        //     position: Qt.vector3d(0, 2.49004, 0)
        //     scale: Qt.vector3d(4.96441, 4.96441, 4.96441)
        //     Model {
        //         id: plane_001
        //         objectName: "Plane.001"
        //         position: Qt.vector3d(0, -0.711335, 0)
        //         scale: Qt.vector3d(0.657842, 0.657842, 0.657842)
        //         source: "meshes/plane_001_mesh.mesh"
        //         materials: [
        //             principledMaterial
        //         ]
        //     }
        // }
    }

    // Animations:
}
