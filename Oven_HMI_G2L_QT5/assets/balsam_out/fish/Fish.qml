import QtQuick 2.15
import QtQuick3D 1.15

Node {
    id: rOOT

    Model {
        id: circle
        y: -0.0991966
        eulerRotation.x: 36.5715
        eulerRotation.y: 10.8277
        eulerRotation.z: 3.22819
        scale.x: 1.94712
        scale.y: 0.669174
        scale.z: 1.51843
        source: "meshes/circle.mesh"

        PrincipledMaterial {
            id: material_002_material
            baseColor: "#ff000000"
            metalness: 0
            roughness: 0.269318
            cullMode: Material.NoCulling
        }
        materials: [
            material_002_material
        ]
    }

    Model {
        id: cube_071
        x: 0.0207218
        y: 0.123111
        z: 0.159525
        eulerRotation.x: 53.7701
        eulerRotation.y: -10.7
        eulerRotation.z: -178.601
        scale.x: 0.48907
        scale.y: 0.39029
        scale.z: 0.365416
        source: "meshes/cube_071.mesh"

        PrincipledMaterial {
            id: material_015_material
            metalness: 0.359091
            roughness: 0.354545
            cullMode: Material.NoCulling
        }
        materials: [
            material_015_material
        ]
    }

    Model {
        id: sphere_026
        x: 1.75648
        y: 0.0339939
        z: -0.262755
        eulerRotation.x: 53.7701
        eulerRotation.y: -10.7
        eulerRotation.z: -178.601
        scale.x: 0.149049
        scale.y: 0.133403
        scale.z: 0.135247
        source: "meshes/sphere_026.mesh"

        PrincipledMaterial {
            id: _material
            roughness: 1
        }
        materials: [
            _material
        ]
    }

    Model {
        id: sphere_027
        x: 1.78846
        y: 0.321486
        z: -0.0563989
        eulerRotation.x: 143.77
        eulerRotation.y: -10.7
        eulerRotation.z: -178.601
        scale.x: 0.149581
        scale.y: 0.111762
        scale.z: 0.119369
        source: "meshes/sphere_027.mesh"
        materials: [
            material_002_material
        ]
    }

    Model {
        id: cube_072
        x: 1.45517
        y: -0.626083
        z: 0.703469
        eulerRotation.x: 38.2273
        eulerRotation.y: -48.1684
        eulerRotation.z: -20.2975
        scale.x: 0.387916
        scale.y: 0.166507
        scale.z: 0.303682
        source: "meshes/cube_072.mesh"

        PrincipledMaterial {
            id: material_009_material
            baseColor: "#ff0ec814"
            metalness: 0
            roughness: 0.457244
            cullMode: Material.NoCulling
        }
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_073
        x: 0.894722
        y: -0.723213
        z: 0.948657
        eulerRotation.x: 50.5908
        eulerRotation.y: -60.5942
        eulerRotation.z: -46.8326
        scale.x: 0.419758
        scale.y: 0.180175
        scale.z: 0.32861
        source: "meshes/cube_073.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_074
        x: 0.218746
        y: -0.846351
        z: 1.14942
        eulerRotation.x: 77.6919
        eulerRotation.y: -68.2665
        eulerRotation.z: -80.0387
        scale.x: 0.464822
        scale.y: 0.199517
        scale.z: 0.363888
        source: "meshes/cube_074.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cylinder_014
        x: -1.63613
        y: 0.370409
        z: -0.463183
        eulerRotation.x: 44.132
        eulerRotation.y: -29.4265
        eulerRotation.z: -39.4693
        scale.x: 0.561489
        scale.y: 0.517361
        scale.z: 0.561489
        source: "meshes/cylinder_014.mesh"

        PrincipledMaterial {
            id: material_010_material
            baseColor: "#ffcc0000"
            metalness: 0
            roughness: 0.5
            cullMode: Material.NoCulling
        }
        materials: [
            material_010_material
        ]
    }

    Model {
        id: cylinder_015
        x: -0.904339
        y: 0.597717
        z: -0.692776
        eulerRotation.x: 44.3414
        eulerRotation.y: -31.7666
        eulerRotation.z: -47.437
        scale.x: 0.561489
        scale.y: 0.517361
        scale.z: 0.561489
        source: "meshes/cylinder_015.mesh"
        materials: [
            material_010_material
        ]
    }

    Model {
        id: cylinder_016
        x: -0.865914
        y: -0.709889
        z: 1.10856
        eulerRotation.x: 27.5794
        eulerRotation.y: 8.93208
        eulerRotation.z: -5.33454
        scale.x: 0.561489
        scale.y: 0.517361
        scale.z: 0.561489
        source: "meshes/cylinder_016.mesh"
        materials: [
            material_010_material
        ]
    }

    Model {
        id: cylinder_017
        x: -1.48096
        y: -0.453064
        z: 1.3221
        eulerRotation.x: 21.6514
        eulerRotation.y: 2.02493
        eulerRotation.z: -6.99809
        scale.x: 0.471935
        scale.y: 0.434845
        scale.z: 0.471935
        source: "meshes/cylinder_017.mesh"
        materials: [
            material_010_material
        ]
    }

    Model {
        id: torus_003
        x: 1.25028
        y: 0.594425
        z: -0.925665
        eulerRotation.x: 53.5614
        eulerRotation.y: -4.09375
        eulerRotation.z: -2.83557
        scale.x: 0.714847
        scale.y: 0.467419
        scale.z: 0.714847
        source: "meshes/torus_003.mesh"

        PrincipledMaterial {
            id: material_018_material
            baseColor: "#ffcc5059"
            metalness: 0
            roughness: 0.263636
            cullMode: Material.NoCulling
        }
        materials: [
            material_018_material
        ]
    }

    Model {
        id: torus_004
        x: 0.508804
        y: 0.763256
        z: -0.848754
        eulerRotation.x: 54.5728
        eulerRotation.y: -6.45838
        eulerRotation.z: 5.14162
        scale.x: 0.674804
        scale.y: 0.441236
        scale.z: 0.674804
        source: "meshes/torus_004.mesh"
        materials: [
            material_018_material
        ]
    }

    Model {
        id: cube_075
        x: -1.53794
        y: 0.165477
        z: 0.578015
        eulerRotation.x: 131.867
        eulerRotation.y: 15.3177
        eulerRotation.z: 177.394
        scale.x: 0.0957408
        scale.y: 0.0410952
        scale.z: 0.074951
        source: "meshes/cube_075.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_076
        x: -0.757093
        y: 0.368749
        z: 0.56814
        eulerRotation.x: 129.932
        eulerRotation.y: 40.5307
        eulerRotation.z: 153.353
        scale.x: 0.0744917
        scale.y: 0.0319744
        scale.z: 0.0583161
        source: "meshes/cube_076.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_077
        x: 0.538991
        y: 0.390993
        z: 0.524194
        eulerRotation.x: 66.4521
        eulerRotation.y: 40.0342
        eulerRotation.z: 39.0237
        scale.x: 0.0744917
        scale.y: 0.0319744
        scale.z: 0.0583161
        source: "meshes/cube_077.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_078
        x: 0.0175937
        y: 0.655211
        z: -0.174558
        eulerRotation.x: 150.433
        eulerRotation.y: 16.0142
        eulerRotation.z: 174.666
        scale.x: 0.0744917
        scale.y: 0.0319744
        scale.z: 0.0583161
        source: "meshes/cube_078.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_079
        x: 1.35654
        y: 0.526183
        z: -0.16607
        eulerRotation.x: 38.8045
        eulerRotation.y: -8.42169
        eulerRotation.z: -13.3671
        scale.x: 0.0744917
        scale.y: 0.0319744
        scale.z: 0.0583161
        source: "meshes/cube_079.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_080
        x: -0.0196132
        y: -0.15166
        z: 1.05954
        eulerRotation.x: 119.579
        eulerRotation.y: 38.3196
        eulerRotation.z: 148.948
        scale.x: 0.0646585
        scale.y: 0.0277537
        scale.z: 0.0506182
        source: "meshes/cube_080.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_081
        x: 1.06837
        y: 0.12398
        z: 0.64266
        eulerRotation.x: 75.902
        eulerRotation.y: 37.7183
        eulerRotation.z: 41.7757
        scale.x: 0.0646586
        scale.y: 0.0277537
        scale.z: 0.0506182
        source: "meshes/cube_081.mesh"
        materials: [
            material_009_material
        ]
    }

    Model {
        id: cube_082
        x: -0.123893
        y: 0.523939
        z: 0.579943
        eulerRotation.x: 149.399
        eulerRotation.y: 31.9197
        eulerRotation.z: 150.261
        scale.x: 0.0531793
        scale.y: 0.0228264
        scale.z: 0.0416316
        source: "meshes/cube_082.mesh"
        materials: [
            material_009_material
        ]
    }
}
