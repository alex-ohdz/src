#version 330 core

// Máximo número de fuentes de luz
const int max_num_luces = 8;

// Parámetros uniformes
uniform bool u_eval_text;
uniform bool u_eval_mil;
uniform sampler2D u_tex;
uniform int u_num_luces;
uniform vec4 u_pos_dir_luz_ec[max_num_luces];
uniform vec3 u_color_luz[max_num_luces];
uniform float u_mil_ka;
uniform float u_mil_kd;
uniform float u_mil_ks;
uniform float u_mil_exp;

// Parámetro de control
uniform float u_param_s;  // Controla el nivel de descarte de fragmentos

// Parámetros varying desde el Vertex Shader
in vec4 v_posic_ecc;
in vec4 v_color;
in vec3 v_normal_ecc;
in vec2 v_coord_text;
in vec3 v_vec_obs_ecc;

layout(location = 0) out vec4 out_color_fragmento;

// Función para calcular el MIL (Modelo de Iluminación Local)
vec3 EvalMIL(vec3 color_obj) {
    vec3 v = normalize(v_vec_obs_ecc);
    vec3 n = normalize(v_normal_ecc);
    vec3 col_suma = vec3(0.0);

    for (int i = 0; i < u_num_luces; i++) {
        vec3 l = normalize(u_pos_dir_luz_ec[i].xyz - v_posic_ecc.xyz);
        float nl = max(dot(n, l), 0.0);
        float hn = max(dot(n, normalize(l + v)), 0.0);

        vec3 col = color_obj * (u_mil_kd * nl) + pow(hn, u_mil_exp) * u_mil_ks;
        col_suma += u_color_luz[i] * (u_mil_ka * color_obj + col);
    }

    return col_suma;
}

void main() {
    // Obtener el color original del fragmento desde la textura o la interpolación de vértices
    vec4 color_obj = u_eval_text ? texture(u_tex, v_coord_text) : v_color;

    // Aplicar iluminación antes del descarte
    if (u_eval_mil) {
        color_obj.rgb = EvalMIL(color_obj.rgb);
    }

    // Corrección: Asegurar que el blanco puro no se modifica
    vec3 color_corrected = clamp(color_obj.rgb, vec3(0.0), vec3(1.0));

    // Calcular la distancia euclídea al color blanco y normalizarla
    float d = length(color_corrected - vec3(1.0)) / sqrt(3.0);

    // Calcular la tolerancia de descarte basada en s
    float t = 1.0 - u_param_s;

    // Aplicar un umbral para evitar errores con valores cercanos a 1.0
    if (d > t && d > 0.01) {
        discard;
    }

    // Salida final
    out_color_fragmento = vec4(color_corrected, color_obj.a);
}
