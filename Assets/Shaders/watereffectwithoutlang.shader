// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
Shader "Unlit/watereffectwithoulang"
{
    Properties
    {
        _TintColor("Color",Color) = (0, 0.15, 0.115, 1)
        _OceanColorShallow("Color",Color) = (0, 0.15, 0.115, 1)
        _OceanColorDeep("Color",Color) = (0, 0.15, 0.115, 1)
        _MainTex ("MainTex", 2D) = "white" {}
        _NoiseTex ("NoiseTex",2D) = "bump" {}
        _WaveTex ("WaveTex",2D) = "bump" {}
        _BGTex ("BGTex",2D) = "white" {}
        //_Cubemap ("Environment Cubemap",Cube) = "_Skybox" {}
        _ForceX("ForceX",Float) = 0.01
        _ForceY("ForceY",Float) = 0.01
        _HeatTime("HeatTime",Float) = 0.01
        _AlphaParam("AlphaParam",Range(0, 1)) = 0.00
        _BGSpeedX("BGSpeedX",Float) = 0.01
        _BGSpeedY("BGSpeedY",Float) = 0.01
       // _shuidiTex("Main Texture",2D) = "white"{}
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
		_Distortion ("Distortion", Range(0, 10)) = 0.1
        _FrenelScale("FrenelScale",Range(0.0,1.0)) = 0.5
        _Shuirender("shuidiRT",2D) = "white" {}
        //_Fansherender("fansheRT",2D) = "white" {}
        [NoScaleOffset]_ReflectionTexture("反射贴图(From ToolForWater)",2D)="white"{}
        _FlowStrength("流动强度",Float)=1
        
        //_Displace ("Displace", 2D) = "black" { }
        //_Normal ("Normal", 2D) = "black" { }
        //_Bubbles ("Bubbles", 2D) = "black" { }

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
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD2;
                float4 worldPos : TEXCOORD3;
                half3 SHLighting : COLOR;
                float Fog : TEXCOORD5;
                float4 TtoW0 : TEXCOORD4;  
				float4 TtoW1 : TEXCOORD6;  
				float4 TtoW2 : TEXCOORD7;
                float4 scrPos : TEXCOORD8;
                float2 uv2 : TEXCOORD9;
                float2 uv3 : TEXCOORD10;
                float4 ScreenPos:TEXCOORD11;
                float2 uv4:TEXCOORD12;
            };
            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            sampler2D _BGTex;
            float4 _BGTex_ST;
            sampler2D _Shuirender;
            float4 _Shuirender_ST;
            //sampler2D _Fansherender;
            //float4 _Fansherender_ST;
            sampler2D _ReflectionTexture;
            float4 _ReflectionTexture_ST;
            //sampler2D _Displace;
            //sampler2D _Normal;
            //sampler2D _Bubbles;
            
            fixed4 _TintColor,_OceanColorShallow,_OceanColorDeep;
            //samplerCUBE _Cubemap;
            //sampler2D _RefractionTex;
			//float4 _RefractionTex_TexelSize;
            //sampler2D _shuidiTex;
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_TexelSize;
            float4 _shuidiTex_ST;
            //float4 _Displace_ST;
            fixed _WaveXSpeed;
			fixed _WaveYSpeed;
            float _Distortion;
            float _FrenelScale;
            float _FlowStrength;
            sampler2D _WaveTex;
            float4 _WaveTex_ST;

            fixed _ForceX,_ForceY,_HeatTime,_AlphaParam,_BGSpeedX,_BGSpeedY;
            float4 _WaveA,_WaveB,_WaveC;

            float4 ApplyFog(float4 color , v2f i){
				float viewDistance = length(_WorldSpaceCameraPos - i.worldPos.xyz);
				#if FOG_DEPTH
					 viewDistance = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.worldPos.w);
				#endif
				UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
				color.rgb = lerp(unity_FogColor.rgb, color.rgb, saturate(unityFogFactor));
				return color ;
			
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NoiseTex);
                o.uv1 = TRANSFORM_TEX(v.texcoord, _BGTex);
                o.uv2 = v.texcoord;
                o.uv2.y = 1-o.uv2.y;
                o.uv2.x = 1-o.uv2.x;
                //o.uv3 = TRANSFORM_TEX(v.texcoord, _Fansherender);

                //o.uv3 = TRANSFORM_TEX(v.texcoord, _Displace);
                //float4 displcae = tex2Dlod(_Displace, float4(o.uv3, 0, 0));
                //v.vertex += float4(displcae.xyz, 0);
                
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                //o.worldNormal = normal;
                
				fixed3 worldNormal = o.worldNormal;  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.scrPos =  ComputeScreenPos(o.vertex);
                o.ScreenPos = ComputeScreenPos(o.vertex);

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
            #include "Assets/Shaders/Library/watertools.cginc"

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed3 normal = UnityObjectToWorldNormal(tex2D(_Normal, i.uv3).rgb);
                //fixed bubbles = tex2D(_Bubbles, i.uv3).r;
                
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
                fixed3 refrcol =  RefrColfromRT(tmp13,i.uv2)  ;
                float2 tmp14;
                tmp14.x = (_Time.x * _BGSpeedX);
                tmp14.y = (_Time.x * _BGSpeedY);
                float2 P_15 = ((i.uv1 + tmp14) + uvMain_8);

                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

                float4 fresnelReflectFactor = Fresnel(_FrenelScale,viewDir,bump);
                float4 fresnelReflectFactor1 = Fresnel(_FrenelScale,viewDir,lightDir);
                //fixed fresnel = saturate(_FrenelScale + (1 - _FrenelScale) * pow(1 - dot(bump, lightDir), 5));
                //half facing = saturate(dot(viewDir, normal));                
                //fixed3 oceanColor = lerp(_OceanColorShallow, _OceanColorDeep, facing);
                //fixed3 reflCol1 = ReflectUsingCubeMap(viewDir,bump,tmp13); 
                //fixed3 reflCol2 = ReflectUsingCamerasetting(i.uv3,tmp13);
                float3 reflCol3 = Reflect(i.ScreenPos,bump) * 3;
                //float3 reflCol3 = Reflect(i.ScreenPos,normalize(normal)) * 2;

                float3 tmp7 = reflCol3 * fresnelReflectFactor1  + refrcol *  (1 - fresnelReflectFactor1) ;            
                //float3 tmp7 = reflCol3 * fresnel * oceanColor  + refrcol * oceanColor * (1-fresnel) ;
                //float3 tmp7 = lerp(reflCol3,refrcol,fresnelReflectFactor1) ;

                fixed4 coll;
                coll = guangzhao(tmp4,tmp2,tmp7,tmp1,i.SHLighting);
                fixed4 col;
                col.w = coll.w; 
                col.rgb = coll * ApplyFog(coll,i) ;
                //col.rgb = tex2D(_ReflectionTexture,UV);
                //col.rgb = lerp(refrcol,tmp7,fresnel) ;

                return col;
            }
            ENDCG
        }
    }
    //FallBack "Diffuse"
    
}
