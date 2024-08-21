import * as THREE from '../node_modules/three/build/three.module.js';
import Stats from '../node_modules/stats-js/src/Stats.js';

var renderer, uniforms, vShader, fShader, camera, scene, screen, stats, video;
var loader = new THREE.FileLoader();
init();

function init() {
    renderer = new THREE.WebGLRenderer({
    canvas: document.getElementById('canvas'),
    antialias: true,
    });
    renderer.setClearColor(0x000000);
    renderer.setSize(800, 800);

    camera = new THREE.PerspectiveCamera(
    40,
    800 / 800,
    0.1, 
    20000
    );

    scene = new THREE.Scene();

    var numFilesLeft = 2;

    function runMoreIfDone() {
        --numFilesLeft;
        if (numFilesLeft == 0) {
            more();
        }
    }
    video = document.getElementById("video");
    if ( navigator.mediaDevices && navigator.mediaDevices.getUserMedia ) {

        const constraints = { video: { width: 1280, height: 720, facingMode: 'user' } };

        navigator.mediaDevices.getUserMedia( constraints ).then( function ( stream ) {

            // apply the stream to the video element used in the texture

            video.srcObject = stream;
            video.play();

        } ).catch( function ( error ) {

            console.error( 'Unable to access the camera/webcam.', error );

        } );

    } else {

        console.error( 'MediaDevices interface not available.' );

    }

    loader.load('../src/fragment.glsl', function ( data ) {fShader =  data; runMoreIfDone(); },);
    loader.load('../src/vertex.glsl', function ( data ) {vShader =  data; runMoreIfDone(); },);

}

function more() {
    var geometry = new THREE.PlaneGeometry(2, 2);

    // VIDEO
    
    var texture2 = new THREE.VideoTexture(video);
    var texture1 = new THREE.TextureLoader().load('../public/images/clouds.jpeg')

    uniforms = {
    texture1:  {value:texture1},
    textureft: {value:texture2},
    uResolution: {
        value: new THREE.Vector2(800, 800),
    },
    }
    var shader_material = new THREE.ShaderMaterial({
    uniforms:       uniforms,
    vertexShader:   vShader,
    fragmentShader: fShader,
    blending:       THREE.AdditiveBlendMode,
    transparent:    true
    });
    screen = new THREE.Mesh(geometry, shader_material);

    screen.position.z = -1;
    scene.add(screen);

    stats = new Stats();
    stats.showPanel( 1 ); // 0: fps, 1: ms, 2: mb, 3+: custom
    document.body.appendChild( stats.dom );

    animate();
}

function animate(){
    stats.begin();
    renderer.render(scene, camera)
    stats.end();
    requestAnimationFrame(animate);
}



