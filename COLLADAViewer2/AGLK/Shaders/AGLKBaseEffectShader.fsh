//
//  AGLKBaseEffectShader.fsh
//  
//

#define highp
#define lowp

/////////////////////////////////////////////////////////////////
// TEXTURE
/////////////////////////////////////////////////////////////////
#define MAX_TEXTURES    2
#define MAX_TEX_COORDS  2

/////////////////////////////////////////////////////////////////
// UNIFORMS
/////////////////////////////////////////////////////////////////
uniform highp mat4      u_mvpMatrix;
uniform highp mat3      u_normalMatrix;
uniform sampler2D       u_units[MAX_TEXTURES];
uniform lowp  vec4      u_lightModelAmbientColor;
uniform highp vec4      u_light0Position;
uniform highp vec4      u_light0DiffuseColor;

/////////////////////////////////////////////////////////////////
// Varyings
/////////////////////////////////////////////////////////////////
varying highp vec2      v_texCoords[MAX_TEX_COORDS];
varying lowp vec4       v_lightColor;


void main()
{
//   lowp vec4 color0 = texture2D(u_units[0], v_texCoords[0]);
//   if (color0.a < 0.2)
//   {  // discard nearly transparent fragments
//      discard;
//   }
//
//   lowp vec4 textureColor = color0;
   
//   lowp vec4 color1 = texture2D(u_units[1], v_texCoords[1]);
//   color1 = mix(baseColor, color1, color1.a);
//
//   lowp vec4 textureColor = mix(color0, color1, color1.a);
   
//   gl_FragColor = textureColor * v_lightColor;
   gl_FragColor = v_lightColor;
}
