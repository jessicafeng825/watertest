#ifndef WATER_TOOL_INCLUDE
#define WATER_TOOL_INCLUDE

float3 Reflect(float4 screenPos,float3 worldNormal){
    float2 uvOffset=worldNormal.xz*_FlowStrength;
        uvOffset.y*=_CameraDepthTexture_TexelSize.z*abs(_CameraDepthTexture_TexelSize.y);
        
        //齐次除法得到透视的uv坐标
        float2 uv=(screenPos.xy+uvOffset)/screenPos.w;
        #if UNITY_UV_STARTS_AT_TOP
            if (_CameraDepthTexture_TexelSize.y < 0) {
                uv.y = 1 - uv.y;
            }
        #endif
        float3 reflectCol=tex2D(_ReflectionTexture,uv);
        return reflectCol;
}

//fixed3 ReflectUsingCamerasetting(float2 uv,fixed4 tmp){
//    return tex2D(_Fansherender, uv.xy).rgb * ((3 * _TintColor) * (tmp * tmp.w)).xyz; 
//}
/*
fixed3 ReflectUsingCubeMap(fixed3 viewDir,fixed3 normal,fixed4 tmp){
    fixed3 reflDir = reflect(-viewDir, normal);
    fixed3 reflCol1 = texCUBE(_Cubemap, reflDir).rgb * ((2.6 * _TintColor) * (tmp * tmp.w)).xyz;
    return reflCol1;
}*/
float Fresnel(float F0,float3 viewDir,float3 halfDir)
    {//schlick
        return F0+(1-F0)*pow((1-dot(viewDir,halfDir)),5);
    }
/*
fixed3 RefrColfromGrabs(fixed3 normal,float4 screenPos){
        float2 offset = normal.xy * _Distortion * _RefractionTex_TexelSize.xy;
		screenPos.xy = offset * screenPos.z  + screenPos.xy;
        return tex2D(_RefractionTex, screenPos.xy/ screenPos.w).rgb;
}*/
fixed3 RefrColfromRT(fixed4 tmp,float2 uv){
    return tex2D(_Shuirender,uv ).rgb * ((2.5 * _TintColor) * (tmp * tmp.w)).xyz; 
}
fixed4 guangzhao(fixed3 normal,half3 LightPos,float3 diffusecolor,half3 Lightcolor,half3 SHLighting){
    fixed4 c16,c17;
    fixed diff = saturate(dot(normal,LightPos));
    c17.xyz = diffusecolor * Lightcolor * diff;
    c17.w = _AlphaParam;
    c16.w = c17.w;
    c16.xyz = c17.xyz + diffusecolor * SHLighting;
    return c16;
}
#endif