Shader "OUR/river_new_optimized"
{
    Properties
    {
        _Texture ("R_Main, G_Flow, B_Noise", 2D) = "white" {}

        _Scale("UV Scale, xy=r, zw=b", Vector) = (0,0,0,0)
        _Color ("Color", Color) = (1,1,1,1)
        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _Speed ("Speed", float) = 1
        _falloff("Falloff", Range(0, 1)) = 0.5

        _progress("Progress", Range(0, 1)) = 0.1


        //_MinLevel("Min Level", float) = 0
        //_MaxLevel("Max Level", float) = 1

        _textureDistort("Texture wobble", range(0,1)) = 0.1
        _textureDistort2("Texture wobble2", range(0,1)) = 0.1
        _noiseScale("Scale Noise", float) = 1
        
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100
        Cull Back
        ZWrite On
        //Blend SrcAlpha OneMinusSrcAlpha

        // Blend SrcAlpha OneMinusSrcAlpha // Traditional transparency
        // Blend One OneMinusSrcAlpha // Premultiplied transparency
        // Blend One One // Additive
        // Blend OneMinusDstColor One // Soft Additive
        // Blend DstColor Zero // Multiplicative
        // Blend DstColor SrcColor // 2x Multiplicative

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            #include "PostProcess.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 color : COLOR;
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 color : COLOR3;
                float3 worldPos : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                float4 screenPos 	      : TEXCOORD3;

                half3 colMul : COLOR0;
				half3 colAdd : COLOR1;
                half3 light : COLOR2;
            };

            sampler2D _Texture;
            float4 _Texture_ST;//main_R flow_G noise_B

            float _Speed;//uv speed
            float4 _Color;//water color
            float4 _FoamColor;

            //smoothstep
            float _falloff;
            float _progress;
            float4 _Scale;//uv scale
            float _textureDistort;
            float _textureDistort2;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                float3 worldPos = o.worldPos;
                o.color = v.color;
                
                //uv samples
                o.uv = TRANSFORM_TEX(v.uv, _Texture);

                
                //uv animation
                float offset = _Time.x * 3 * _Speed;
                o.uv += float2(0, offset);//offset

                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //texture sample
                float texFlow = tex2D(_Texture, float2(i.uv * _Scale.z) + (_Time.x * float2(0, 10))).g;//Flow, float2 for increase basic speed flow
                float texNoise = tex2D(_Texture, float2(i.uv * float2(_Scale.w, 2) + (_Time.x * float2(0, 10))) - (texFlow * _textureDistort)).b;//Noise
                float texMain = tex2D(_Texture, float2(i.uv * _Scale.rg) - (texFlow * _textureDistort2)).r;//Main
                

                float noiseMask = smoothstep(_falloff, _falloff + _progress, texNoise);

                float4 mix = (texMain * _FoamColor) + _Color;
                float mask = clamp(i.color.r + noiseMask - (i.color.g) + i.color.b, 0, 0.5);  
                
                float4 col = lerp(_Color, mix, mask);
                col = lerp(col, col + (noiseMask * _FoamColor), i.color.b);
                //col.rgb = (col.rgb * (i.light + GET_MAIN_LIGHT_COLOR(i)) * i.colMul + i.colAdd);
                col.a = 1;

                //Vingette
                float vingetteScreenPos = distance(i.screenPos.xy / i.screenPos.w, float2(0.5, 0.5));
                float vingette = float4(vingetteScreenPos, vingetteScreenPos, vingetteScreenPos, 1.0);
                half vingetteMask = vingette * _Vignette;
                col.rgb = postProcessing(col.rgb, vingetteMask);
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
