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
float3 RefractionColor(float4 screenPos,float3 worldNormal)
    {
        //法线uv偏移 长宽应当适配屏幕
        //float2 uvOffset=tangnentNormal.xy*_FlowStrength;
        //世界空间改为xz
        float2 uvOffset=worldNormal.xz*_FlowStrength;
        uvOffset.y*=_CameraDepthTexture_TexelSize.z*abs(_CameraDepthTexture_TexelSize.y);
        
        //齐次除法得到透视的uv坐标
        float2 uv=(screenPos.xy+uvOffset)/screenPos.w;
        #if UNITY_UV_STARTS_AT_TOP
            if (_CameraDepthTexture_TexelSize.y < 0) {
                uv.y = 1 - uv.y;
            }
        #endif
        //采样深度 得到深度差
        float backgroundDepth=LinearEyeDepth(tex2D(_CameraDepthTexture,uv));
        float surfaceDepth=UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
        float waterDepth=backgroundDepth-surfaceDepth;

        //水深为负数表明物体在水面之上，应当抹去法向偏移 重新计算
        uvOffset*=saturate(waterDepth);//负数就归0了，顺便水深0-1还可以有个过渡
        uv=(screenPos.xy+uvOffset)/screenPos.w;
        #if UNITY_UV_STARTS_AT_TOP
            if (_CameraDepthTexture_TexelSize.y < 0) {
                uv.y = 1 - uv.y;
            }
        #endif
        backgroundDepth=LinearEyeDepth(tex2D(_CameraDepthTexture,uv));
        surfaceDepth=UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
        waterDepth=backgroundDepth-surfaceDepth;
        //采样贴图
        float3 refracolor = tex2D(_Renderrefrcol,uv);
        float fogFactor=exp2(-waterDepth*_WaterDensity);
        float3 finalCol=lerp(_OceanColorDeep,refracolor,fogFactor);


        

        return finalCol * (1.5f * _TintColor)  ;

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

//泡沫
float4 FoamColor(float4 screenPos,float2 FoamUV,float3 blendcolor)
    {
        //未经法线扰乱的深度

        float2 uv=(screenPos.xy)/screenPos.w;
        #if UNITY_UV_STARTS_AT_TOP
            if (_CameraDepthTexture_TexelSize.y < 0) {
                uv.y = 1 - uv.y;
            }
        #endif
        float backgroundDepth=LinearEyeDepth(tex2D(_CameraDepthTexture,uv));
        float surfaceDepth=UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
        float waterDepth=backgroundDepth-surfaceDepth;
        
        //一条依附边缘
        float factor1=1-smoothstep(_Foam1Range,_Foam1Range+1.5,waterDepth);
        //一条移动
        float time=-frac(_Time.y*_Foam2Speed);
        float offset=time*_Foam2Range;//(0-_Foam2Range)的偏移量
        float fade=sin(frac(_Time.y*_Foam2Speed)*3.14);//中间最明显
        float factor2=step(_Foam1Range+_Foam2Range+_foamfactor +offset,waterDepth)*step(waterDepth,_Foam1Range+_Foam2Range+_shorethick+offset);
        float factor=factor1+factor2*fade*_fade;
        float4 foamCol=factor*tex2D(_FoamTexture,FoamUV*10).r;
        

        return foamCol;


    }
    //泡沫的UV动画函数  
    float2 DelayOffsetUV(float2 uv, float offset, float offset_y)//输入UV 和偏移量（x，y），外部变量控制速度，范围  
    {  
        float pi = 3.1415926536f;  
        float sintime = sin(_Time.y * _Speed * pi + offset * 0.5f * pi);//余弦函数使UV来回移动,  
        float u = (sintime + 1) * 0.5f * _WaveRange + (1 - _WaveRange);  
        uv.x += u;  
        uv.y += offset_y;  
        return uv;  
    }  
    //获取泡沫逐渐出现，向岸边移动，开始折返并逐渐消失的透明度值  
    fixed GetDisappearAlpha(float delay)  
    {  
        float PI = 3.1415926536f;  
        float t = _Time.y *_Speed * PI + delay * 0.5* PI + 1.2 * PI;  
        fixed a = (sin(t)+1)*0.5;  
        return a*a;  
    }  
    //将两层半透明的颜色合并，获取合并后的RGBA  
    fixed4 TwoColorBlend(fixed4 c1, fixed4 c2)  
    {  
        fixed4 c12;  
        c12.a = c1.a + c2.a - c1.a * c2.a;  
        c12.rgb = (c1.rgb * c1.a * (1 - c2.a) + c2.rgb * c2.a) / c12.a;  
        return c12;  
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