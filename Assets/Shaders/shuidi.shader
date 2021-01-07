Shader "Unlit/shuidi"
{
    Properties
    {
        _TintColor("Color",Color) = (0, 0.15, 0.115, 1)
        _MainTex ("Texture", 2D) = "white" {}
        //unity_Lightmap ("Texture", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float4 texcoord1  : TEXCOORD1;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                
                #ifndef LIGHTMAP_OFF
                float2 uv2 : TEXCOORD3; //lightmap光照
                #endif

                half3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 vertex : SV_POSITION;
                float Fog : TEXCOORD5;

                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _TintColor;
            //sampler2D unity_Lightmap;
            //float4 unity_LightmapST;

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
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;

                #ifndef LIGHTMAP_OFF
                o.uv2 = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.xy;
                #endif
                

                #if APPLY_FOG
				o.worldPos.w = o.vertex.z;
				#endif

                o.Fog = ((o.vertex.z * unity_FogParams.z) + unity_FogParams.w);

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _TintColor;
                // apply fog
                col.rgb = col * ApplyFog(col,i);
                #ifndef LIGHTMAP_OFF
                float3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uv2));
                col.rgb *= lm*2;
                #endif
                //float f = 1;
                //return f;
                return col;
            }
            ENDCG
        }
    }
}
