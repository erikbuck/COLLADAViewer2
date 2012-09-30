//
//  AGLKBaseEffectShader.vsh
//  
//

#define highp
#define lowp

/////////////////////////////////////////////////////////////////
// VERTEX ATTRIBUTES
/////////////////////////////////////////////////////////////////
attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_texCoords0;
attribute vec2 a_texCoords1;

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
   // Texture coords
   v_texCoords[0] = a_texCoords0;
   v_texCoords[1] = a_texCoords1;
   
   // Lighting
   lowp vec3 normal = normalize(u_normalMatrix * a_normal);
   lowp float nDotL = max(
      dot(normal, normalize(u_light0Position.xyz)), 0.0);
   v_lightColor = (nDotL * u_light0DiffuseColor) + 
      u_lightModelAmbientColor;

   gl_Position = u_mvpMatrix * vec4(a_position, 1.0); 
}
