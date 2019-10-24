import * as twgl from "./twgl/twgl-full.js";
import {m4} from "./twgl/twgl-full.js";

import { loadText } from "./util";
import { VoxBox, VoxQuad, quadsToArrays, VoxArraysData } from "./vox.js";

/*import SPECTOR from "spectorjs";
var spector = new SPECTOR.Spector();
spector.displayUI();*/

window.onload = async () => {
  const canvas = document.getElementById("c") as HTMLCanvasElement;
  const gl = canvas.getContext("webgl2");

  /*gl.getExtension('EXT_color_buffer_float');
  gl.getExtension('OES_texture_float_linear');*/

  //twgl.addExtensionsToContext(gl);

  let [vs, fs, vsScreen, fsScreen] = await Promise.all([
    loadText("./shaders/vs.glsl"),
    loadText("./shaders/fs.glsl"),
    loadText("./shaders/vs-screen.glsl"),
    loadText("./shaders/fs-screen.glsl")
  ]);

  const programInfo = twgl.createProgramInfo(gl, [vs, fs], error =>
    console.log(error)
  );

  const screenProgramInfo = twgl.createProgramInfo(
    gl,
    [vsScreen, fsScreen],
    error => console.log(error)
  );

  let va = await loadStage();

  let arrays = {
    color: { size: 1, data: Uint32Array.from(va.colors) },
    normals: va.normals,
    position: va.vertices,
    indices: va.triangles
  };

  console.log(arrays);

  let superSampling = 1;
  let bufferWH = [canvas.clientWidth * superSampling, canvas.clientHeight * superSampling];

  let depthTexture = twgl.createTexture(gl, {
    width: bufferWH[0],
    height: bufferWH[1],
    internalFormat: gl.DEPTH24_STENCIL8
  });
    
  const framebufferInfo = twgl.createFramebufferInfo(
    gl,
    [
      { internalFormat: gl.RGBA },
      { format: gl.RGBA },
      { format: gl.RGBA },
      //{ format: gl.RGBA },
      { format: gl.DEPTH_STENCIL, attachment: depthTexture }
    ],
    bufferWH[0],
    bufferWH[1]
  );

  gl.drawBuffers([
    gl.COLOR_ATTACHMENT0,
    gl.COLOR_ATTACHMENT1,
    gl.COLOR_ATTACHMENT2,
    //gl.COLOR_ATTACHMENT3
  ]);

  console.log("status", twgl.glEnumToString(gl, gl.checkFramebufferStatus(gl.FRAMEBUFFER)));

  twgl.bindFramebufferInfo(gl, null);

  const screenBufferInfo = twgl.createBufferInfoFromArrays(gl, {
    position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0]
  });

  const bufferInfo = twgl.createBufferInfoFromArrays(gl, arrays);
  
  console.log(bufferInfo);
  
  const deferredRendering = true;

  //gl.enable(gl.BLEND);
  //gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  function render(time) {
    twgl.resizeCanvasToDisplaySize(canvas);
    gl.viewport(0, 0, canvas.clientWidth, canvas.clientHeight);
    time *= 0.001;
    //time = 1;

    const fov = (50 * Math.PI) / 180;
    const aspect = canvas.clientWidth / canvas.clientHeight;
    const zNear = 0.5;
    const zFar = 800;
    const projection = m4.perspective(fov, aspect, zNear, zFar);
  
    //let eye = [1, 300, 200];

    const eye = m4.transformPoint(m4.rotateZ(m4.identity(), time), [1, 300, 200])

    const target = [0, 40, 40];
    const up = [0, 0, 1];
    const camera = m4.lookAt(eye, target, up);
    const view = m4.inverse(camera);
    const viewProjection = m4.multiply(projection, view);
    
    const world = m4.identity();
  
    const uniforms = {
      "u_light[0].pos": [0, 100, 100],
      "u_light[0].color": [1, 1, 1, 1],
      u_ambient: [0.2, 0.2, 0.2, 1],
      u_specular: [1, 1, 1, 0],
      u_shininess: 50,
      u_specularFactor: 1,
      u_viewInverse: camera,
      u_world: world,
      u_worldInverseTranspose: m4.transpose(m4.inverse(world)),
      u_worldViewProjection: viewProjection,
      u_InverseWorldViewProjection: m4.inverse(viewProjection),
      u_time: 0
    };
  
    /*console.log(projection)
    let a = [0, 0, 200]
    let b = m4.transformPoint(uniforms.u_worldViewProjection, a);
    let c = m4.transformPoint(uniforms.u_InverseWorldViewProjection, b);
    console.log(a, b, c);*/
    //console.log(m4.transformPoint(projection, [100, 100, 200]));
  
    const screenUniforms = {
      u_color: framebufferInfo.attachments[0],
      u_light_: framebufferInfo.attachments[1],
      u_normal: framebufferInfo.attachments[2],
      u_depth: framebufferInfo.attachments[3],
    };
  
    Object.assign(screenUniforms, uniforms)
  

    if (deferredRendering) twgl.bindFramebufferInfo(gl, framebufferInfo);

    uniforms.u_time = time;

    gl.clearColor(0, 0, 0, 1);
    gl.enable(gl.DEPTH_TEST);
    gl.enable(gl.CULL_FACE);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    gl.useProgram(programInfo.program);
    twgl.setBuffersAndAttributes(gl, programInfo, bufferInfo);
    twgl.setUniforms(programInfo, uniforms);

    twgl.drawBufferInfo(gl, bufferInfo);

    if (deferredRendering) {
      twgl.bindFramebufferInfo(gl, null);
      //gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      gl.useProgram(screenProgramInfo.program);
      twgl.setBuffersAndAttributes(gl, screenProgramInfo, screenBufferInfo);
      twgl.setUniforms(screenProgramInfo, screenUniforms);
      twgl.drawBufferInfo(gl, screenBufferInfo);
    }

    requestAnimationFrame(render);
  }
  requestAnimationFrame(render);
};

async function loadStage() {
  let chunks = [];
  for (let i = 0; i < 9; i++) {
    let XY = [Math.floor(i / 3) - 1, (i % 3) - 1];
    let path = "/vox/" + XY.map(n => "a01"[n + 1]).join("") + ".vox";
    let place = XY.map(n => n * 124 - 62);
    chunks.push({ path, place });
  }

  console.time("quads");
  let chunkVox = await Promise.all(
    chunks.map(chunk => new VoxBox().load(chunk.path))
  );
  console.timeEnd("quads");

  console.time("arrays");
  let quads = chunkVox
    .map((box, boxi) =>
      box.quads.map(
        quad =>
          ({
            color: quad.color,
            vertices: quad.vertices.map(([x, y, z]) => [
              x + chunks[boxi].place[0],
              y + chunks[boxi].place[1],
              z
            ])
          } as VoxQuad)
      )
    )
    .flat();
  let arrays = quadsToArrays(quads);
  console.timeEnd("arrays");

  /*let arrays = quadsToArrays(quads, (quad, [x, y, z]) => [
    x + quad.body.box.place[0],
    y + quad.body.box.place[1],
    z
  ])

  for (let i = 0; i < 9; i++)
    va.concat(chunkVox[i].arrays(), ([x, y, z]) => [
      x + chunks[i].place[0],
      y + chunks[i].place[1],
      z
    ]);*/

  return arrays;
}

addEventListener("mouseover", e => {});
