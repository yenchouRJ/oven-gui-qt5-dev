import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: orange_001_material
        objectName: "orange.001"
        baseColor: "#ffffa400"
        roughness: 0.33544301986694336
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: coklat_material
        objectName: "coklat"
        baseColor: "#ffb15d3d"
        roughness: 0.40986162424087524
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: merah_muda_001_material
        objectName: "merah muda.001"
        baseColor: "#ffe7847b"
        roughness: 0.33544301986694336
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: putih_001_material
        objectName: "putih.001"
        baseColor: "#ffe7d6cd"
        roughness: 0.3734177350997925
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: merah_001_material
        objectName: "merah.001"
        baseColor: "#ffad4234"
        roughness: 0.33544301986694336
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: node01_Lighting_Plane_material
        objectName: "01_Lighting Plane"
        baseColor: "#ff000000"
        metalness: 1
        roughness: 1
        emissiveFactor: Qt.vector3d(1, 1, 1)
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: root
        objectName: "ROOT"
        Model {
            id: cylinder_001
            objectName: "Cylinder.001"
            position: Qt.vector3d(0.101397, -1.15652, 0)
            rotation: Qt.quaternion(0.904474, 0.262168, 0.323143, 0.0936654)
            scale: Qt.vector3d(1.66755, 1.66755, 1.66755)
            source: "meshes/cylinder_002_mesh.mesh"
            materials: [
                orange_001_material
            ]
            Model {
                id: cube
                objectName: "Cube"
                position: Qt.vector3d(0.19618, 0.841025, 0)
                source: "meshes/cube_003_mesh.mesh"
                materials: [
                    coklat_material
                ]
            }
            Model {
                id: cube_001
                objectName: "Cube.001"
                position: Qt.vector3d(-0.401004, 1.19822, -0.496723)
                source: "meshes/cube_004_mesh.mesh"
                materials: [
                    coklat_material
                ]
            }
            Model {
                id: cube_002
                objectName: "Cube.002"
                position: Qt.vector3d(-1.25444, 0.360899, -0.422394)
                rotation: Qt.quaternion(0.984541, -0.163139, -0.0356513, -0.052864)
                scale: Qt.vector3d(1, 1, 1)
                source: "meshes/cube_002_mesh.mesh"
                materials: [
                    coklat_material,
                    merah_muda_001_material,
                    putih_001_material
                ]
                Model {
                    id: cube_003
                    objectName: "Cube.003"
                    source: "meshes/cube_006_mesh.mesh"
                    materials: [
                        merah_001_material
                    ]
                }
                Model {
                    id: cylinder_002
                    objectName: "Cylinder.002"
                    position: Qt.vector3d(0, 0, -0.0878244)
                    source: "meshes/cylinder_004_mesh.mesh"
                    materials: [
                        putih_001_material
                    ]
                }
                Model {
                    id: sphere_001
                    objectName: "Sphere.001"
                    position: Qt.vector3d(0, 0, -0.282832)
                    source: "meshes/sphere_002_mesh.mesh"
                    materials: [
                        putih_001_material
                    ]
                }
            }
            Model {
                id: cylinder
                objectName: "Cylinder"
                position: Qt.vector3d(-0.567323, 1.20405, -1.20243)
                rotation: Qt.quaternion(0.984585, 0.128173, 0.11802, 0.0153639)
                scale: Qt.vector3d(0.784094, 0.784094, 0.784094)
                source: "meshes/cylinder_001_mesh.mesh"
                materials: [
                    putih_001_material
                ]
            }
            Model {
                id: sphere
                objectName: "Sphere"
                position: Qt.vector3d(-0.672976, 1.32877, -1.53685)
                rotation: Qt.quaternion(0.877344, 0.0882392, -0.0472012, 0.469311)
                scale: Qt.vector3d(0.76818, 0.76818, 0.76818)
                source: "meshes/sphere_001_mesh.mesh"
                materials: [
                    putih_001_material
                ]
            }
        }
        // Model {
        //     id: plane_002
        //     objectName: "Plane.002"
        //     position: Qt.vector3d(4.01126, 1.03458, 7.40238)
        //     rotation: Qt.quaternion(0.673382, 0.673382, 0.215769, -0.215769)
        //     scale: Qt.vector3d(1.2185, 1.2185, 1.22195)
        //     source: "meshes/plane_002_mesh.mesh"
        //     materials: [
        //         node01_Lighting_Plane_material
        //     ]
        // }
    }

    // Animations:
}
