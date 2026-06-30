import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: box_material
        objectName: "box"
        baseColor: "#ff323232"
        roughness: 0.7559162974357605
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: c3_material
        objectName: "c3"
        baseColor: "#ff749f2c"
        metalness: 0.104545459151268
        roughness: 0.44090911746025085
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: c9_material
        objectName: "c9"
        baseColor: "#ff905844"
        metalness: 0.10000000149011612
        roughness: 0.586363673210144
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: c1_material
        objectName: "c1"
        baseColor: "#ffd85141"
        metalness: 0.10000000149011612
        roughness: 0.15454550087451935
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: c2_material
        objectName: "c2"
        baseColor: "#ffd8a589"
        metalness: 0.10000000149011612
        roughness: 0.4000000059604645
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        transmissionFactor: 0.30000001192092896
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: c6_material
        objectName: "c6"
        baseColor: "#ffd59550"
        roughness: 0.4909090995788574
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }

    // Nodes:
    Node {
        id: node29_Takoyaki
        objectName: "29 Takoyaki"
        position: Qt.vector3d(0.036335, 0.118001, -0.068128)
        rotation: Qt.quaternion(0.930646, 0, -0.365921, 0)
        scale: Qt.vector3d(0.693417, 0.693417, 0.693417)
        Model {
            id: pan
            objectName: "pan"
            position: Qt.vector3d(0, -0.512357, 0)
            scale: Qt.vector3d(1.5043, 1.5043, 1.5043)
            source: "meshes/mesh_mesh.mesh"
            materials: [
                box_material
            ]
        }
        Model {
            id: plane_004
            objectName: "Plane.004"
            position: Qt.vector3d(0.470316, -0.284175, 0.118746)
            rotation: Qt.quaternion(0.847227, 0.470112, 0.246863, 0.0161326)
            scale: Qt.vector3d(0.269146, 0.269145, 0.269145)
            source: "meshes/mesh_mesh6.mesh"
            materials: [
                c3_material
            ]
        }
        Model {
            id: plate
            objectName: "plate"
            position: Qt.vector3d(0, -0.760563, 0)
            scale: Qt.vector3d(1.42867, 1.42867, 1.42867)
            source: "meshes/mesh_mesh9.mesh"
            materials: [
                c9_material
            ]
        }
        Model {
            id: takoyaki
            objectName: "takoyaki"
            position: Qt.vector3d(-0.593347, 0, 0.626787)
            scale: Qt.vector3d(0.78075, 0.78075, 0.78075)
            source: "meshes/takoyaki_mesh.mesh"
            materials: [
                c3_material,
                c1_material,
                c2_material
            ]
        }
        Model {
            id: wood
            objectName: "wood"
            position: Qt.vector3d(0.602069, 0.944677, -1.36801)
            rotation: Qt.quaternion(0.907004, -0.169452, 0.356625, -0.146455)
            scale: Qt.vector3d(0.0431432, 0.0431432, 0.0431432)
            source: "meshes/cylinder_mesh.mesh"
            materials: [
                c6_material
            ]
        }
    }

    // Animations:
}
