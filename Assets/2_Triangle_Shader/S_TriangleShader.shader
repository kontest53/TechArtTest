Shader "Unlit/TriangleShader"
//Нашел этот шейдер на сайте ShaderToy и перевёл его в юнити
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Scale ("Scale", Float) = 1
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
            #define PI 3.14159265359
            #define TWO_PI 6.28318530718

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float3 simplexGrid (float2 uv)
            {
                float3 xyz = float3(0,0,0);

                //float f2d = 0.3660254038; 
                float f2d = (sqrt(3) - 1) / 2;
                f2d *= (uv.x + uv.y);

                float2 skew = float2(0,0);//скос 

                skew.x = uv.x + f2d;
                skew.y = uv.y + f2d;
                
                xyz.xy = 1.0 - float2(skew.x, skew.y - skew.x);
                xyz.z = skew.y;
                
                

                return xyz;
            }

            float4 _Color;
            float _Scale;

            float2 rotate(float2 original, float angle, float2 pivot)
            {
                float2x2 rotation = float2x2(cos(angle), sin(angle), -sin(angle), cos(angle));
                float2 final = original;
                final -= pivot;
                final = mul(final, rotation);
                final += pivot;
                return final;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _Scale;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = rotate(i.uv, -PI/4.0, float2(0,0));

                float3 uvT = simplexGrid(uv);
                float3 cellUv = frac(uvT);
                float3 col = 1;

                float lineSize = 0.2;
                float lineBlur = 0.01;

                for (int i = 0; i < 3; i++)
                {
                    col *= smoothstep(lineSize / 2. - lineBlur, lineSize / 2. + lineBlur, cellUv[i]);
                    col *= smoothstep(lineSize / 2. - lineBlur, lineSize / 2. + lineBlur, 1 - cellUv[i]);
                }
                
                fixed4 color = float4(col, 1) * _Color;
                return color;
            }
        ENDCG
        }
    }
}