Shader "LastLevelTest/SkyBox"
{
    Properties
    {
        _Intensety("Intensety", Range(0, 3)) = 1
        [Space(10)]
      
        _GradientColorA("Color A", Color) = (1, 0, 1, 1)
        _GradientColorB("Color B", Color) = (1, 1, 0, 1)
        [Space(10)]

        _RadiusMultiplier("Radius", Range(0, 2)) = 1
        _Power("Power", Range(0, 5)) = 1
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }

      Pass {
         Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            //#pragma multi_compile_fog

         #include "UnityCG.cginc"
         #include "PostProcess.cginc"//

         fixed4 _GradientColorA;
         fixed4 _GradientColorB;

         half _RadiusMultiplier;
         half _Power;
         half _Intensety;

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
            float dist = sqrt(screenUV.x + screenUV.y) / _RadiusMultiplier;
            dist = clamp(dist, 0, 1);
            dist = pow(dist, _Power);
            fixed3 colorOut = lerp(_GradientColorB, _GradientColorA, dist) * _Intensety;

            //Vingette
            float vingetteScreenPos = distance(i.screenPos.xy / i.screenPos.w, float2(0.5, 0.5));
            float vingette = float4(vingetteScreenPos, vingetteScreenPos, vingetteScreenPos, 1.0);
            half vingetteMask = vingette * _Vignette;
            
            colorOut.rgb = postProcessing(colorOut.rgb, vingetteMask);

                            //fog
            //UNITY_APPLY_FOG(i.fogCoord, colorOut);

            return fixed4(colorOut, 1);
            }
            ENDCG
        }
    }
}
