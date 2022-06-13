using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
#if UNITY_EDITOR
using UnityEditor;
#endif

#if UNITY_EDITOR

[CustomEditor(typeof(RenderController))]
public class RenderControllerGUI : Editor
{
    //readonly string settingsLabel = "Settings";

    public override void OnInspectorGUI()
    {
        RenderController rc = (RenderController)target;

        serializedObject.Update();

        EditorGUILayout.Space();
        EditorGUILayout.PropertyField(serializedObject.FindProperty("GlobalIllumination"), true);
		EditorGUI.indentLevel = 1;
        EditorGUILayout.PropertyField(serializedObject.FindProperty("SkyReflection"), true);
        EditorGUILayout.PropertyField(serializedObject.FindProperty("GroundReflection"), true);
        EditorGUILayout.PropertyField(serializedObject.FindProperty("GIIntensity"), true);
        EditorGUI.indentLevel = 0;
        EditorGUILayout.Space();

        
        EditorGUI.indentLevel = 0;
        EditorGUILayout.Space();

        EditorGUILayout.PropertyField(serializedObject.FindProperty("RimLight"), true);
        EditorGUI.indentLevel = 1;
        EditorGUILayout.PropertyField(serializedObject.FindProperty("RimLightColor"), true);
        EditorGUILayout.PropertyField(serializedObject.FindProperty("RimLightIntensity"), true);
        EditorGUI.indentLevel = 0;
        EditorGUILayout.Space();

        EditorGUILayout.Space();
        EditorGUILayout.PropertyField(serializedObject.FindProperty("PostGrading"), true);
        EditorGUI.indentLevel = 1;
        //EditorGUILayout.PropertyField(serializedObject.FindProperty("Gain"), true);
        //EditorGUILayout.PropertyField(serializedObject.FindProperty("Tint"), true);
        //EditorGUILayout.PropertyField(serializedObject.FindProperty("Offset"), true);
        EditorGUILayout.PropertyField(serializedObject.FindProperty("Saturation"), true);
        EditorGUILayout.PropertyField(serializedObject.FindProperty("Vignette"), true);
        EditorGUILayout.PropertyField(serializedObject.FindProperty("Outline"), true);
        EditorGUI.indentLevel = 0;
        EditorGUILayout.Space();


        serializedObject.ApplyModifiedProperties();
    }
}
#endif

[ExecuteInEditMode]
public class RenderController : MonoBehaviour
{   
    public static RenderController Instance { get; private set; }

	public bool MainLight = true;
	public Light MainLightObj; 
	public Color MainLightColor = Color.white;
	[Range(0, 20000)]
	public float MainLightIntensity = 1.0f;
    public LightType mainLightType = 0;
    public Vector3 MainLightPosition;
    public Vector3 MainLightRotation;
    public LightType MainLightType = 0;

    public bool RimLight = true;
    public Color RimLightColor = Color.white;
    [Range(0, 1)]
    public float RimLightIntensity = 0.7f;

    public bool GlobalIllumination = true;
	public Color SkyReflection = Color.white;
	public Color GroundReflection = Color.grey;
	[Range(0, 5)]
	public float GIIntensity = 1.0f;

    public bool Fog = true;
    public Color FogColor = Color.white;
    [Range(0, 5.0f)]
    public float FogDensity = 0.5f;

    public bool PostGrading = true;
	[Range(0, 2)]
	public float Gain = 1.0f;
	public Color Tint = Color.white;
	public Color Offset = Color.gray;
	[Range(0, 2)]
	public float Saturation = 1;
    [Range(0, 5)]
    public float Vignette = 1.3f;

    [Range(0, 1)]
    public float Outline = 0.5f;


    public int ShaderLODInt = 800; 

	public bool InheritLightObj = true;
    
    private void Awake()
	{
		if (InheritLightObj) {

			var instance = Instance;

			if (instance != null) {
				MainLightObj = instance.MainLightObj;
			} 
		}
    }

    private void OnEnable()
	{
        Instance = this;
    }

    private void LateUpdate()
	{    
		UpdateShaderVariables();
    }
    
    bool isRenderControllerSelected()
    {
	#if UNITY_EDITOR
        foreach (GameObject go in Selection.gameObjects)
            if (go.GetComponent<RenderController>() != null)
                return true;
	#endif
        return false;
    }

    public void UpdateShaderVariables ()
	{
        Shader.SetGlobalVector( "_SkyReflection", GlobalIllumination ? SkyReflection * SkyReflection : Color.black);
		Shader.SetGlobalVector( "_GroundReflection", GlobalIllumination ? GroundReflection * GroundReflection : Color.black);
        Shader.SetGlobalFloat("_GIIntensity", GIIntensity);

        Shader.SetGlobalVector( "_MainLightColor", MainLight ? MainLightColor * MainLightIntensity : Color.black);
		if (MainLightObj) {
			Shader.SetGlobalVector("_MainLightPosition", MainLightObj.transform.position);
			Shader.SetGlobalVector("_MainLightDirection", -MainLightObj.transform.forward);
		}

        Shader.SetGlobalVector( "_RimColor", RimLight ? RimLightColor : Color.black);
        Shader.SetGlobalFloat ("_Rim",  RimLight ? RimLightIntensity : 0.0f);

		
        if (PostGrading)
		{
			Shader.SetGlobalVector ("_Gain", Gain * Tint);
			Shader.SetGlobalVector ("_Offset", new Vector3 (Offset.r - 0.5f, Offset.g - 0.5f, Offset.b - 0.5f));
			Shader.SetGlobalFloat ("_Saturation", Saturation);
            Shader.SetGlobalFloat ("_Vignette", Vignette);
             Shader.SetGlobalFloat ("_Outline", Outline);
		} else {
			Shader.SetGlobalVector ("_Gain", Color.white);
			Shader.SetGlobalVector ("_Offset", Color.black);
			Shader.SetGlobalFloat ("_Saturation", 1);
            Shader.SetGlobalFloat ("_Vignette", 0f);
            Shader.SetGlobalFloat ("_Outline", 0f);
		}
	}
}
