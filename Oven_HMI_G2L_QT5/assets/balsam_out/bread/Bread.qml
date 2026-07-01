import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: rOOT

    Node {
        id: bakery
        x: 0.124018
        y: 0.787242
        z: -0.199507
        scale.x: 1.8256
        scale.y: 1.8256
        scale.z: 1.8256

        Model {
            id: cube_079
            x: 0.0763726
            y: -0.0254604
            eulerRotation.x: 12.6703
            eulerRotation.y: 22.8363
            eulerRotation.z: 7.81257
            scale.x: 0.225477
            scale.y: 0.225477
            scale.z: 0.225477
            source: "meshes/cube_079.mesh"

            PrincipledMaterial {
                id: material_076_material
                baseColor: "#ffcc4f17"
                metalness: 0
                roughness: 0.5
                cullMode: Material.NoCulling
            }
            materials: [
                material_076_material
            ]
        }

        Model {
            id: cube_080
            x: 0.0763726
            y: -0.0254604
            eulerRotation.x: 12.6703
            eulerRotation.y: 22.8363
            eulerRotation.z: 7.81257
            scale.x: 0.278028
            scale.y: 0.278028
            scale.z: 0.278028
            source: "meshes/cube_080.mesh"

            PrincipledMaterial {
                id: material_075_material
                baseColor: "#ff6d2007"
                metalness: 0
                roughness: 0.25
                cullMode: Material.NoCulling
            }
            materials: [
                material_075_material
            ]
        }

        Model {
            id: cube_099
            x: -0.452082
            y: 0.168796
            z: 0.416746
            eulerRotation.x: 90.4497
            eulerRotation.y: -51.8034
            eulerRotation.z: -12.3824
            scale.x: 0.398745
            scale.y: 0.398745
            scale.z: 0.398745
            source: "meshes/cube_099.mesh"

            PrincipledMaterial {
                id: material_077_material
                baseColor: "#ff4f1805"
                metalness: 0
                roughness: 0.25
                cullMode: Material.NoCulling
            }
            materials: [
                material_077_material
            ]
        }
    }

}
