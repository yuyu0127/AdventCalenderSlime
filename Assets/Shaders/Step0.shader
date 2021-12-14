Shader "Slime/Step0"
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

            // v2f -> 出力
            output frag(const v2f i)
            {
                output o;
                o.col = fixed4(i.pos.xyz, 0.5);
                o.depth = 1;
                return o;
            }
            ENDCG
        }
    }
}