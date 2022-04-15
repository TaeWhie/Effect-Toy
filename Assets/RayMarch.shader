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
            uniform float3 _LightDir;

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
                return length(p) - s;//length(point - center) - radius;
            }

            float distanceField(float3 p)
            {
                float Sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
                return Sphere1;
            }

            float3 getNormal(float3 p)
            {
                //기존 포인트보다 미세하게 떨어진 위치에서 가장 가까운 표면까지의 거리를 계산하여, 그 차이 만틈 x,y,z를 구성한다.
                //노말은 상대적이기 떄문에 이와 같은 방법을 사용한다.
                const float2 offset = float2(0.001, 0.0);
                float3 n = float3(
                    distanceField(p + offset.xyy) - distanceField(p - offset.xyy),
                    distanceField(p + offset.yxy) - distanceField(p - offset.yxy),
                    distanceField(p + offset.yyx) - distanceField(p - offset.yyx)
                    );
                return normalize(n);//그리고 그것을 노말화 한다.
            }

            fixed4 rayMarching(float3 ro, float3 rd)
            {
                float4 result = float4(1, 1, 1, 1);
                const int max_iteration = 100;//최대 반복 수
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
                    float d = distanceField(p);//d는 현재 발사중인 레이로부터 가장 가까운 거리에 있는 표면까지의 거리 
                    if (d < 0.01)//거리가 0.01 이하라는 뜻은 그자리에 무언가 있다는 뜻이다.
                    {
                        //shading
                        float3 n = getNormal(p);
                        float light = dot(-_LightDir, n);//노말벡터와 라이트의 내적값으로 각도 차이에 따른 색을 변경한다.
                        result = fixed4(1,1,1,1)*light;//그 자리를 흰색으로 칠한다.
                        break;
                    }
                    t += d;//t는 누적값
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
