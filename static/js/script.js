import * as THREE from './three.module.js';
import Stats from './Stats.js';
//import image from "./photo-1610730260505-0b9ed7f06293.png"


var renderer, uniforms, vShader, fShader, camera, scene, acc_disk, stats, video, video1;
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
    video1 = document.getElementById("video1");
    async function getCameraDevices() {
        navigator.mediaDevices.getUserMedia({video: true}).then(stream => {console.log(stream)});

        let devices = await navigator.mediaDevices.enumerateDevices();
        let videodevices = [];
        for (let device of devices) {
            if (device.kind === 'videoinput') {
                videodevices.push(device);
            }
        }
        //return videodevices;
    

        if ( navigator.mediaDevices && navigator.mediaDevices.getUserMedia ) {

            const constraints = { 
                video: { deviceId: {exact: videodevices[0].deviceId}, width: 2000, height: 2000},
            };//, facingMode: 'user' } };
            const constraints1 = { 
                video: { deviceId: {exact: videodevices[1].deviceId}, width: 2000, height: 2000},
            };//, facingMode: 'user' } };



            navigator.mediaDevices.getUserMedia( constraints ).then( function ( stream ) {

                // apply the stream to the video element used in the texture

                video.srcObject = stream;
                video.play();


            } ).catch( function ( error ) {

                console.error( 'Unable to access the camera/webcam.', error );

            } );
            navigator.mediaDevices.getUserMedia( constraints1 ).then( function ( stream ) {

                // apply the stream to the video element used in the texture

                video1.srcObject = stream;
                video1.play();


            } ).catch( function ( error ) {

                console.error( 'Unable to access the camera/webcam.', error );

            } );


        } else {

            console.error( 'MediaDevices interface not available.' );

        }
    };
    const videodevices = getCameraDevices();


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
    var nighttexture = new THREE.VideoTexture(video1);//new THREE.TextureLoader().load("./static/images/sky.png");

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
    acc_disk = new THREE.Mesh(geometry, shader_material);

    acc_disk.position.z = -1;
    scene.add(acc_disk);

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




