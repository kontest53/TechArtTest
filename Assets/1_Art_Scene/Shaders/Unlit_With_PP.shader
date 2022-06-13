Shader "LastLevelTest/UnlitWithPP"
{
    Properties
    {
      _MainTex ("Texture", 2D) = "white" {}
      _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {"RenderType"="Opaque"}

      Pass {
         Cull Off ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            //#pragma multi_compile_fog

         #include "UnityCG.cginc"
         #include "PostProcess.cginc"//

         fixed4 _Color;
         float4 _MainTex_ST;
         sampler2D _MainTex;

         struct appdata {
            float4 vertex 		: POSITION;
            float2 uv         : TEXCOORD1;
         };

         struct v2f {
            float4 pos 			      : SV_POSITION;
            float2 uv               : TEXCOORD0;
            //UNITY_FOG_COORDS(1)
            float4 screenPos 	      : TEXCOORD3;
         };
 
         v2f vert (appdata v)
         {
            v2f o;
			   o.pos = UnityObjectToClipPos(v.vertex);
            o.screenPos = ComputeScreenPos(o.pos);
            o.uv = v.uv;
            //UNITY_TRANSFER_FOG(o,o.pos);
            return o;
         }
 
         float4 frag (v2f i) : SV_Target
         {
            //Gradient Color Ramp
            fixed2 screenUV = (i.screenPos.y / i.screenPos.w);

            fixed4 colorOut = tex2D(_MainTex, i.uv) * _Color;

            //Vingette
            float vingetteScreenPos = distance(i.screenPos.xy / i.screenPos.w, float2(0.5, 0.5));
            float vingette = float4(vingetteScreenPos, vingetteScreenPos, vingetteScreenPos, 1.0);
            half vingetteMask = vingette * _Vignette;
            
            colorOut.rgb = postProcessing(colorOut.rgb, vingetteMask);

                            //fog
            //UNITY_APPLY_FOG(i.fogCoord, colorOut);

            return fixed4(colorOut);
            }
            ENDCG
        }
    }
}
