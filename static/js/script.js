import * as THREE from './three.module.js';
import Stats from './Stats.js';
//import image from "./photo-1610730260505-0b9ed7f06293.png"


var renderer, uniforms, vShader, fShader, camera, scene, acc_disk, stats, video;
var loader = new THREE.FileLoader();
init();

function init() {
    renderer = new THREE.WebGLRenderer({
    canvas: document.getElementById('canvas'),
    antialias: true,
    });
    renderer.setClearColor(0x000000);
    renderer.setSize(window.innerWidth, window.innerHeight);

    camera = new THREE.PerspectiveCamera(
    50,
    window.innerWidth/window.innerHeight,
    0.1, 
    200
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

        const constraints = { video: { width: 2000, height: 2000, facingMode: 'user' } };

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

    loader.load('./static/glsl/fragment.glsl', function ( data ) {fShader =  data; runMoreIfDone(); },);
    loader.load('./static/glsl/vertex.glsl', function ( data ) {vShader =  data; runMoreIfDone(); },);

}

function more() {
    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
        acc_disk.material.uniforms.uResolution.value = new THREE.Vector2(window.innerWidth, window.innerHeight)
    }, true)
   

    var geometry = new THREE.PlaneGeometry(2, 2);

    // VIDEO
    var texture = new THREE.VideoTexture(video);
    var nighttexture = new THREE.TextureLoader().load("./static/images/sky.png");

    uniforms = {
    textureft: {value:texture},
    texturebg: {value:nighttexture},
    uResolution: {
        value: new THREE.Vector2(window.innerWidth, window.innerHeight),
    },
    }
    var shader_material = new THREE.ShaderMaterial({
    uniforms:       uniforms,
    vertexShader:   vShader,
    fragmentShader: fShader,
    blending:       THREE.AdditiveBlendMode,
    transparent:    true
    });
    //var reflective_material = new THREE.MeshBasicMaterial(0xffffff);
    screen = new THREE.Mesh(geometry, shader_material);

    screen.position.z = -1;
    scene.add(screen);

    stats = new Stats();
    stats.showPanel( 0 ); // 0: fps, 1: ms, 2: mb, 3+: custom
    document.body.appendChild( stats.dom );


    animate();
}

function animate(){
    stats.begin();
    var d = new Date();
    renderer.render(scene, camera)
    stats.end();
    requestAnimationFrame(animate);
}




