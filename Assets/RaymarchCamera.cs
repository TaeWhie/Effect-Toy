using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RaymarchCamera : MonoBehaviour
{
    [SerializeField]
    public Shader _shader;

    public Material _raymarchMaterial
    {
        get
        {
            if(!_raymarchMat && _shader)
            {
                //이 클래스는 게임 실행 중에만 작동되는 것이 아니기 때문에, 이런 작업도 직접 해주어야한다.
                _raymarchMat = new Material(_shader);
                _raymarchMat.hideFlags = HideFlags.HideAndDontSave;//생성된 메터리얼을 보이지 않게 하고, 세이브를 하지 않는다.
            }
            return _raymarchMat;
        }
    }
    private Material _raymarchMat;

 
    public Camera _Camera
    {
        get
        {
            if(!_cam)
            {
                _cam = GetComponent<Camera>();
            }
            return _cam;
        }
    }
    private Camera _cam;

    public float _maxDistance;
    public Vector4 Sphere1;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(!_raymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        //shader에 있는 _CamFrustum,_CamToWorld,_CamWorldSpace에 값을 지정
        _raymarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_Camera));
        _raymarchMaterial.SetMatrix("_CamToWorld", _Camera.cameraToWorldMatrix);
        _raymarchMaterial.SetFloat("max_distance", _maxDistance);
        _raymarchMaterial.SetVector("_sphere1", Sphere1);
        //Quad를 생성하는 과정 Quad를 입방체 끝에다가 형성
        RenderTexture.active = destination;
        GL.PushMatrix();
        GL.LoadOrtho();
        _raymarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);

        //BL
        GL.MultiTexCoord2(0, 0.0f,0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        //BR
        GL.MultiTexCoord2(+0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }
    private Matrix4x4 CamFrustum(Camera cam)//카메라를 직접 설정하는 과정
    {
        //카메라를 형성하기 위해서는 입방체를 형성할 필요가 있는데, 입방체는 4개로 뻣어가는 벡터들을 통해 형성 할 수 있다.

        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);//중앙에서 부터 얼마나 기울어 졌는지

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);//위 왼쪽
        Vector3 TR = (-Vector3.forward + goRight + goUp);//위 오른쪽
        Vector3 BR = (-Vector3.forward + goRight - goUp);//아래 오른쪽
        Vector3 BL = (-Vector3.forward - goRight - goUp);//아래 왼쪽

        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);

        return frustum;
    }
}
