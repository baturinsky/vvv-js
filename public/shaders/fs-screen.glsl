#version 300 es
precision highp float;

struct Light{
  vec3 pos;
  vec4 color;
};

uniform Light u_light[1];
uniform vec4 u_ambient;
uniform sampler2D u_diffuse;
uniform vec4 u_specular;
uniform float u_shininess;
uniform float u_specularFactor;
uniform mat4 u_InverseWorldViewProjection;

uniform sampler2D u_color;
uniform sampler2D u_light_;
uniform sampler2D u_normal;
uniform sampler2D u_depth;

in vec2 v_texCoord;

out vec4 outColor;

void main() {

  //ivec2 fragCoord = ivec2(gl_FragCoord.xy);

  vec4 color = texture(u_color, v_texCoord);
  vec4 light = texture(u_light_, v_texCoord);
  vec4 normal = texture(u_normal, v_texCoord);
  vec4 depth = texture(u_depth, v_texCoord);
  //vec4 depth2 = texture(u_depth, v_texCoord + vec2(0,0.01));

  vec4 p1 = vec4(v_texCoord*2. - 1., depth.r * 2. - 1., 1.);
  vec4 p2 = u_InverseWorldViewProjection * p1;

  if(length(vec2(v_texCoord.x-0.5,v_texCoord.y-0.5)) < 0.2)
    outColor = light * color;  
  else {
    if(v_texCoord.x<0.5)
      if(v_texCoord.y>0.5)
        outColor = normal;
      else
        outColor = light;
    else
      if(v_texCoord.y>0.5)
        outColor = color;
      else
        outColor = vec4(vec3(p2.z), 1.0);
        //outColor = vec4(p2.x/50. - 50., p2.y/50. - 50., p2.z - 199., 1.0);
        //outColor = vec4(vec3(depth.r<1.?(1. - (1. - depth.r) * 600.):0.), 1.0);
        //outColor = vec4(vec3(depth.r/10.), 1.0);
  }

  outColor = vec4(p2.xyz, 1.0);
  //outColor = vec4(vec3(p2.z)*2., 1.0);
  /*if(v_texCoord.x<0.5)
    outColor = vec4(vec3(p2.z), 1.0);
  else
    outColor = vec4(vec3(depth.r<1.?((1. - depth.r) * 300.):0.), 1.0);*/

  //outColor = vec4(1., 0., 0., 1.);

  //outColor = light * color;
  //outColor = vec4(1.0 - tex.r, 1.0 - tex.g, 1.0 - tex.b, 1.);
  //outColor = vec4(vec3(1.0) - tex.rgb, 1.0);
  //outColor = vec4(tex.rgb*3., 1.0);
  //outColor = vec4(vec3((- depth.r + depth2.r) * 2000.), 1.0);
}