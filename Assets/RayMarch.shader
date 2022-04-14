Shader "Make/RayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 3.0
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform float max_distance;
            uniform float4 _sphere1;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray:TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv.xy;

                o.ray = _CamFrustum[(int)index].xyz;

                o.ray /= abs(o.ray.z);
                o.ray = mul(_CamToWorld, o.ray);
                return o;
            }
            float sdSphere(float3 p,float s)
            {
                //거리함수 참조:https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
                return length(p) - s;
            }

            float distanceField(float3 p)
            {
                float Sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
                return Sphere1;
            }

            fixed4 rayMarching(float3 ro, float3 rd)
            {
                float4 result = float4(1, 1, 1, 1);
                const int max_iteration = 64;//최대 반복 수
                float t = 0;//광선 방향을 따라 이동한 거리

                for (int i = 0; i < max_iteration; i++)
                {
                    if (t > max_distance)
                    {
                        //Enviroment
                        result = fixed4(rd, 1);
                        break;
                    }

                    float3 p = ro + rd * t;
                    //거리 함수를 이용하기 위해서는 각 물체들에 대한 거리가 필요함으로 이것을 확인한다.
                    float d = distanceField(p);
                    if (d < 0.01)//거리가 0.01 이하라는 뜻은 그자리에 무언가 있다는 뜻이다.
                    {
                        //shading
                        result = fixed4(1, 1, 1, 1);//그 자리를 흰색으로 칠한다.
                        break;
                    }
                    t += d;
                }
                return result;
            }

            fixed4 frag(v2f i) : SV_Target
            {
              float3 rayDirection = normalize(i.ray.xyz);//ray의 방향을 노말화
              float3 rayOrigin = _WorldSpaceCameraPos;//ray의 시작점
              float4 result = rayMarching(rayOrigin, rayDirection);
              return result;
            }
            ENDCG
        }
    }
}
