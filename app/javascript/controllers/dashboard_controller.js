import { Controller } from "@hotwired/stimulus"
import * as THREE from 'three'
import { GLTFLoader } from 'three/gltf';

const scene = new THREE.Scene();
scene.background = new THREE.Color( 0xffffff );

const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
);

const renderer = new THREE.WebGLRenderer();
renderer.setSize(window.innerWidth, window.innerHeight);

const ambientLight = new THREE.AmbientLight( 0xffffff, 1 );
ambientLight.position.set( 10, 0, 10 );
scene.add( ambientLight );

const dirLight = new THREE.DirectionalLight( 0xefefff, 0.5 );
dirLight.position.set( 10, 0, 10 );
scene.add( dirLight );

camera.position.y = 2.5;
camera.position.z = 3.6;

const clock = new THREE.Clock();
let mixer = new THREE.AnimationMixer();
let activeAction;
let modelReady = false
let clips;

const arr_animation = ["idle"];

window.addEventListener('resize', onWindowResize, false)
function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize(window.innerWidth, window.innerHeight)
    renderer.render( scene, camera );
}

export default class extends Controller {
  static targets = ["params"]

  connect() {
    if (this.paramsTarget.dataset.info){

      let mic = document.getElementById("mic");
      mic.disabled = true;
      document.body.appendChild(renderer.domElement);

      const first_login = parseInt(this.paramsTarget.dataset.info);

      if (first_login > 0){
        let random_prompt = Math.floor(Math.random() * 5) + 1;
        this.play_init_prompt("greeting"+random_prompt);
      }else {
        this.play_init_prompt("welcome");
      }

    }
  }

  play_init_prompt(prompt){
    let audio = document.createElement("audio");
    audio.src = "/prompts/"+prompt+".wav";
    audio.autoplay = true;
    let playAudio = audio.play();

    if (playAudio !== undefined) {
      playAudio
        .then(() => {
          this.load_character("character2", "stand_greeting");
          audio.addEventListener("ended", function() {
            document.getElementById("set-ai-default").click();
            let mic = document.getElementById("mic");
            mic.disabled = false;
          });
        })
        .catch((error) => {
          if (error.name === "NotAllowedError") {
            let randomIndex = Math.floor(Math.random() * arr_animation.length);
            let rand_animation = arr_animation[randomIndex];
            this.load_character("character1", rand_animation);
          } else {
            let randomIndex = Math.floor(Math.random() * arr_animation.length);
            let rand_animation = arr_animation[randomIndex];
            this.load_character("character1", rand_animation);
          }
          document.getElementById("set-ai-default").click();
          let mic = document.getElementById("mic");
          mic.disabled = false;
        });
    }
    
  }

  thinking(){
    this.load_character("character1", "thinking");
  }

  stop_and_talk(){
    // let random_num = Math.floor(Math.random() * 2) + 1;
    // let talking = "talking"+random_num;
    let talking = "talking1"
    this.load_character("character2", talking);
  }

  default(){
    let randomIndex = Math.floor(Math.random() * arr_animation.length);
    let rand_animation = arr_animation[randomIndex];
    this.load_character("character1", rand_animation);
  }

  load_character(character, animate){
    const loader = new GLTFLoader();
    loader.load(
        '/characters/'+character+'.glb',
        (gltf) => {
            
            mixer = new THREE.AnimationMixer(gltf.scene);
            clips = gltf.animations;
            // let clips = gltf.animations;

            let clip = THREE.AnimationClip.findByName( clips, animate );
            let action = mixer.clipAction( clip );
            modelReady = true
            if (typeof activeAction !== "undefined"){
              this.reset_action();
            }

            activeAction = action;
            activeAction.fadeIn( 0.5 )
            .play();

            this.originModel = gltf.scene;
            scene.add( gltf.scene );
        },
        (xhr) => {
            // console.log((xhr.loaded / xhr.total) * 100 + '% loaded')
        },
        (error) => {
            console.log(error)
        }
    )

    this.animate();
  }

  animate() {
    requestAnimationFrame( this.animate.bind(this) );
      // this.originModel.rotation.x += 0.01;
      // this.originModel.rotation.y += 0.01;
    // controls.update()
    let delta = clock.getDelta();
    if ( modelReady ) mixer.update( delta );
    
    renderer.render( scene, camera );
  }

  reset_action(){
    const old_action = activeAction;
    old_action.fadeOut(0.5);
    scene.remove(old_action.getRoot());
  }
}
