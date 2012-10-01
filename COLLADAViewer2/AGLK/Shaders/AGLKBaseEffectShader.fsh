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
uniform highp mat3      u_textureTransforms[MAX_TEXTURES];
uniform lowp float      u_textureEnables[MAX_TEXTURES];
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
   lowp vec4 baseColor = vec4(1.0, 1.0, 1.0, 1.0);
   lowp vec4 textureColor = vec4(1.0, 1.0, 1.0, 0.0);
   
   if(0.0 != u_textureEnables[0])
   {
      lowp vec4 color0 = texture2D(u_units[0], v_texCoords[0]);
      if (color0.a < 0.2)
      {  // discard nearly transparent fragments
         discard;
      }
      textureColor = color0;
      baseColor = textureColor;
   }
   
   if(0.0 != u_textureEnables[1])
   {
      lowp vec4 color1 = texture2D(u_units[1], v_texCoords[1]);
      textureColor = mix(textureColor, color1, color1.a);
      baseColor = textureColor;
   }

   gl_FragColor = baseColor * v_lightColor;
}
