//MIT License
//
//Copyright (c) 2020 No Fakie Ltd
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

Shader "NoFakie/Unlit/VectorNoise"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        [MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
        [PerRendererData] _AlphaTex ("External Alpha", 2D) = "white" {}
        [PerRendererData] _EnableExternalAlpha ("Enable External Alpha", Float) = 0

        [Toggle(NOISE_TOGGLE)] _Noise("Noise", float) = 0
        [Toggle(DISPLACEMENT_TOGGLE)] _Displacement("Displacement", float) = 0

        _DisplacementSpeed ("DisplacementSpeedSpeed",Range(-100,100)) = 5
        _FrequencyX ("FrequencyX",Range(0,0.01)) = 0
        _AmplitudeX ("AmplitudeX",Range(-100,100)) = 1
        _FrequencyY ("FrequencyY",Range(0,0.01)) = 0
        _AmplitudeY ("AmplitudeY",Range(-100,100)) = 1
        _NoiseScale ("NoiseScale", Range(-100,100)) = 1
        _NoiseSnap ("NoiseSnap", Range(0.01,1)) = 0.1

        [HideInInspector] _RandomOffset ("RandomOffset", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex VectorVert
            #pragma fragment SpriteFrag
            #pragma target 2.0
            #pragma multi_compile_instancing
            #pragma multi_compile _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA
            #pragma shader_feature _ NOISE_TOGGLE
            #pragma shader_feature _ DISPLACEMENT_TOGGLE
            #include "UnitySprites.cginc"
            //#include "UnityShaderVariables.cginc"

            float _DisplacementSpeed;
            float _FrequencyX;
            float _AmplitudeX;
            float _FrequencyY;
            float _AmplitudeY;
            float _NoiseScale;
            float _NoiseSnap;
            float _RandomOffset;

            float random (float2 uv)
            {
                return frac(sin(dot(uv,float2(12.9898,78.233))) * 43758.5453123);
            }

            float3 random3(float3 c)
            {
                float j = 4096.0 * sin(dot(c,float3(17.0, 59.4, 15.0))) + _RandomOffset;
                float3 r;
                r.z = frac(512.0 * j);
                j *= .125;
                r.x = frac(512.0 * j);
                j *= .125;
                r.y = frac(512.0 * j);
                return r - 0.5;
            }

            inline float snap (float x, float snap)
            {
                return snap * round(x / snap);
            }

            v2f VectorVert(appdata_t IN)
            {
            #ifdef NOISE_TOGGLE
                float noiseTime = snap(_Time.y, _NoiseSnap);
                float2 noise = random3(IN.vertex.xyz + float3(noiseTime, 0.0, 0.0) ).xy * _NoiseScale;
                IN.vertex.xy += noise;
            #endif

            #ifdef DISPLACEMENT_TOGGLE
                float displacementTime = _Time * _DisplacementSpeed;
                float wX = cos(displacementTime + IN.vertex.x * _FrequencyX) * _AmplitudeX;
                float wY = cos(displacementTime + IN.vertex.y * _FrequencyY) * _AmplitudeY;

                IN.vertex.xy = float2(IN.vertex.x + wX, IN.vertex.y + wY);
            #endif

                v2f OUT;

                UNITY_SETUP_INSTANCE_ID (IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.vertex = UnityFlipSprite(IN.vertex, _Flip);
                OUT.vertex = UnityObjectToClipPos(OUT.vertex);
                OUT.texcoord = IN.texcoord;

                #ifdef UNITY_COLORSPACE_GAMMA
                fixed4 color = IN.color;
                #else
                fixed4 color = fixed4(GammaToLinearSpace(IN.color.rgb), IN.color.a);
                #endif

                OUT.color = color * _Color * _RendererColor;

                #ifdef PIXELSNAP_ON
                OUT.vertex = UnityPixelSnap (OUT.vertex);
                #endif

                return OUT;
            }
        ENDCG
        }
    }
}
