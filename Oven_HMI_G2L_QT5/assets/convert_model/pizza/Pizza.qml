import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: material_149_material
        objectName: "Material.149"
        baseColor: "#ff7f240c"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: principledMaterial
        metalness: 1
        roughness: 1
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_140_material
        objectName: "Material.140"
        baseColor: "#ffe78800"
        roughness: 0.25
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_150_material
        objectName: "Material.150"
        baseColor: "#ffc2702e"
        roughness: 0.25
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_148_material
        objectName: "Material.148"
        baseColor: "#ff639e10"
        roughness: 0.25
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_001_material
        objectName: "Material.001"
        baseColor: "#ffe71c00"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_147_material
        objectName: "Material.147"
        baseColor: "#ffe75d36"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: root
        objectName: "ROOT"
        Node {
            id: pizza
            objectName: "Pizza"
            position: Qt.vector3d(0, 0.153495, 0)
            rotation: Qt.quaternion(1, 0, 0, 0)
            scale: Qt.vector3d(1.37287, 1.37287, 1.37287)
            Model {
                id: circle_020
                objectName: "Circle.020"
                rotation: Qt.quaternion(0.998639, 0, -0.0521536, 0)
                scale: Qt.vector3d(0.778641, 0.778641, 0.778641)
                source: "meshes/mesh_mesh.mesh"
                materials: [
                    material_150_material
                ]
            }
            Model {
                id: cube_460
                objectName: "Cube.460"
                position: Qt.vector3d(0.379416, 0.0373729, 0)
                rotation: Qt.quaternion(0.977741, 0, -0.209813, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh7.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_461
                objectName: "Cube.461"
                position: Qt.vector3d(-0.204462, 0.0373729, 0.346785)
                rotation: Qt.quaternion(0.883213, 0, 0.468971, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh10.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_462
                objectName: "Cube.462"
                position: Qt.vector3d(-0.338926, 0.0373729, 0.0530794)
                rotation: Qt.quaternion(0.649847, 0, 0.760065, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh12.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_463
                objectName: "Cube.463"
                position: Qt.vector3d(-0.55478, 0.0373729, -0.293706)
                rotation: Qt.quaternion(0.98949, 0, 0.144599, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh14.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_464
                objectName: "Cube.464"
                position: Qt.vector3d(0.241996, 0.0373729, 0.445277)
                rotation: Qt.quaternion(0.649847, 0, 0.760065, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh16.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_465
                objectName: "Cube.465"
                position: Qt.vector3d(0.105766, 0.0373729, -0.00471806)
                rotation: Qt.quaternion(0.98949, 0, 0.144599, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh18.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_466
                objectName: "Cube.466"
                position: Qt.vector3d(0.503854, 0.0373729, -0.3863)
                rotation: Qt.quaternion(0.736325, 0, -0.676628, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh20.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_467
                objectName: "Cube.467"
                position: Qt.vector3d(-0.214488, 0.0373729, 0.455893)
                rotation: Qt.quaternion(0.87955, 0, -0.475807, 0)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh22.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_468
                objectName: "Cube.468"
                position: Qt.vector3d(-0.0120148, 0.33812, -0.286893)
                rotation: Qt.quaternion(0.933086, 0.22217, 0.278318, 0.0503054)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh24.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cube_469
                objectName: "Cube.469"
                position: Qt.vector3d(-0.0671316, 0.449807, -0.445454)
                rotation: Qt.quaternion(0.544414, 0.10535, 0.820388, 0.139561)
                scale: Qt.vector3d(0.0159542, 0.0159542, 0.0159542)
                source: "meshes/mesh_mesh26.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cylinder_105
                objectName: "Cylinder.105"
                position: Qt.vector3d(0.406624, 0.0436425, -0.204098)
                rotation: Qt.quaternion(1, 0, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh28.mesh"
                materials: [
                    material_001_material
                ]
                Model {
                    id: cube_453
                    objectName: "Cube.453"
                    position: Qt.vector3d(1.97291e-05, 0, 0)
                    scale: Qt.vector3d(0.0520618, 0.0236106, 0.0520618)
                    source: "meshes/mesh_mesh31.mesh"
                    materials: [
                        material_147_material
                    ]
                }
            }
            Model {
                id: cylinder_106
                objectName: "Cylinder.106"
                position: Qt.vector3d(-0.325755, 0.0436425, -0.137518)
                rotation: Qt.quaternion(1, 0, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh34.mesh"
                materials: [
                    material_001_material
                ]
                Model {
                    id: cube_454
                    objectName: "Cube.454"
                    position: Qt.vector3d(1.97291e-05, 0, 0)
                    scale: Qt.vector3d(0.0520618, 0.0236106, 0.0520618)
                    source: "meshes/mesh_mesh36.mesh"
                    materials: [
                        material_147_material
                    ]
                }
            }
            Model {
                id: cylinder_107
                objectName: "Cylinder.107"
                position: Qt.vector3d(-0.375681, 0.0436425, 0.330916)
                rotation: Qt.quaternion(1, 0, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh38.mesh"
                materials: [
                    material_001_material
                ]
                Model {
                    id: cube_455
                    objectName: "Cube.455"
                    position: Qt.vector3d(1.97291e-05, 0, 0)
                    scale: Qt.vector3d(0.0520618, 0.0236106, 0.0520618)
                    source: "meshes/mesh_mesh40.mesh"
                    materials: [
                        material_147_material
                    ]
                }
            }
            Model {
                id: cylinder_108
                objectName: "Cylinder.108"
                position: Qt.vector3d(0.085615, 0.0436425, 0.223913)
                rotation: Qt.quaternion(1, 0, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh42.mesh"
                materials: [
                    material_001_material
                ]
                Model {
                    id: cube_456
                    objectName: "Cube.456"
                    position: Qt.vector3d(1.97291e-05, 0, 0)
                    scale: Qt.vector3d(0.0520618, 0.0236106, 0.0520618)
                    source: "meshes/mesh_mesh44.mesh"
                    materials: [
                        material_147_material
                    ]
                }
            }
            Model {
                id: cylinder_109
                objectName: "Cylinder.109"
                position: Qt.vector3d(0.456561, 0.0436425, 0.27147)
                rotation: Qt.quaternion(1, 0, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh46.mesh"
                materials: [
                    material_001_material
                ]
                Model {
                    id: cube_457
                    objectName: "Cube.457"
                    position: Qt.vector3d(1.97291e-05, 0, 0)
                    scale: Qt.vector3d(0.0520618, 0.0236106, 0.0520618)
                    source: "meshes/mesh_mesh48.mesh"
                    materials: [
                        material_147_material
                    ]
                }
            }
            Model {
                id: cylinder_110
                objectName: "Cylinder.110"
                position: Qt.vector3d(-0.0285198, 0.0436425, 0.566322)
                rotation: Qt.quaternion(1, 0, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh50.mesh"
                materials: [
                    material_001_material
                ]
                Model {
                    id: cube_458
                    objectName: "Cube.458"
                    position: Qt.vector3d(1.97478e-05, 0, 0)
                    scale: Qt.vector3d(0.0520618, 0.0236106, 0.0520618)
                    source: "meshes/mesh_mesh52.mesh"
                    materials: [
                        material_147_material
                    ]
                }
            }
            Model {
                id: cylinder_111
                objectName: "Cylinder.111"
                position: Qt.vector3d(0.105432, 0.383184, -0.379383)
                rotation: Qt.quaternion(0.97686, 0.213878, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh54.mesh"
                materials: [
                    material_001_material
                ]
                Model {
                    id: cube_459
                    objectName: "Cube.459"
                    position: Qt.vector3d(1.9744e-05, 0, 0)
                    scale: Qt.vector3d(0.0520618, 0.0236106, 0.0520618)
                    source: "meshes/mesh_mesh56.mesh"
                    materials: [
                        material_147_material
                    ]
                }
            }
            Model {
                id: cylinder_112
                objectName: "Cylinder.112"
                position: Qt.vector3d(-0.205007, 0.0349481, 0.134744)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh58.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_113
                objectName: "Cylinder.113"
                position: Qt.vector3d(-0.540287, 0.0349481, -0.0531052)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh61.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_114
                objectName: "Cylinder.114"
                position: Qt.vector3d(0.127883, 0.0349481, 0.546111)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh63.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_115
                objectName: "Cylinder.115"
                position: Qt.vector3d(0.507766, 0.0363864, -0.0441898)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh65.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_116
                objectName: "Cylinder.116"
                position: Qt.vector3d(0.235305, 0.0457355, -0.0694643)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh67.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_117
                objectName: "Cylinder.117"
                position: Qt.vector3d(0.054161, 0.0349481, 0.386796)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh69.mesh"
                materials: [
                    material_148_material
                ]
            }
            Model {
                id: cylinder_118
                objectName: "Cylinder.118"
                position: Qt.vector3d(-0.366712, 0.0349481, -0.390759)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh71.mesh"
                materials: [
                    principledMaterial
                ]
            }
            Model {
                id: cylinder_119
                objectName: "Cylinder.119"
                position: Qt.vector3d(-0.502253, 0.0349481, 0.196568)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh74.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_120
                objectName: "Cylinder.120"
                position: Qt.vector3d(-0.0504598, 0.276749, -0.172676)
                rotation: Qt.quaternion(0.973229, 0.229836, 0, 0)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh76.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_121
                objectName: "Cylinder.121"
                position: Qt.vector3d(-0.151746, 0.399402, -0.395255)
                rotation: Qt.quaternion(0.973229, 0.229836, 0, 0)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh78.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: cylinder_122
                objectName: "Cylinder.122"
                position: Qt.vector3d(0.222334, 0.423712, -0.449798)
                rotation: Qt.quaternion(0.965027, 0.262152, 0, 0)
                scale: Qt.vector3d(0.302443, 0.302443, 0.302443)
                source: "meshes/mesh_mesh80.mesh"
                materials: [
                    material_149_material
                ]
            }
            Model {
                id: plane_074
                objectName: "Plane.074"
                position: Qt.vector3d(0.0019895, -0.027926, -0.05828)
                rotation: Qt.quaternion(0.968294, 0.249768, 0.0046173, 0.00119102)
                scale: Qt.vector3d(0.362393, 0.362393, 0.362393)
                source: "meshes/mesh_mesh82.mesh"
                materials: [
                    material_150_material
                ]
            }
            Model {
                id: plane_075
                objectName: "Plane.075"
                position: Qt.vector3d(0, 0.00258029, 0)
                rotation: Qt.quaternion(1, 0, 0, 0)
                scale: Qt.vector3d(0.562872, 0.562872, 0.562872)
                source: "meshes/mesh_mesh84.mesh"
                materials: [
                    material_140_material
                ]
            }
            Model {
                id: plane_076
                objectName: "Plane.076"
                position: Qt.vector3d(0.0019895, -0.027926, -0.05828)
                rotation: Qt.quaternion(0.968294, 0.249768, 0.0046173, 0.00119102)
                scale: Qt.vector3d(0.362393, 0.362393, 0.362393)
                source: "meshes/mesh_mesh87.mesh"
                materials: [
                    material_140_material
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
