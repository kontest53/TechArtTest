Shader "LastLevelTest/EnvironmentBaked"
{
    Properties
    {
        _Tint ("Tint", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("Ramp Texture", 2D) = "white" {}
        [Space(10)]

        //[NoScaleOffset]_NormalMap("Normal", 2D) = "bump" {}
        [Space(10)]

        _Emission("Emission", Color) = (0,0,0,0)
        [NoScaleOffset]_SpecularEmissionMap("R - Metallic G - Smoothness B - Emission", 2D) = "black" {}
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



            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ LIGHTMAP_ON VERTEXLIGHT_ON

            #include "UnityCG.cginc"
            #include "PostProcess.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
                float3 uv1 : TEXCOORD1;
                float3 normal : NORMAL;
                fixed3 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD5;
                UNITY_FOG_COORDS(1)
                SHADOW_COORDS(2)
                float4 screenPos : TEXCOORD3;
                float3 worldNormal : TEXCOORD4;
                float4 envLight : COLOR1;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _SpecularEmissionMap;
            sampler2D _RampTex;
            float4 _MainTex_ST;
            fixed4 _Emission;
            fixed4 _OutlineColor;
            fixed4 _Tint;

            
            v2f vert (appdata v)
            {
                v2f o;
                //position
                o.pos = UnityObjectToClipPos(v.vertex);
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);

                
                //normal
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                //compute texture coordinates
                o.uv = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                o.uv1 = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                //vertex color ao
                o.envLight.w = saturate(v.color.r *2);
                
                //environment
                o.envLight.xyz = lerp(_GroundReflection * 2, _SkyReflection, o.worldNormal.y * 0.5 + 0.5) * 0.25 * _GIIntensity;;
                o.envLight.xyz = lerp(o.envLight.xyz * o.envLight.xyz, o.envLight.xyz, o.envLight.w);

                //fog
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //texture
                fixed4 col = tex2D(_MainTex, i.uv1.xy) * _Tint;
                half smoothness = tex2D(_SpecularEmissionMap, i.uv.xy).r;
                half metallic = tex2D(_SpecularEmissionMap, i.uv.xy).g;
                half emissionMap = tex2D(_SpecularEmissionMap, i.uv.xy).b;

                //normal
                fixed3 normal = normalize(i.worldNormal);

                //env light
                half3 env = i.envLight;
                env = lerp(env, i.envLight * i.envLight, metallic);

                //ramp
                float NdotL = dot(normalize(_WorldSpaceLightPos0), normal);
                float hlambert = NdotL * 0.5 + 0.5;
                fixed4 ramp = tex2D(_RampTex, hlambert*0.8+0.1);
                
                //shadow
                float shadow = SHADOW_ATTENUATION(i);
                col = col * (ramp + shadow);
                
                //Fetch lightmap
                half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv.xy);
                fixed3 lightMap = DecodeLightmap(bakedColorTex);
                col.rgb = lightMap.rgb * col.rgb;
                
                //Final Shade
                fixed3 colorOut = col * env;

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
                return fixed4(colorOut,1);
            }
            ENDCG
        }
        //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
