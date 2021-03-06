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

uniform mat4 u_viewInverse;

in vec4 v_position;
in vec2 v_texCoord;
in vec3 v_normal;
in vec3 v_surfaceToLight;
in vec3 v_surfaceToView;
in vec4 v_color;
in vec2 v_uv;
in vec4 v_worldPosition;

layout(location=0) out vec4 outColor;
layout(location=1) out vec4 outLight;
layout(location=2) out vec4 outNormal;

vec4 lit(float l ,float h, float m) {
  return vec4(
    1.0,
    max(l, 0.0),
    (l > 0.0) ? pow(max(0.0, h), m) : 0.0,
    1.0
  );
}

void main() {
  //vec4 diffuseColor = texture(u_diffuse, v_texCoord);
  //vec4 diffuseColor = vec4(v_color.xyz*(v_uv.x+v_uv.y), 1.0);
  vec4 diffuseColor = v_color;
  vec3 surfaceToLight = normalize((u_light[0].pos - v_worldPosition.xyz).xyz);
  vec3 surfaceToView = normalize((u_viewInverse[3] - v_worldPosition).xyz);
  vec3 halfVector = normalize(surfaceToLight + surfaceToView);
  
  vec4 litR = lit(dot(v_normal, surfaceToLight), dot(v_normal, halfVector), u_shininess);

  /*outColor = vec4(
    (u_light[0].color * (diffuseColor * litR.y + diffuseColor * u_ambient + u_specular * litR.z * u_specularFactor)).rgb, 
    diffuseColor.a
  );*/


  outLight = u_light[0].color * (dot(v_normal, halfVector) + u_ambient);

  //float depth = 1. - (1. - gl_FragCoord.z)*400.;
  //outLight = vec4(1., 0., 1., 1.);
  //outDepth = vec4(vec3((1. - gl_FragCoord.z)*500.), 1.0);

  //outDepth = vec4(vec3(depth), 1.0);

  outColor = diffuseColor;

  outNormal = vec4(v_normal, 1.);
}