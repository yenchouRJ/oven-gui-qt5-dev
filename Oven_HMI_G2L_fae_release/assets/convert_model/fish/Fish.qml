import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    PrincipledMaterial {
        id: material_018_material
        objectName: "Material.018"
        baseColor: "#ffe7989f"
        roughness: 0.26363635063171387
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: material_010_material
        objectName: "Material.010"
        baseColor: "#ffe70000"
        roughness: 0.5
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: material_009_material
        objectName: "Material.009"
        baseColor: "#ff43e54e"
        roughness: 0.457244336605072
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: principledMaterial
        metalness: 1
        roughness: 1
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: material_015_material
        objectName: "Material.015"
        metalness: 0.3590908944606781
        roughness: 0.3545454740524292
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }
    PrincipledMaterial {
        id: material_002_material
        objectName: "Material.002"
        baseColor: "#ff000000"
        roughness: 0.26931819319725037
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1.4500000476837158
    }

    // Nodes:
    Node {
        id: root
        objectName: "ROOT"
        Model {
            id: circle
            objectName: "Circle"
            position: Qt.vector3d(0, -0.0991966, 0)
            rotation: Qt.quaternion(0.945727, 0.30971, 0.0983476, -0.00296507)
            scale: Qt.vector3d(1.94712, 0.669174, 1.51843)
            source: "meshes/mesh_mesh.mesh"
            materials: [
                material_002_material
            ]
        }
        Model {
            id: cube_071
            objectName: "Cube.071"
            position: Qt.vector3d(0.0207218, 0.123111, 0.159525)
            rotation: Qt.quaternion(-0.0530011, 0.0776595, 0.451214, 0.887449)
            scale: Qt.vector3d(0.48907, 0.39029, 0.365416)
            source: "meshes/mesh_mesh6.mesh"
            materials: [
                material_015_material
            ]
        }
        Model {
            id: sphere_026
            objectName: "Sphere.026"
            position: Qt.vector3d(1.75648, 0.0339939, -0.262755)
            rotation: Qt.quaternion(-0.053001, 0.0776594, 0.451214, 0.887449)
            scale: Qt.vector3d(0.149049, 0.133403, 0.135247)
            source: "meshes/sphere_026_mesh.mesh"
            materials: [
                principledMaterial
            ]
        }
        Model {
            id: sphere_027
            objectName: "Sphere.027"
            position: Qt.vector3d(1.78846, 0.321486, -0.0563989)
            rotation: Qt.quaternion(-0.0923909, 0.0174361, 0.946578, 0.308465)
            scale: Qt.vector3d(0.149581, 0.111762, 0.119369)
            source: "meshes/sphere_027_mesh.mesh"
            materials: [
                material_002_material
            ]
        }
        Model {
            id: cube_072
            objectName: "Cube.072"
            position: Qt.vector3d(1.45517, -0.626083, 0.703469)
            rotation: Qt.quaternion(0.872665, 0.22632, -0.432223, -0.0204649)
            scale: Qt.vector3d(0.387916, 0.166507, 0.303682)
            source: "meshes/mesh_mesh14.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_073
            objectName: "Cube.073"
            position: Qt.vector3d(0.894722, -0.723213, 0.948657)
            rotation: Qt.quaternion(0.802007, 0.15728, -0.565163, -0.112425)
            scale: Qt.vector3d(0.419758, 0.180175, 0.32861)
            source: "meshes/mesh_mesh17.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_074
            objectName: "Cube.074"
            position: Qt.vector3d(0.218746, -0.846351, 1.14942)
            rotation: Qt.quaternion(0.720025, 0.116578, -0.668538, -0.145019)
            scale: Qt.vector3d(0.464822, 0.199517, 0.363888)
            source: "meshes/mesh_mesh19.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cylinder_014
            objectName: "Cylinder.014"
            position: Qt.vector3d(-1.63613, 0.370409, -0.463183)
            rotation: Qt.quaternion(0.875934, 0.262536, -0.344246, -0.212859)
            scale: Qt.vector3d(0.561489, 0.517361, 0.561489)
            source: "meshes/mesh_mesh21.mesh"
            materials: [
                material_010_material
            ]
        }
        Model {
            id: cylinder_015
            objectName: "Cylinder.015"
            position: Qt.vector3d(-0.904339, 0.597717, -0.692776)
            rotation: Qt.quaternion(0.857015, 0.230355, -0.378035, -0.263728)
            scale: Qt.vector3d(0.561489, 0.517361, 0.561489)
            source: "meshes/mesh_mesh24.mesh"
            materials: [
                material_010_material
            ]
        }
        Model {
            id: cylinder_016
            objectName: "Cylinder.016"
            position: Qt.vector3d(-0.865914, -0.709889, 1.10856)
            rotation: Qt.quaternion(0.966316, 0.240897, 0.0644834, -0.0635978)
            scale: Qt.vector3d(0.561489, 0.517361, 0.561489)
            source: "meshes/mesh_mesh26.mesh"
            materials: [
                material_010_material
            ]
        }
        Model {
            id: cylinder_017
            objectName: "Cylinder.017"
            position: Qt.vector3d(-1.48096, -0.453064, 1.3221)
            rotation: Qt.quaternion(0.980017, 0.188502, 0.00586176, -0.063249)
            scale: Qt.vector3d(0.471935, 0.434845, 0.471935)
            source: "meshes/mesh_mesh28.mesh"
            materials: [
                material_010_material
            ]
        }
        Model {
            id: torus_003
            objectName: "Torus.003"
            position: Qt.vector3d(1.25028, 0.594425, -0.925665)
            rotation: Qt.quaternion(0.892293, 0.449363, -0.0430175, -0.00598606)
            scale: Qt.vector3d(0.714847, 0.467419, 0.714847)
            source: "meshes/mesh_mesh30.mesh"
            materials: [
                material_018_material
            ]
        }
        Model {
            id: torus_004
            objectName: "Torus.004"
            position: Qt.vector3d(0.508804, 0.763256, -0.848754)
            rotation: Qt.quaternion(0.885264, 0.459496, -0.0294815, 0.0655976)
            scale: Qt.vector3d(0.674804, 0.441236, 0.674804)
            source: "meshes/mesh_mesh33.mesh"
            materials: [
                material_018_material
            ]
        }
        Model {
            id: cube_075
            objectName: "Cube.075"
            position: Qt.vector3d(-1.53794, 0.165477, 0.578015)
            rotation: Qt.quaternion(0.130847, -0.0337599, 0.90593, 0.401286)
            scale: Qt.vector3d(0.0957408, 0.0410952, 0.074951)
            source: "meshes/mesh_mesh35.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_076
            objectName: "Cube.076"
            position: Qt.vector3d(-0.757093, 0.368749, 0.56814)
            rotation: Qt.quaternion(0.396861, 0.0532485, 0.86087, 0.313958)
            scale: Qt.vector3d(0.0744917, 0.0319744, 0.0583161)
            source: "meshes/mesh_mesh37.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_077
            objectName: "Cube.077"
            position: Qt.vector3d(0.538991, 0.390993, 0.524194)
            rotation: Qt.quaternion(0.803491, 0.389639, 0.441854, 0.0857292)
            scale: Qt.vector3d(0.0744917, 0.0319744, 0.0583161)
            source: "meshes/mesh_mesh39.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_078
            objectName: "Cube.078"
            position: Qt.vector3d(0.0175937, 0.655211, -0.174558)
            rotation: Qt.quaternion(0.146296, 0.00904397, 0.958088, 0.246136)
            scale: Qt.vector3d(0.0744917, 0.0319744, 0.0583161)
            source: "meshes/mesh_mesh41.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_079
            objectName: "Cube.079"
            position: Qt.vector3d(1.35654, 0.526183, -0.16607)
            rotation: Qt.quaternion(0.93711, 0.320989, -0.107345, -0.0852533)
            scale: Qt.vector3d(0.0744917, 0.0319744, 0.0583161)
            source: "meshes/mesh_mesh43.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_080
            objectName: "Cube.080"
            position: Qt.vector3d(-0.0196132, -0.15166, 1.05954)
            rotation: Qt.quaternion(0.400506, 0.0593893, 0.830732, 0.382038)
            scale: Qt.vector3d(0.0646585, 0.0277537, 0.0506182)
            source: "meshes/mesh_mesh45.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_081
            objectName: "Cube.081"
            position: Qt.vector3d(1.06837, 0.12398, 0.64266)
            rotation: Qt.quaternion(0.768041, 0.452847, 0.445634, 0.0803258)
            scale: Qt.vector3d(0.0646586, 0.0277537, 0.0506182)
            source: "meshes/mesh_mesh47.mesh"
            materials: [
                material_009_material
            ]
        }
        Model {
            id: cube_082
            objectName: "Cube.082"
            position: Qt.vector3d(-0.123893, 0.523939, 0.579943)
            rotation: Qt.quaternion(0.321443, 0.167856, 0.914941, 0.177152)
            scale: Qt.vector3d(0.0531793, 0.0228264, 0.0416316)
            source: "meshes/mesh_mesh49.mesh"
            materials: [
                material_009_material
            ]
        }
    }

    // Animations:
}
