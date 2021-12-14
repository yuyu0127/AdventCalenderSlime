Shader "Slime/Step8"
{
    Properties {}
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" // 透過できるようにする
        }

        Pass
        {
            ZWrite On // 深度を書き込む
            Blend SrcAlpha OneMinusSrcAlpha // 透過できるようにする

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // 入力データ用の構造体
            struct input
            {
                float4 vertex : POSITION; // 頂点座標
            };

            // vertで計算してfragに渡す用の構造体
            struct v2f
            {
                float4 pos : POSITION1; // ピクセルワールド座標
                float4 vertex : SV_POSITION; // 頂点座標
            };

            // 出力データ用の構造体
            struct output
            {
                float4 col: SV_Target; // ピクセル色
                float depth : SV_Depth; // 深度
            };

            // 入力 -> v2f
            v2f vert(const input v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld, v.vertex); // ローカル座標をワールド座標に変換
                return o;
            }

            // 球の距離関数
            float4 sphereDistanceFunction(float4 sphere, float3 pos)
            {
                return length(sphere.xyz - pos) - sphere.w;
            }

            // 深度計算
            inline float getDepth(float3 pos)
            {
                const float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));

                float z = vpPos.z / vpPos.w;
                #if defined(SHADER_API_GLCORE) || \
                    defined(SHADER_API_OPENGL) || \
                    defined(SHADER_API_GLES) || \
                    defined(SHADER_API_GLES3)
                return z * 0.5 + 0.5;
                #else
                return z;
                #endif
            }

            #define MAX_SPHERE_COUNT 256 // 最大の球の個数
            float4 _Spheres[MAX_SPHERE_COUNT]; // 球の座標・半径を格納した配列
            fixed3 _Colors[MAX_SPHERE_COUNT]; // 球の色を格納した配列
            int _SphereCount; // 処理する球の個数

            // smooth min関数
            float smoothMin(float x1, float x2, float k)
            {
                return -log(exp(-k * x1) + exp(-k * x2)) / k;
            }

            // 全ての球との最短距離を返す
            float getDistance(float3 pos)
            {
                float dist = 100000;
                for (int i = 0; i < _SphereCount; i++)
                {
                    dist = smoothMin(dist, sphereDistanceFunction(_Spheres[i], pos), 3);
                }
                return dist;
            }

            // 色の算出
            fixed3 getColor(const float3 pos)
            {
                fixed3 color = fixed3(0, 0, 0);
                float weight = 0.01;
                for (int i = 0; i < _SphereCount; i++)
                {
                    const float distinctness = 0.7;
                    const float4 sphere = _Spheres[i];
                    const float x = clamp((length(sphere.xyz - pos) - sphere.w) * distinctness, 0, 1);
                    const float t = 1.0 - x * x * (3.0 - 2.0 * x);
                    color += t * _Colors[i];
                    weight += t;
                }
                color /= weight;
                return float4(color, 1);
            }

            // 法線の算出
            float3 getNormal(const float3 pos)
            {
                float d = 0.0001;
                return normalize(float3(
                    getDistance(pos + float3(d, 0.0, 0.0)) - getDistance(pos + float3(-d, 0.0, 0.0)),
                    getDistance(pos + float3(0.0, d, 0.0)) - getDistance(pos + float3(0.0, -d, 0.0)),
                    getDistance(pos + float3(0.0, 0.0, d)) - getDistance(pos + float3(0.0, 0.0, -d))
                ));
            }

            // v2f -> 出力
            output frag(const v2f i)
            {
                output o;

                float3 pos = i.pos.xyz; // レイの座標（ピクセルのワールド座標で初期化）
                const float3 rayDir = normalize(pos.xyz - _WorldSpaceCameraPos); // レイの進行方向
                const half3 halfDir = normalize(_WorldSpaceLightPos0.xyz - rayDir); // ハーフベクトル

                for (int i = 0; i < 40; i++)
                {
                    // posと球との最短距離
                    float dist = getDistance(pos);

                    // 距離が0.01以下になったら、色と深度を書き込んで処理終了
                    if (dist < 0.01)
                    {
                        fixed3 norm = getNormal(pos); // 法線
                        fixed3 baseColor = getColor(pos);

                        const float rimPower = 2;
                        const float rimRate = pow(1 - abs(dot(norm, rayDir)), rimPower);
                        const fixed3 rimColor = fixed3(1.5, 1.5, 1.5);

                        float highlight = dot(norm, halfDir) > 0.99 ? 1 : 0; // ハイライト
                        fixed3 color = clamp(lerp(baseColor, rimColor, rimRate) + highlight, 0, 1); // 色
                        float alpha = clamp(lerp(0.2, 4, rimRate) + highlight, 0, 1); // 不透明度

                        o.col = fixed4(color, alpha); // 塗りつぶし
                        o.depth = getDepth(pos); // 深度書き込み
                        return o;
                    }

                    // レイの方向に行進
                    pos += dist * rayDir;
                }

                // 衝突判定がなかったら透明にする
                o.col = 0;
                o.depth = 0;
                return o;
            }
            ENDCG
        }
    }
}