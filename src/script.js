import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/Addons.js';

import mainVS from './shaders/mainVS.glsl';
import mainFS from './shaders/mainFS.glsl';

const width = window.innerWidth;
const height = window.innerHeight;

const scene = new THREE.Scene();

const camera = new THREE.PerspectiveCamera(55, width / height, 0.1, 1000);
camera.position.x = 8;
camera.position.y = 5;
camera.position.z = 8;

const renderer = new THREE.WebGLRenderer();
renderer.setSize(width, height);
renderer.setAnimationLoop(animate);
document.body.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;

const dirLight = new THREE.DirectionalLight(0xffffff, 1);
dirLight.position.set(1, 1, 0);
scene.add(dirLight);

const geometry = new THREE.PlaneGeometry();

// textures
const texLoader = new THREE.TextureLoader();
const beachBallColor = texLoader.load('images/beachBallColor.jpg', 
    tex => {
        tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    }
);
const wallColor = texLoader.load('images/poolTile.jpg', 
    tex => {
        tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    }
);

const material = new THREE.ShaderMaterial({
    defines: {
        SCENENUM: 1 // basic scene by default
    },
    uniforms: {
        camProjectionMatrixInverse: {value: camera.projectionMatrixInverse},
        camWorldMatrix: {value: camera.matrixWorld},

        lights: {value: [dirLight.position.normalize()]},
        lightsCol: {value: [dirLight.color]},

        textures: {value: [beachBallColor, wallColor]},

        time: {value: 0.0}
    },
    vertexShader: mainVS,
    fragmentShader: mainFS
});

// scene options
const scenesSelect = document.getElementById("scenes");
scenesSelect.addEventListener('change', (e) => {
    if (e.target.value == 'basic') material.defines.SCENENUM = 1;
    else if (e.target.value == 'pool') material.defines.SCENENUM = 2;

    material.needsUpdate = true;
});

const plane = new THREE.Mesh(geometry, material);
scene.add(plane);

// scale to near
const H = Math.tan((camera.fov / 2) * (Math.PI / 180)) * camera.near * 2;
const W = H * camera.aspect;
plane.scale.set(W, H, 1);

const forward = new THREE.Vector3();

function animate(time) {
    // translate to near
    camera.getWorldDirection(forward);
    forward.multiplyScalar(camera.near);
    const camPos = camera.position.clone();
    const planePos = camPos.add(forward);
    plane.position.copy(planePos);
    // rotate like near
    plane.rotation.copy(camera.rotation);

    material.uniforms.time.value = time / 1000;

    renderer.render(scene, camera);
    controls.update();
}
