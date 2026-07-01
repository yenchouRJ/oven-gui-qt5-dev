import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: node29_Takoyaki
    x: 0.036335
    y: 0.118001
    z: -0.068128
    eulerRotation.y: -42.9285
    scale.x: 0.693417
    scale.y: 0.693417
    scale.z: 0.693417

    Model {
        id: pan
        y: -0.512357
        scale.x: 1.5043
        scale.y: 1.5043
        scale.z: 1.5043
        source: "meshes/pan.mesh"

        PrincipledMaterial {
            id: box_material
            baseColor: "#ff080808"
            metalness: 0
            roughness: 0.755916
            cullMode: Material.NoCulling
        }
        materials: [
            box_material
        ]
    }

    Model {
        id: plane_004
        x: 0.470316
        y: -0.284175
        z: 0.118746
        eulerRotation.x: 61.5399
        eulerRotation.y: 23.7739
        eulerRotation.z: 16.4691
        scale.x: 0.269146
        scale.y: 0.269145
        scale.z: 0.269145
        source: "meshes/plane_004.mesh"

        PrincipledMaterial {
            id: c3_material
            baseColor: "#ff2d5806"
            metalness: 0.104545
            roughness: 0.440909
            cullMode: Material.NoCulling
        }
        materials: [
            c3_material
        ]
    }

    Model {
        id: plate
        y: -0.760563
        scale.x: 1.42867
        scale.y: 1.42867
        scale.z: 1.42867
        source: "meshes/plate.mesh"

        PrincipledMaterial {
            id: c9_material
            baseColor: "#ff47190f"
            metalness: 0.1
            roughness: 0.586364
            cullMode: Material.NoCulling
        }
        materials: [
            c9_material
        ]
    }

    Model {
        id: takoyaki
        x: -0.593347
        z: 0.626787
        scale.x: 0.78075
        scale.y: 0.78075
        scale.z: 0.78075
        source: "meshes/takoyaki.mesh"

        PrincipledMaterial {
            id: c1_material
            baseColor: "#ffaf150d"
            metalness: 0.1
            roughness: 0.154546
            cullMode: Material.NoCulling
        }

        PrincipledMaterial {
            id: c2_material
            baseColor: "#ffaf6040"
            metalness: 0.1
            roughness: 0.4
            cullMode: Material.NoCulling
        }
        materials: [
            c3_material,
            c1_material,
            c2_material
        ]
    }

    Model {
        id: wood
        x: 0.602069
        y: 0.944677
        z: -1.36801
        eulerRotation.x: -30.8977
        eulerRotation.y: 36.6758
        eulerRotation.z: -28.8123
        scale.x: 0.0431432
        scale.y: 0.0431432
        scale.z: 0.0431432
        source: "meshes/wood.mesh"

        PrincipledMaterial {
            id: c6_material
            baseColor: "#ffab4c15"
            metalness: 0
            roughness: 0.490909
            cullMode: Material.NoCulling
        }
        materials: [
            c6_material
        ]
    }
}
