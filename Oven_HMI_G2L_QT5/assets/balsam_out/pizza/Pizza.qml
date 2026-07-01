import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: rOOT

    Node {
        id: pizza
        y: 0.153495
        scale.x: 1.37287
        scale.y: 1.37287
        scale.z: 1.37287

        Model {
            id: circle_020
            eulerRotation.y: -5.97907
            scale.x: 0.778641
            scale.y: 0.778641
            scale.z: 0.778641
            source: "meshes/circle_020.mesh"

            PrincipledMaterial {
                id: material_150_material
                baseColor: "#ff892a07"
                metalness: 0
                roughness: 0.25
                cullMode: Material.NoCulling
            }
            materials: [
                material_150_material
            ]
        }

        Model {
            id: cube_460
            x: 0.379416
            y: 0.0373729
            eulerRotation.y: -24.2228
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_460.mesh"

            PrincipledMaterial {
                id: material_148_material
                baseColor: "#ff205701"
                metalness: 0
                roughness: 0.25
                cullMode: Material.NoCulling
            }
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_461
            x: -0.204462
            y: 0.0373729
            z: 0.346785
            eulerRotation.y: 55.9351
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_461.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_462
            x: -0.338926
            y: 0.0373729
            z: 0.0530794
            eulerRotation.x: 180
            eulerRotation.y: 81.0601
            eulerRotation.z: 180
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_462.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_463
            x: -0.55478
            y: 0.0373729
            z: -0.293706
            eulerRotation.y: 16.6281
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_463.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_464
            x: 0.241996
            y: 0.0373729
            z: 0.445277
            eulerRotation.x: 180
            eulerRotation.y: 81.0601
            eulerRotation.z: 180
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_464.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_465
            x: 0.105766
            y: 0.0373729
            z: -0.00471806
            eulerRotation.y: 16.6281
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_465.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_466
            x: 0.503854
            y: 0.0373729
            z: -0.3863
            eulerRotation.y: -85.1615
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_466.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_467
            x: -0.214488
            y: 0.0373729
            z: 0.455893
            eulerRotation.y: -56.8238
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_467.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_468
            x: -0.0120148
            y: 0.33812
            z: -0.286893
            eulerRotation.x: 30.6689
            eulerRotation.y: 29.8041
            eulerRotation.z: 14.5194
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_468.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cube_469
            x: -0.0671316
            y: 0.449807
            z: -0.445454
            eulerRotation.x: 136.977
            eulerRotation.y: 59.7524
            eulerRotation.z: 139.849
            scale.x: 0.0159542
            scale.y: 0.0159542
            scale.z: 0.0159542
            source: "meshes/cube_469.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cylinder_105
            x: 0.406624
            y: 0.0436425
            z: -0.204098
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/cylinder_105.mesh"

            PrincipledMaterial {
                id: material_001_material
                baseColor: "#ffcc0300"
                metalness: 0
                roughness: 0.5
                cullMode: Material.NoCulling
            }
            materials: [
                material_001_material
            ]

            Model {
                id: cube_453
                x: 1.97291e-05
                scale.x: 0.0520618
                scale.y: 0.0236106
                scale.z: 0.0520618
                source: "meshes/cube_453.mesh"

                PrincipledMaterial {
                    id: material_147_material
                    baseColor: "#ffcc1c09"
                    metalness: 0
                    roughness: 0.5
                    cullMode: Material.NoCulling
                }
                materials: [
                    material_147_material
                ]
            }
        }

        Model {
            id: cylinder_106
            x: -0.325755
            y: 0.0436425
            z: -0.137518
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/cylinder_106.mesh"
            materials: [
                material_001_material
            ]

            Model {
                id: cube_454
                x: 1.97291e-05
                scale.x: 0.0520618
                scale.y: 0.0236106
                scale.z: 0.0520618
                source: "meshes/cube_454.mesh"
                materials: [
                    material_147_material
                ]
            }
        }

        Model {
            id: cylinder_107
            x: -0.375681
            y: 0.0436425
            z: 0.330916
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/cylinder_107.mesh"
            materials: [
                material_001_material
            ]

            Model {
                id: cube_455
                x: 1.97291e-05
                scale.x: 0.0520618
                scale.y: 0.0236106
                scale.z: 0.0520618
                source: "meshes/cube_455.mesh"
                materials: [
                    material_147_material
                ]
            }
        }

        Model {
            id: cylinder_108
            x: 0.085615
            y: 0.0436425
            z: 0.223913
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/cylinder_108.mesh"
            materials: [
                material_001_material
            ]

            Model {
                id: cube_456
                x: 1.97291e-05
                scale.x: 0.0520618
                scale.y: 0.0236106
                scale.z: 0.0520618
                source: "meshes/cube_456.mesh"
                materials: [
                    material_147_material
                ]
            }
        }

        Model {
            id: cylinder_109
            x: 0.456561
            y: 0.0436425
            z: 0.27147
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/cylinder_109.mesh"
            materials: [
                material_001_material
            ]

            Model {
                id: cube_457
                x: 1.97291e-05
                scale.x: 0.0520618
                scale.y: 0.0236106
                scale.z: 0.0520618
                source: "meshes/cube_457.mesh"
                materials: [
                    material_147_material
                ]
            }
        }

        Model {
            id: cylinder_110
            x: -0.0285198
            y: 0.0436425
            z: 0.566322
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/cylinder_110.mesh"
            materials: [
                material_001_material
            ]

            Model {
                id: cube_458
                x: 1.97478e-05
                scale.x: 0.0520618
                scale.y: 0.0236106
                scale.z: 0.0520618
                source: "meshes/cube_458.mesh"
                materials: [
                    material_147_material
                ]
            }
        }

        Model {
            id: cylinder_111
            x: 0.105432
            y: 0.383184
            z: -0.379383
            eulerRotation.x: 24.6994
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/cylinder_111.mesh"
            materials: [
                material_001_material
            ]

            Model {
                id: cube_459
                x: 1.9744e-05
                scale.x: 0.0520618
                scale.y: 0.0236106
                scale.z: 0.0520618
                source: "meshes/cube_459.mesh"
                materials: [
                    material_147_material
                ]
            }
        }

        Model {
            id: cylinder_112
            x: -0.205007
            y: 0.0349481
            z: 0.134744
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_112.mesh"

            PrincipledMaterial {
                id: material_149_material
                baseColor: "#ff370401"
                metalness: 0
                roughness: 0.5
                cullMode: Material.NoCulling
            }
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_113
            x: -0.540287
            y: 0.0349481
            z: -0.0531052
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_113.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_114
            x: 0.127883
            y: 0.0349481
            z: 0.546111
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_114.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_115
            x: 0.507766
            y: 0.0363864
            z: -0.0441898
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_115.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_116
            x: 0.235305
            y: 0.0457355
            z: -0.0694643
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_116.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_117
            x: 0.054161
            y: 0.0349481
            z: 0.386796
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_117.mesh"
            materials: [
                material_148_material
            ]
        }

        Model {
            id: cylinder_118
            x: -0.366712
            y: 0.0349481
            z: -0.390759
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_118.mesh"

            PrincipledMaterial {
                id: _material
                roughness: 1
            }
            materials: [
                _material
            ]
        }

        Model {
            id: cylinder_119
            x: -0.502253
            y: 0.0349481
            z: 0.196568
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_119.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_120
            x: -0.0504598
            y: 0.276749
            z: -0.172676
            eulerRotation.x: 26.5748
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_120.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_121
            x: -0.151746
            y: 0.399402
            z: -0.395255
            eulerRotation.x: 26.5748
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_121.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: cylinder_122
            x: 0.222334
            y: 0.423712
            z: -0.449798
            eulerRotation.x: 30.3956
            scale.x: 0.302443
            scale.y: 0.302443
            scale.z: 0.302443
            source: "meshes/cylinder_122.mesh"
            materials: [
                material_149_material
            ]
        }

        Model {
            id: plane_074
            x: 0.0019895
            y: -0.027926
            z: -0.05828
            eulerRotation.x: 28.9291
            eulerRotation.y: 0.478245
            eulerRotation.z: 0.264317
            scale.x: 0.362393
            scale.y: 0.362393
            scale.z: 0.362393
            source: "meshes/plane_074.mesh"
            materials: [
                material_150_material
            ]
        }

        Model {
            id: plane_075
            y: 0.00258029
            scale.x: 0.562872
            scale.y: 0.562872
            scale.z: 0.562872
            source: "meshes/plane_075.mesh"

            PrincipledMaterial {
                id: material_140_material
                baseColor: "#ffcc3f00"
                metalness: 0
                roughness: 0.25
                cullMode: Material.NoCulling
            }
            materials: [
                material_140_material
            ]
        }

        Model {
            id: plane_076
            x: 0.0019895
            y: -0.027926
            z: -0.05828
            eulerRotation.x: 28.9291
            eulerRotation.y: 0.478245
            eulerRotation.z: 0.264317
            scale.x: 0.362393
            scale.y: 0.362393
            scale.z: 0.362393
            source: "meshes/plane_076.mesh"
            materials: [
                material_140_material
            ]
        }
    }

}
