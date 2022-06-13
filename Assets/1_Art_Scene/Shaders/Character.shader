Shader "LastLevelTest/Character"
{
    Properties
    {
        _Tint ("Tint", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("Ramp Texture", 2D) = "white" {}
        [Space(10)]

        [NoScaleOffset]_NormalMap("Normal", 2D) = "bump" {}
        [Space(10)]

        _Emission("Emission", Color) = (0,0,0,0)
        [NoScaleOffset]_SpecularEmissionMap("R - Metallic G - Smoothness B - Emission", 2D) = "black" {}
        [Space(10)]
        _GIIntensity2 ("GIIntecity_2", Float) = 1 
        _OutlineColor ("Outline", Color) = (0, 0, 0, 0)

//
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass//Main
        {

            Tags
			{
				"LightMode" = "ForwardBase"
				"PassFlags" = "OnlyDirectional"
			}

            Stencil {
                Ref 6
                Comp always
                Pass replace
                Fail keep
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //#pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "PostProcess.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                fixed3 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                SHADOW_COORDS(2)
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD7;
                float3 viewDir : TEXCOORD6;
                float4 envLight : COLOR1;
                float4 tspace0          : TEXCOORD3; // tangent.x, bitangent.x, normal.x, worldPos.x
                float4 tspace1          : TEXCOORD4; // tangent.y, bitangent.y, normal.y, worldPos.y
                float4 tspace2          : TEXCOORD5; // tangent.z, bitangent.z, normal.z, worldPos.z
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _SpecularEmissionMap;
            sampler2D _RampTex;
            float4 _MainTex_ST;
            fixed4 _Emission;
            fixed4 _OutlineColor;
            fixed4 _Tint;
            float _GIIntensity2;

            
            v2f vert (appdata v)
            {
                v2f o;
                //position
                o.pos = UnityObjectToClipPos(v.vertex);
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                
                //normal
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(worldNormal, wTangent) * tangentSign;
                o.tspace0 = half4(wTangent.x, wBitangent.x, worldNormal.x, worldPos.x);
                o.tspace1 = half4(wTangent.y, wBitangent.y, worldNormal.y, worldPos.y);
                o.tspace2 = half4(wTangent.z, wBitangent.z, worldNormal.z, worldPos.z);
                
                //uv
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //vertex ao
                o.envLight.w = saturate(v.color.r *2);
                
                //environment
                o.envLight.xyz = lerp(_GroundReflection * 2, _SkyReflection, worldNormal.y * 0.5 + 0.5) * 0.25 * (_GIIntensity * _GIIntensity2);;
                o.envLight.xyz = lerp(o.envLight.xyz * o.envLight.xyz, o.envLight.xyz, o.envLight.w);

                //fog
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Tint;
                fixed4 normalMap = tex2D(_NormalMap, i.uv);
                half smoothness = tex2D(_SpecularEmissionMap, i.uv).r;
                half metallic = tex2D(_SpecularEmissionMap, i.uv).g;
                half emissionMap = tex2D(_SpecularEmissionMap, i.uv).b;


                
                //normal
                fixed3 tnormal = UnpackNormal(normalMap);
                float3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);
                fixed3 normal = normalize(worldNormal);
				float3 worldPos = float3(i.tspace0.w, i.tspace1.w, i.tspace2.w);

                //Direction
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 worldRefl = reflect(-worldViewDir, normal);
                fixed3 direction = normalize(lerp(normal, worldRefl, metallic));

                half3 env = i.envLight;
                env = lerp(env, i.envLight * i.envLight, metallic);

                //ramp
                float NdotL = dot(normalize(_WorldSpaceLightPos0), normal);
                float hlambert = NdotL * 0.5 + 0.5;
                fixed4 ramp = tex2D(_RampTex, hlambert*0.8+0.1);

                //RimLight
				float rimDot = 1 - dot(worldViewDir, normal);
				half rimIntensity = rimDot * pow(NdotL, 0.5);
				rimIntensity = smoothstep(_Rim - 0.01, _Rim + 0.01, rimIntensity);
				half3 rim = rimIntensity * _RimColor;
                
                //Specular
				float NdotH = saturate(dot(direction,i.viewDir));
				half specularIntensity = pow(NdotH, 65) * (0 + 1);
				half specular = smoothstep(0.005, 0.01 , specularIntensity) * smoothness * i.envLight.w;
                
                //shadow
                float shadow = SHADOW_ATTENUATION(i);
                //float light = smoothstep(0, 0.01, NdotL * shadow);	
                col = col * (ramp + shadow);
                
                //Final Shade
                fixed3 colorOut = col * (env + specular + rim);

                //Emission
                half3 emission = emissionMap * _Emission * 10;
                colorOut += emission;

                //Vingette
                float vingetteScreenPos = distance(i.screenPos.xy / i.screenPos.w, float2(0.5, 0.5));
				float vingette = float4(vingetteScreenPos, vingetteScreenPos, vingetteScreenPos, 1.0);
                half vingetteMask = vingette * _Vignette;
                colorOut.rgb = postProcessing(colorOut, vingetteMask);

                //fog
                UNITY_APPLY_FOG(i.fogCoord, colorOut);
                //return fixed4(vingetteMask,1,1,1);
                return fixed4(colorOut,1);
                //return float4(shadow,1,1,1);
            }
            ENDCG
        }
        
        Pass//Ouline 
        {

            Stencil {
                Ref 5
                Comp Greater
                Pass replace
                Fail keep
            }

            CGPROGRAM
 
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "PostProcess.cginc"
 
            struct v2f {
                float4 pos : SV_POSITION;
                float fog : TEXCOORD1;
            };

            float4 _OutlineColor;
 
            v2f vert ( float4 vertex : POSITION, float3 normal : NORMAL)
            {
                v2f o;
                //Position
                o.pos = UnityObjectToClipPos(vertex);

                //Outline
                float3 clipNormal = mul((float3x3) UNITY_MATRIX_VP, mul((float3x3) UNITY_MATRIX_M, normal));
                float2 offset = normalize(clipNormal.xy) * o.pos.w * (0.01 * _Outline);
                float aspect = _ScreenParams.x / _ScreenParams.y;
                offset.y *= aspect;
                o.pos.xy += offset;

                //Fog
                float coord = o.pos.z;
                #if defined(UNITY_REVERSED_Z)
               	coord = max(((1.0 - coord / _ProjectionParams.y) * _ProjectionParams.z), 0);
                #endif
				float unityFog = unity_FogParams.x * coord;
                o.fog = saturate( exp2( -unityFog * unityFog));

                return o;
            }
 
            half4 frag(v2f i) : SV_Target
            {
                //Color
                fixed3 colorOut = 1 * _OutlineColor;

                //Fog
                colorOut = lerp(unity_FogColor, colorOut, i.fog);

                //Post
                colorOut = colorOut;
                fixed3 luma = dot(colorOut, fixed3(0.213, 0.715, 0.072));
	            fixed3 diff = colorOut - luma;
	            colorOut = luma + diff * _Saturation;

                return fixed4(colorOut, 1);
            }
 
            ENDCG
        }
        //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
