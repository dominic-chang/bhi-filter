import * as THREE from '../node_modules/three/build/three.module.js';
import Stats from '../node_modules/stats-js/src/Stats.js';

var renderer, uniforms, vShader, fShader, vSkyShader, fSkyShader, camera, scene, acc_disk, skyboxGeo, skyBox, theta, stats, video;
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

    var numFilesLeft = 4;

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
    loader.load('../src/skyfragment.glsl', function ( data ) {fSkyShader =  data; runMoreIfDone(); },);
    loader.load('../src/skyvertex.glsl', function ( data ) {vSkyShader =  data; runMoreIfDone(); },);

}

function more() {
    var geometry = new THREE.PlaneGeometry(2, 2);

    //var texture = new THREE.TextureLoader().load('static/space.png')
    //var texture = new THREE.TextureLoader().load('https://upload.wikimedia.org/wikipedia/commons/d/d3/Albert_Einstein_Head.jpg')//.load('space.png')
    //var texture = new THREE.TextureLoader().load('https://images.theconversation.com/files/393213/original/file-20210401-13-1w9xb24.jpg?ixlib=rb-1.1.0&q=30&auto=format&w=600&h=400&fit=crop&dpr=2')//https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/The_Event_Horizon_Telescope_and_Global_mm-VLBI_Array_on_the_Earth.jpg/1920px-The_Event_Horizon_Telescope_and_Global_mm-VLBI_Array_on_the_Earth.jpg')//.load('space.png')

    // VIDEO
    
    var texture2 = new THREE.VideoTexture(video);
    //var texture2 = new THREE.TextureLoader().load('../public/images/eso0932a.png')//.load('space.png')
    //var texture1 = new THREE.TextureLoader().load('https://cdn.vox-cdn.com/thumbor/nPHkBUDla9JcRJWRdswdAETz4MU=/0x0:1960x2000/1820x1213/filters:focal(686x574:998x886):format(webp)/cdn.vox-cdn.com/uploads/chorus_image/image/71122307/STScI_01G7PWWPY7XRR9PW95W9W8ZYZW.0.png')
    var texture1 = new THREE.TextureLoader().load('../public/images/clouds.jpeg')
    //var texture2 = new THREE.TextureLoader().load('https://cdn-icons-png.flaticon.com/512/25/25435.png')

    //const ft = new THREE.TextureLoader().load("../public/images/ulukai/corona_ft.png");
    //const ft = new THREE.TextureLoader().load("https://upload.wikimedia.org/wikipedia/commons/3/34/Gnomonic_projection_SW.jpg")
    //const ft = new THREE.TextureLoader().load("https://tomassobekphotography.co.nz/photos/_data/i/upload/2018/08/15/20180815085151-4d7b709e-me.jpg")
    const ft = new THREE.TextureLoader().load("../public/images/milkyway.jpg")
    const bk = new THREE.TextureLoader().load("../public/images/ulukai/corona_bk.png");
    const up = new THREE.TextureLoader().load("../public/images/ulukai/corona_up.png");
    const dn = new THREE.TextureLoader().load("../public/images/ulukai/corona_dn.png");
    const rt = new THREE.TextureLoader().load("../public/images/ulukai/corona_rt.png");
    const lf = new THREE.TextureLoader().load("../public/images/ulukai/corona_lf.png");


    uniforms = {
    theta :    {value: 0},
    texture1:  {value:texture1},
    textureft: {value:texture2},
    texturebk: {value:bk},
    textureup: {value:up},
    texturedn: {value:dn},
    texturert: {value:rt},
    texturelf: {value:lf},
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
    var reflective_material = new THREE.MeshBasicMaterial(0xffffff);
    acc_disk = new THREE.Mesh(geometry, shader_material);

    acc_disk.position.z = -1;
    scene.add(acc_disk);


    
    const texture_arr = [ft, bk, up, dn, rt, lf]
    //const materialArray = texture_arr.map(texture => {return new THREE.MeshBasicMaterial({ map: texture, side: THREE.BackSide })})

    //skyboxGeo = new THREE.BoxGeometry(10000, 10000, 10000);
    //skyBox = new THREE.Mesh(skyboxGeo, materialArray);
    ////skyBox.position.set(1200, -250, -20000);
    //scene.add(skyBox);
    //var skygeometry = new THREE.SphereGeometry(1000, 60, 40);  
    //var skyuniforms = {  
    //    texture1: { type: 't', value: new THREE.TextureLoader().load('https://cdn.eso.org/images/screen/eso0932a.jpg') }
    //};
    //var skyMaterial = new THREE.ShaderMaterial( {  
    //    uniforms:       skyuniforms,
    //    vertexShader:   vSkyShader,
    //    fragmentShader: fSkyShader,
    //    side:           THREE.BackSide
    //    //blending:       THREE.AdditiveBlendMode,
    //    //transparent:    true

    //});

    //skyBox = new THREE.Mesh(skygeometry, skyMaterial);  
    //skyBox.scale.set(-1, 1, 1);  
    ////skyBox.position.set(0, 0, -20);
    //skyBox.eulerOrder = 'XZY';  
    ////skyBox.renderDepth = 1000.0;  
    //scene.add(skyBox);  


    theta = 85*Math.PI/180;
    stats = new Stats();
    stats.showPanel( 1 ); // 0: fps, 1: ms, 2: mb, 3+: custom
    document.body.appendChild( stats.dom );


    animate();
}

function animate(){
    stats.begin();
    var d = new Date();
    theta = d.getTime()/5000 % 2*Math.PI
    if (Math.abs(theta - Math.PI/2.) < 0.005 || Math.abs(theta - 3.*Math.PI/2.) < 0.005){
        theta += 0.01;
    }
    //skyBox.rotation.x = 2*Math.PI-theta;
    //acc_disk.material.uniforms.theta.value = theta;//  + 3.14 * (Math.abs(Math.sin(theta)))/2.;
    renderer.render(scene, camera)
    stats.end();
    requestAnimationFrame(animate);
}



