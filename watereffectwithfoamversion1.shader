// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
Shader "Unlit/watereffect"
{
    Properties
    {
        [Header(Water Properties)]
        _TintColor("Color",Color) = (0, 0.15, 0.115, 1)
        _WaterDensity("水体密度",Range(0,1))=0.5
       
        _OceanColorShallow("shadow Color",Color) = (0, 0.15, 0.115, 1)
        _OceanColorDeep("deep Color",Color) = (0, 0.15, 0.115, 1)
        _BubblesColor ("Bubbles Color", Color) = (1, 1, 1, 1)//浪尖泡沫颜色
        _MainTex ("MainTex", 2D) = "white" {}
        _NoiseTex ("NoiseTex",2D) = "bump" {}
        _WaveTex ("WaveTex",2D) = "bump" {}

        //_Cubemap ("Environment Cubemap",Cube) = "_Skybox" {}
        _ForceX("ForceX",Float) = 0.01//细节法线
        _ForceY("ForceY",Float) = 0.01//细节法线
        _HeatTime("HeatTime",Float) = 0.01
        _AlphaParam("AlphaParam",Range(0, 1)) = 0.00
        _FlowStrength("流动强度",Float)=1
        // _shuidiTex("Main Texture",2D) = "white"{}
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01//细节法线
        _WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01//细节法线
        _Distortion ("Distortion", Range(0, 100)) = 0.1
        _FrenelScale("FrenelScale",Range(0.0,1.0)) = 0.5
        
        [Header(Water Reflection and Refration)]
        //_Fansherender("fansheRT",2D) = "white" {}
        [NoScaleOffset]_ReflectionTexture("反射贴图(From ToolForWater)",2D)="white"{}
        [NoScaleOffset]_Renderrefrcol("折射贴图(From ToolForWater)",2D) = "white" {}
        [NoScaleOffset]_Shuirender("折射贴图（来自另一个水底摄像机）",2D) = "white" {}

        
        [Header(Water FFT Properties)]
        _Displace ("Displace", 2D) = "black" { }
        _Normal ("Normal", 2D) = "black" { }
        _Bubbles ("Bubbles", 2D) = "black" { }
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _Speculareffect ("_Speculareffect", Range(1, 10)) = 1
        _diffuseeffect ("_diffuseeffect", Range(1, 10)) = 1

        [Header(Water Foam)]
        _FoamTexture("bubble map",2D)="white"{}
        _Foam1Range("外围泡沫移动范围",Range(0,10))=0.5
        _Foam2Range("内围泡沫移动范围",Range(0,10))=0.2
        _Foam2Speed("内围泡沫移动速度",Float)=1
        _shorethick("边界线多厚",Range(0,1)) = 0.23
        _foamfactor("边界线消失阈值",Range(0,1)) = 0.185
        _fade("边界线透明度",Range(0,1)) = 0.2
        
        _AlphaDelay     ("Alpha Delay", Range(-1,1)) = 0  
        _Speed          ("Time Scale", Range(0,1)) = 0.25  
        _WaveRange      ("Wave Range", Range(-1,1)) = 0.6  
        _Layer1OffsetX  ("Layer1 Offset X", Range(-2,2)) = 0  
        _Layer2OffsetX  ("Layer2 Offset X", Range(-2,2)) = 0  
        _Layer3OffsetX  ("Layer3 Offset X", Range(-2,2)) = 0  
        _Layer1OffsetY  ("Layer1 Offset Y", Range(-2,2)) = 0  
        _Layer2OffsetY  ("Layer2 Offset Y", Range(-2,2)) = 0  
        _Layer3OffsetY  ("Layer3 Offset Y",Range(-2,2)) = 0  

    }
    SubShader
    {
        Tags { "RenderType"="Transparent"
            "LightMode"="ForwardBase"
        "Queue" = "Transparent" }
        //GrabPass { "_RefractionTex" }
        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #define FOG_DISTANCE

            #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
                #if !defined(FOG_DISTANCE)
                    #define FOG_DEPTH 1
                #endif
                #define APPLY_FOG 1  
                
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 uv : TEXCOORD0; 
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD2;
                float4 worldPos : TEXCOORD3;
                half3 SHLighting : COLOR;
                float Fog : TEXCOORD5;
                float4 TtoW0 : TEXCOORD4;  
                float4 TtoW1 : TEXCOORD6;  
                float4 TtoW2 : TEXCOORD7;
                float4 scrPos : TEXCOORD8;
                float4 uv2 : TEXCOORD9;
                float2 uv3 : TEXCOORD10;
                float4 ScreenPos:TEXCOORD11;
                float4 uv4 : TEXCOORD12;
            };
            
            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;



            sampler2D _Shuirender,_Renderrefrcol;
            float4 _Shuirender_ST,_Renderrefrcol_ST;
            //sampler2D _Fansherender;
            //float4 _Fansherender_ST;
            sampler2D _ReflectionTexture;
            float4 _ReflectionTexture_ST;
            sampler2D _Displace;
            sampler2D _Normal;
            sampler2D _Bubbles;
            float4 _Displace_ST,_Normal_ST,_Bubbles_ST;

            fixed4 _TintColor,_OceanColorShallow,_OceanColorDeep, _BubblesColor;
            //samplerCUBE _Cubemap;
            //sampler2D _RefractionTex;
            //float4 _RefractionTex_TexelSize;
            //sampler2D _shuidiTex;
            sampler2D _CameraDepthTexture;
            fixed4 _Specular;
            float _Gloss,_Speculareffect,_diffuseeffect;
            float4 _CameraDepthTexture_TexelSize;
            float4 _shuidiTex_ST;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            float _Distortion;
            float _FrenelScale,_WaterDensity;
            float _FlowStrength;
            sampler2D _WaveTex,_FoamTexture;
            float4 _WaveTex_ST,_FoamTexture_ST;

            fixed _ForceX,_ForceY,_HeatTime,_AlphaParam;
            
            float _Foam1Range,_Foam2Range,_Foam2Speed,_shorethick,_foamfactor,_fade;
            
            uniform float       _AlphaDelay;  
            uniform float       _Speed;  
            uniform float       _WaveRange;  
            uniform float       _Layer1OffsetX;  
            uniform float       _Layer2OffsetX;  
            uniform float       _Layer3OffsetX;  
            uniform float       _Layer1OffsetY;  
            uniform float       _Layer2OffsetY;  
            uniform float       _Layer3OffsetY;  

            float4 ApplyFog(float4 color , v2f i){
                float viewDistance = length(_WorldSpaceCameraPos - i.worldPos.xyz);
                #if FOG_DEPTH
                    viewDistance = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.worldPos.w);
                #endif
                UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
                color.rgb = lerp(unity_FogColor.rgb, color.rgb, saturate(unityFogFactor));
                return color ;
                
            }
            #include "Assets/Shaders/Library/watertools.cginc"
            v2f vert (appdata v)
            {
                v2f o;
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
                
                o.uv2.xy = v.texcoord;
                //o.uv2.y = 1-o.uv2.y;
                //o.uv2.x = 1-o.uv2.x;
                //o.uv3 = TRANSFORM_TEX(v.texcoord, _Fansherender);
                o.uv3 = TRANSFORM_TEX(v.texcoord, _Displace);
                float4 displcae = tex2Dlod(_Displace, float4(o.uv3, 0, 0));
                v.vertex += float4(displcae.xyz, 0);
                
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                //o.worldNormal = normal;
                
                fixed3 worldNormal = o.worldNormal;  
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.scrPos =  ComputeScreenPos(o.vertex);
                o.ScreenPos = ComputeScreenPos(o.vertex);
                
                //泡沫位移
                float2 inuv = v.uv; 
                float2 uv_tex1 = DelayOffsetUV(inuv, _Layer1OffsetX, _Layer1OffsetY); 
                o.uv1.xy = TRANSFORM_TEX(v.texcoord, _FoamTexture);

                // layer1 uv offset  
                float2 uv_tex2 = DelayOffsetUV(inuv, _Layer2OffsetX, _Layer2OffsetY); 
                o.uv1.zw = TRANSFORM_TEX(uv_tex2, _FoamTexture);

                // layer1 uv offset 
                float2 uv_tex3 = DelayOffsetUV(inuv, _Layer3OffsetX, _Layer3OffsetY);  
                o.uv4.xy = TRANSFORM_TEX(uv_tex3, _FoamTexture); 

                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldPos = o.worldPos.xyz; 
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  

                #if APPLY_FOG
                    o.worldPos.w = o.vertex.z;
                #endif

                o.SHLighting = ShadeSH9(float4(o.worldNormal,1)) ;//使用球谐光照
                o.Fog = ((o.vertex.z * unity_FogParams.z) + unity_FogParams.w);//应用unity雾效因子(初始)
                return o;
                
            }

            

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 normal = UnityObjectToWorldNormal(tex2D(_Normal, i.uv3).rgb);
                fixed bubbles = tex2D(_Bubbles, i.uv3).r;
                
                half3 tmp1 = _LightColor0.xyz;
                half3 tmp2 = _WorldSpaceLightPos0.xyz;
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);

                fixed4 tmp9;
                float2 P_10 = (i.uv.zw + (_Time.xz * _HeatTime));
                tmp9 = tex2D(_NoiseTex,P_10);
                
                fixed4 tmp11;
                float2 P_12 = (i.uv.zw + (_Time.yx * _HeatTime));
                tmp11 = tex2D(_NoiseTex,P_12);

                float2 uvMain_8;
                uvMain_8.x = (i.uv.x + ((((tmp9.x + tmp11.x) * (tmp9.w + tmp11.w)) - 1.0) * _ForceX));
                uvMain_8.y = (i.uv.y + ((((tmp9.x + tmp11.x) * (tmp9.w + tmp11.w)) - 1.0) * _ForceY));

                fixed3 tmp4 = i.worldNormal;
                fixed3 bump = normalize(UnpackNormal(tex2D(_WaveTex, uvMain_8)).rgb);
                

                //fixed3 refrCol = RefrColfromGrabs(bump,i.scrPos);

                float2 offset1 = bump.xy * _Distortion * _Shuirender_ST * 0.1;
                i.uv2.xy = offset1 + i.uv2.xy; 
                i.uv3.xy = offset1 + i.uv3.xy;

                fixed4 tmp13 = tex2D(_MainTex,uvMain_8);
                //fixed3 refrcol = RefrColfromRT(tmp13,i.uv2) * _LightColor0.rgb;//另一个相机
                float3 refrcol1 = RefractionColor(i.ScreenPos,normal) * _LightColor0.rgb + 1.0f * (tmp13 * tmp13.w).xyz ;

                //bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

                //float4 fresnelReflectFactor = Fresnel(_FrenelScale,viewDir,bump);
                float4 fresnelReflectFactor1 = Fresnel(_FrenelScale,viewDir,lightDir);
                //fixed fresnel = saturate(_FrenelScale + (1 - _FrenelScale) * pow(1 - dot(bump, lightDir), 5));
                half facing = saturate(dot(viewDir, normal));                
                fixed3 oceanColor = lerp(_OceanColorShallow, _OceanColorDeep, facing);

                //浪尖泡沫颜色
                fixed3 bubblesDiffuse = _BubblesColor.rbg * _LightColor0.rgb * saturate(dot(lightDir, normal));
                //岸边泡沫
                float4 foamCol1=FoamColor(i.ScreenPos,i.uv1.xy,refrcol1);
                float4 foamCol2=FoamColor(i.ScreenPos,i.uv1.zw,refrcol1);
                float4 foamCol3=FoamColor(i.ScreenPos,i.uv4.xy,refrcol1);
                foamCol1.a = GetDisappearAlpha(_Layer1OffsetX);
                foamCol2.a = GetDisappearAlpha(_Layer2OffsetX);
                foamCol3.a = GetDisappearAlpha(_Layer3OffsetX);
                float4 f1 = TwoColorBlend(foamCol1,foamCol2);
                float4 foamCol = TwoColorBlend(f1,foamCol3);



                //海洋颜色
                fixed3 oceanDiffuse = oceanColor * _LightColor0.rgb * saturate(dot(lightDir, normal));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(normal, halfDir)), _Gloss) * _Speculareffect;

                //fixed3 reflCol1 = ReflectUsingCubeMap(viewDir,bump,tmp13); 
                //fixed3 reflCol2 = ReflectUsingCamerasetting(i.uv3,tmp13);
                float3 reflCol3 = oceanDiffuse * Reflect(i.ScreenPos,normal) * _TintColor  * 3.0f;
                //float3 reflCol3 = Reflect(i.ScreenPos,normalize(normal)) * 2;
                fixed3 diffuse = lerp(oceanDiffuse, bubblesDiffuse, bubbles) * _diffuseeffect;

                //float3 tmp7 = reflCol3 * fresnelReflectFactor1  + refrcol *  (1 - fresnelReflectFactor1) ;            
                //float3 tmp7 = reflCol3 * fresnel * oceanColor  + refrcol * oceanColor * (1-fresnel) ;
                float3 tmp7 = lerp(refrcol1 * 3.6f,reflCol3,fresnelReflectFactor1) + diffuse + specular * 2 + foamCol* 1.5;

                fixed4 coll;
                coll = guangzhao(tmp4,tmp2,tmp7,tmp1,i.SHLighting);
                fixed4 col;
                col.w = coll.w; 
                col.rgb = coll * ApplyFog(coll,i) ;
                
                return col;
            }
            ENDCG
        }
    }
    //FallBack "Diffuse"
    
}
