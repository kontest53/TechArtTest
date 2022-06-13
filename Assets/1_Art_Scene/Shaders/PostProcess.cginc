#ifndef PostProcess
#define PostProcess

//Rim
float4 _RimColor;
float _Rim;

//GI
float3 _SkyReflection;
float3 _GroundReflection;
float _GIIntensity;

//PostProcesses
float _Saturation;
float _Vignette;
float _Outline;


//Post Process
inline fixed3 postProcessing(fixed3 colorIn, half vingetteMask)
{
    fixed3 colorOut = colorIn;
	//Vignette
	colorOut.rgb = lerp(colorOut.rgb, colorOut.rgb * colorOut.rgb * 0.5, saturate(vingetteMask * vingetteMask));
    //Saturation
	fixed3 luminance = dot(colorOut.rgb, fixed3(0.213, 0.715, 0.072));
	fixed3 diff = colorOut.rgb - luminance;
	colorOut.rgb = luminance + diff * _Saturation;
    return colorOut;
}

//Flow map
float3 FlowUVW (
    float2 uv, float2 flowVector, float2 jump, float flowOffset, float tiling, float time, bool flowB)
{
    float phaseOffset = flowB ? 0.5 : 0;
    float progress = frac(time + phaseOffset);
    float3 uvw;
    
    uvw.xy = uv - flowVector * (progress + flowOffset);
    uvw.xy *= tiling;
    uvw.xy += phaseOffset;

    uvw.xy += (time - progress) * jump;
    uvw.z = 1 - abs(1 - 2 * progress);
    return uvw;
}
#endif