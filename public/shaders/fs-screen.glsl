#version 300 es
precision highp float;

uniform sampler2D u_color;
uniform sampler2D u_light;
uniform sampler2D u_normal;
uniform sampler2D u_depth;

in vec2 v_texCoord;

out vec4 outColor;

void main() {

  //ivec2 fragCoord = ivec2(gl_FragCoord.xy);

  vec4 color = texture(u_color, v_texCoord);
  vec4 light = texture(u_light, v_texCoord);
  vec4 normal = texture(u_normal, v_texCoord);
  vec4 depth = texture(u_depth, v_texCoord);

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
        outColor = vec4(vec3((1. - depth.r) * 500.), 1.0);
  }

  //outColor = light * color;
  //outColor = vec4(1.0 - tex.r, 1.0 - tex.g, 1.0 - tex.b, 1.);
  //outColor = vec4(vec3(1.0) - tex.rgb, 1.0);
  //outColor = vec4(tex.rgb*3., 1.0);
}