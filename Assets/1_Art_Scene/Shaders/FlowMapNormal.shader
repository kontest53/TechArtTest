Shader "LastLevelTest/FlowMapNormal"
{
    Properties
    {
        _LightColor("LightColor", Color) = (1,1,1,1)
        _Color ("Color", COLOR) = (1,1,1,1)

        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _FlowMap ("Flow (RG), A noise", 2D) = "black" {}

        //normal
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        //[NoScaleOffset] _SpecularMap("SpecularMap (RGB)", 2D) = "white" {}
        _MainLightPosition("MainLightPosition", Vector) = (0,0,0,0)
        //

        _UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
        _VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
        _Tiling ("Tiling", Float) = 1

        _Speed ("Speed", Float) = 1
        _FlowStrength ("Flow Strength", Float) = 1
        _FlowOffset ("Flow Offset", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "PostProcess.cginc"
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float2 uv           : TEXCOORD0;

                float3 lightdir : TEXCOORD1;
				float3 viewdir : TEXCOORD2;

				float3 T : TEXCOORD3;//tangent
				float3 B : TEXCOORD4;//binormal
				float3 N : TEXCOORD5;//normal
            };

            //#include "Flow.cginc"
            
            sampler2D _MainTex, _FlowMap, _NormalMap, _SpecularMap;
            float4 _MainTex_ST, _Color, _LightColor;
            float3 _MainLightPosition;
            float _UJump, _VJump, _Tiling, _Speed, _FlowStrength, _FlowOffset; 
            
            

            v2f vert (appdata v)
            {
                v2f o;
                // calc output position directly
                o.vertex = UnityObjectToClipPos(v.vertex);

                //pass uv coord
                o.uv = v.uv;

                //calc lightDir vector heading current vertex
                float4 worldPosition = mul(unity_ObjectToWorld, v.vertex);
                float3 lightDir = worldPosition.xyz - _MainLightPosition.xyz;
                o.lightdir = normalize(lightDir);

                //calc viewDir vector
                float3 viewDir = normalize(worldPosition.xyz - _WorldSpaceCameraPos.xyz);
                o.viewdir = viewDir;

                //calc Normal, Binormal, Tangent vector in world space
                //cast 1st arg to 'float3x3' (type of v.normal is 'float3')
                float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                float3 worldTangent = mul((float3x3)unity_ObjectToWorld, v.tangent);
                
                float3 binormal = cross(v.normal, v.tangent.xyz);
                float3 worldBinormal = mul((float3x3)unity_ObjectToWorld, binormal);

                //set n,b,t
                o.N = normalize(worldNormal);
                o.B = normalize(worldBinormal);
                o.T = normalize(worldTangent);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 flowVector = tex2D(_FlowMap, i.uv).rg * 2 - 1;
                flowVector *= _FlowStrength;
                float noise = tex2D(_FlowMap, i.uv).a;

                float time = _Time.y * _Speed + noise;
                float2 jump = float2(_UJump, _VJump);
                
                float3 uvwA = FlowUVW(i.uv, flowVector, jump, _FlowOffset, _Tiling, time, false);
                float3 uvwB = FlowUVW(i.uv, flowVector, jump, _FlowOffset, _Tiling, time, true);


                //// set normals ////
                float3 normalA = UnpackNormal(tex2D(_NormalMap, uvwA.xy)) * uvwA.z;
                float3 normalB = UnpackNormal(tex2D(_NormalMap, uvwB.xy)) * uvwB.z;

                float3 tangentNormal = normalize((normalA + normalB) * 2 - 1);

                // 'TBN' transforms the world space into a tangent space
                // we need its inverse matrix
                // Tip: An inverse matrix of orthogonal matrix is its transpose matrix
                float3x3 TBN = float3x3(normalize(i.T), normalize(i.B), normalize(i.N));
                TBN = transpose(TBN);
                
                // finally we got a normal vector from the normal map
                float3 worldNormal = mul(TBN, tangentNormal);

                // Lambert here (cuz we're calculating Normal vector in pixel shader)
                float3 lightDir = normalize(i.lightdir);
                float3 diffuse = saturate(dot(worldNormal, -lightDir));//lambert


                fixed4 colA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
                fixed4 colB = tex2D(_MainTex, uvwB.xy) * uvwB.z;
                
                fixed4 c = (colA + colB);
                c.xyz = _Color * c.xyz; 

                //// Specular ////
                float3 specular = 0;

                    float3 reflection = reflect(lightDir, worldNormal);
                    float3 viewDir = normalize(i.viewdir);

                    specular = saturate(dot(reflection, -viewDir));
                    specular = pow(specular, 50.0f);
                    
                    //specular tex
                    //fixed4 specularIntensityA = tex2D(_SpecularMap, uvwA.xy) * uvwA.z;
                    //fixed4 specularIntensityB = tex2D(_SpecularMap, uvwB.xy) * uvwB.z;
                    //fixed4 specularIntensity = specularIntensityA + specularIntensityB;
                    //specular *= _LightColor * specularIntensity; 
                    
                    specular *= _LightColor; 
                

                //ambient
                float3 ambient = float3(0.1f, 0.1f, 0.1f) * 2 * ((colA.xyz + colB.xyz) * _Color);

                return float4(c.xyz + specular + ambient, c.a);
            }
            ENDCG
        }
    }
}
