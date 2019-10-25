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
uniform vec2 u_viewportSize;

uniform sampler2D u_color;
uniform sampler2D u_light_;
uniform sampler2D u_normal;
uniform sampler2D u_depth;

in vec2 v_texCoord;

out vec4 outColor;

#define FXAA_REDUCE_MIN   (1.0/ 128.0)
#define FXAA_REDUCE_MUL   (1.0 / 8.0)
#define FXAA_SPAN_MAX     8.0

vec4 applyFXAA(vec2 fragCoord, sampler2D tex, vec2 u_viewportSize)
{
    vec4 color;
    vec2 inverseVP = vec2(1.0 / u_viewportSize.x, 1.0 / u_viewportSize.y);
    vec3 rgbNW = texture(tex, (fragCoord + vec2(-1.0, -1.0)) * inverseVP).xyz;
    vec3 rgbNE = texture(tex, (fragCoord + vec2(1.0, -1.0)) * inverseVP).xyz;
    vec3 rgbSW = texture(tex, (fragCoord + vec2(-1.0, 1.0)) * inverseVP).xyz;
    vec3 rgbSE = texture(tex, (fragCoord + vec2(1.0, 1.0)) * inverseVP).xyz;
    vec3 rgbM  = texture(tex, fragCoord  * inverseVP).xyz;
    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
    
    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
    
    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                          (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
              max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
              dir * rcpDirMin)) * inverseVP;
      
    vec3 rgbA = 0.5 * (
        texture(tex, fragCoord * inverseVP + dir * (1.0 / 3.0 - 0.5)).xyz +
        texture(tex, fragCoord * inverseVP + dir * (2.0 / 3.0 - 0.5)).xyz);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture(tex, fragCoord * inverseVP + dir * -0.5).xyz +
        texture(tex, fragCoord * inverseVP + dir * 0.5).xyz);

    float lumaB = dot(rgbB, luma);
    if ((lumaB < lumaMin) || (lumaB > lumaMax))
        color = vec4(rgbA, 1.0);
    else
        color = vec4(rgbB, 1.0);
    return color;
}

void main() {

  //ivec2 fragCoord = ivec2(gl_FragCoord.xy);

  vec4 color = texture(u_color, v_texCoord);
  vec4 light = texture(u_light_, v_texCoord);
  vec4 normal = texture(u_normal, v_texCoord);
  vec4 depth = texture(u_depth, v_texCoord);
  //vec4 depth2 = texture(u_depth, v_texCoord + vec2(0,0.01));

  vec4 p1 = vec4(v_texCoord*2. - 1., depth.r*2. -1., 1.);
  vec4 p2 = u_InverseWorldViewProjection * p1;
  p2 = p2 / p2.w;

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

  //outColor = light * color;  

  /*if(v_texCoord.x>0.5)
    outColor = applyFXAA(gl_FragCoord.xy, u_color, u_viewportSize);
  else
    outColor = color;*/

  outColor = vec4(p2.xyz / 200.  + vec3(.5), 1.0);
  //outColor = vec4(vec3(p2.z / 200. - 0.), 1.0);
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

