import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: rOOT

    Model {
        id: cylinder_001
        x: 0.101397
        y: -1.15652
        eulerRotation.x: 39.2865
        eulerRotation.y: 32.3736
        eulerRotation.z: 23.6553
        scale.x: 1.66755
        scale.y: 1.66755
        scale.z: 1.66755
        source: "meshes/cylinder_001.mesh"

        DefaultMaterial {
            id: orange_001_material
            lighting:     DefaultMaterial.NoLighting
            diffuseColor: "#ffff5f00"
            cullMode:     Material.NoCulling
        }
        materials: [
            orange_001_material
        ]

        Model {
            id: cube
            x: 0.19618
            y: 0.841025
            source: "meshes/cube.mesh"

            DefaultMaterial {
                id: coklat_material
                lighting:     DefaultMaterial.NoLighting
                diffuseColor: "#ff701c0c"
                cullMode:     Material.NoCulling
            }
            materials: [
                coklat_material
            ]
        }

        Model {
            id: cube_001
            x: -0.401004
            y: 1.19822
            z: -0.496723
            source: "meshes/cube_001.mesh"
            materials: [
                coklat_material
            ]
        }

        Model {
            id: cube_002
            x: -1.25444
            y: 0.360899
            z: -0.422394
            eulerRotation.x: -18.5834
            eulerRotation.y: -5.01684
            eulerRotation.z: -5.32568
            scale.y: 1
            scale.z: 1
            source: "meshes/cube_002.mesh"

            DefaultMaterial {
                id: merah_muda_001_material
                lighting:     DefaultMaterial.NoLighting
                diffuseColor: "#ffcc3b32"
                cullMode:     Material.NoCulling
            }

            DefaultMaterial {
                id: putih_001_material
                lighting:     DefaultMaterial.NoLighting
                diffuseColor: "#ffccab9b"
                cullMode:     Material.NoCulling
            }
            materials: [
                coklat_material,
                merah_muda_001_material,
                putih_001_material
            ]

            Model {
                id: cube_003
                source: "meshes/cube_003.mesh"

                DefaultMaterial {
                    id: merah_001_material
                    lighting:     DefaultMaterial.NoLighting
                    diffuseColor: "#ff6b0e09"
                    cullMode:     Material.NoCulling
                }
                materials: [
                    merah_001_material
                ]
            }

            Model {
                id: cylinder_002
                z: -0.0878244
                source: "meshes/cylinder_002.mesh"
                materials: [
                    putih_001_material
                ]
            }

            Model {
                id: sphere_001
                z: -0.282832
                source: "meshes/sphere_001.mesh"
                materials: [
                    putih_001_material
                ]
            }
        }

        Model {
            id: cylinder
            x: -0.567323
            y: 1.20405
            z: -1.20243
            eulerRotation.x: 15.2468
            eulerRotation.y: 13.2066
            eulerRotation.z: 3.56335
            scale.x: 0.784094
            scale.y: 0.784094
            scale.z: 0.784094
            source: "meshes/cylinder.mesh"
            materials: [
                putih_001_material
            ]
        }

        Model {
            id: sphere
            x: -0.672976
            y: 1.32877
            z: -1.53685
            eulerRotation.x: 6.43503
            eulerRotation.y: -9.53481
            eulerRotation.z: 55.7494
            scale.x: 0.76818
            scale.y: 0.76818
            scale.z: 0.76818
            source: "meshes/sphere.mesh"
            materials: [
                putih_001_material
            ]
        }
    }

}
