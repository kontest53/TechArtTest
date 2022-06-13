Shader "LastLevelTest/DisolveWithCustomData"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _DisolveMask ("Disolve Mask", 2D) = "white" {}
        _NoiseScale ("Noise Scale", Float) = 1
        _Falloff ("Falloff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        Cull Back
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;//xyzw
                half4 color : COLOR;
                
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half4 color : COLOR;
            };

            sampler2D _MainTex, _DisolveMask;
            float4 _MainTex_ST;
            float _NoiseScale, _Falloff;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv.zw = v.uv.zw;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.color = _Color * v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float customData = i.uv.z;
                fixed4 col = tex2D(_MainTex, i.uv.xy)*i.color;
                fixed noise = tex2D(_DisolveMask, (i.uv.xy * _NoiseScale));
                float noiseMask = smoothstep(customData.x, customData.x + _Falloff, noise);
                col.a *= noiseMask;
                return col;
            }
            ENDCG
        }
    }
}
