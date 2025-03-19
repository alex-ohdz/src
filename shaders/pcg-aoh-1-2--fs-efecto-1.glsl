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

// Parámetro S
uniform float u_param_s; // varia entre 0 y 1, por teclado.

// Parámetros varying ( 'in' aquí, 'out' en el vertex shader)
in vec4 v_posic_ecc;
in vec4 v_color;
in vec3 v_normal_ecc;
in vec2 v_coord_text;
in vec3 v_vec_obs_ecc;

layout(location = 0) out vec4 out_color_fragmento;

// Función para calcular la luminancia de un color
float luminance(vec3 color) {
    return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
}

// Función para calcular el MIL
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
    // consultar color del objeto en el centro del pixel ('color_obj')
    vec4 color_obj;
    if (u_eval_text) 
        color_obj = texture(u_tex, v_coord_text);
    else 
        color_obj = v_color;

    // Convertir a escala de grises
    float l = luminance(color_obj.rgb);
    vec3 color_gray = vec3(l, l, l);

    // Interpolar entre el color original y la escala de grises
    vec3 color_final = mix(color_obj.rgb, color_gray, u_param_s);

    // Aplicar iluminación si está activada
    if (u_eval_mil)
        color_final = EvalMIL(color_final);

    // Salida final
    out_color_fragmento = vec4(color_final, color_obj.a);
}
