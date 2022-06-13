Shader "LastLevelTest/PortalShader"
{
    Properties
    {
        _MainTex ("mainTexture", 2D) = "white" {}
        _FlowTex ("flowTexture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

        _MaxDistance ("MaxDistance", Float) = 1
        _MinDistance ("MinDistance", Float) = 1
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float distanceFromCamera : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _FlowTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _MaxDistance;
            float _MinDistance;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = ComputeScreenPos(o.vertex);

                float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.distanceFromCamera = distance(worldPos, _WorldSpaceCameraPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float fade = saturate((i.distanceFromCamera - _MinDistance) / _MaxDistance);
                float2 uv =  i.uv.xy / i.uv.w;
                fixed texFlow = tex2D(_FlowTex, (uv *5) + (_Time.x * 4));
                fixed4 col = tex2D(_MainTex, uv - (texFlow * (fade/50))) ;
                return col * _Color;
            }
            ENDCG
        }
    }
}
