using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshRenderer))]
public class ToolForWater : MonoBehaviour
{
    #region 提取反射贴图

    public enum TexSize
    {
        _128 = 128,
        _256 = 256,
        _512 = 512,
        _1024 = 1024
    };

    public TexSize TextureSize = TexSize._512;
    public int PlaneOffset = 0;
    public LayerMask ReflecetLayer=-1;
    private TexSize oldTexSize;
    
    private RenderTexture _reflectionTexture;
    private Camera _mainCamera;
    private Camera _reflCamera;

    private static bool s_InsideRendering = false;

    void Start()
    {
        _mainCamera = Camera.main;
    }

    //物体被渲染时会调用该方法
    void OnWillRenderObject()
    {
        if (!enabled || !GetComponent<Renderer>() || !GetComponent<Renderer>().sharedMaterial || !GetComponent<Renderer>().enabled||!_mainCamera)
            return;
        if (s_InsideRendering) return;
        s_InsideRendering = true;//反射相机也可能会渲染到这个水面从而无限递归，通过这个布尔值来确保只会在主相机渲染时调用一次
        
        CreateReflectCamAndTex(_mainCamera);
        CloneCameraModes(_mainCamera,_reflCamera);
        
        //获取反射平面
        Vector3 pos = transform.position;
        Vector3 normal = transform.up;
        float D = -Vector3.Dot(pos, normal) - PlaneOffset;
        Vector4 reflectPlane=new Vector4(normal.x,normal.y,normal.z,D);
        //计算反射矩阵
        Matrix4x4 reflection = CalculateReflectionMatrixByPlane(reflectPlane);
        Vector3 MainCamPos = _mainCamera.transform.position;
        Vector3 ReflCamPos = reflection.MultiplyPoint(MainCamPos);
        //设置反射相机的世界-相机矩阵
        _reflCamera.worldToCameraMatrix = _mainCamera.worldToCameraMatrix * reflection;
        //计算剪裁空间的反射平面
        Vector4 clipPlane = CameraSpacePlane(_reflCamera, pos, normal, PlaneOffset);
        //设置反射相机的投影矩阵
        Matrix4x4 projection=_mainCamera.projectionMatrix;
        projection = CalculateProjectionBasePlane(projection, clipPlane);
        _reflCamera.projectionMatrix = projection;
        //避免渲染到layer=water这一层的物体 避免反射贴图渲染水体本身
        _reflCamera.cullingMask = ~(1 << 4) & ReflecetLayer.value; 
        
        //渲染反射贴图
        _reflCamera.targetTexture = _reflectionTexture;
        //反射相机用的是左手坐标系，而常规的相机用的左手坐标系，而且很多计算也反了
        GL.invertCulling = true;
        _reflCamera.transform.position = ReflCamPos;
        Vector3 eular = _mainCamera.transform.eulerAngles;
        _reflCamera.transform.eulerAngles=new Vector3(0,eular.y,eular.z);
        _reflCamera.Render();
        _reflCamera.transform.position=MainCamPos;
        GL.invertCulling = false;
        
        //传递反射贴图给需要的材质
        Material[] materials = GetComponent<Renderer>().sharedMaterials;
        foreach (var m in materials)
        {
            if (m.HasProperty("_ReflectionTexture"))
            {
                m.SetTexture("_ReflectionTexture",_reflectionTexture);
            }
        }

        s_InsideRendering = false;
    }
    
    //关闭时清除
    void OnDisable()
    {
        if (_reflectionTexture)
        {
            DestroyImmediate(_reflectionTexture);
            _reflectionTexture = null;
        }

        if (_reflCamera)
        {
            DestroyImmediate(_reflCamera.gameObject);
            _reflCamera = null;
        }
    }
   
    
    public void CreateReflectCamAndTex(Camera sourceCam)
    {
        if (!_reflectionTexture || oldTexSize != TextureSize)
        {
            if(!_reflectionTexture) DestroyImmediate(_reflectionTexture);
            _reflectionTexture=new RenderTexture((int)TextureSize,(int)TextureSize,0);
            _reflectionTexture.name = "_ReflectionTex" + GetInstanceID();
            _reflectionTexture.isPowerOfTwo = true;
            _reflectionTexture.hideFlags = HideFlags.DontSave;
            _reflectionTexture.antiAliasing = 4;
            _reflectionTexture.anisoLevel = 0;
            oldTexSize = TextureSize;
        }

        if (!_reflCamera)
        {
            GameObject go=new GameObject("Reflection Camera id" + GetInstanceID() + " for " + _mainCamera.GetInstanceID(), typeof(Camera), typeof(Skybox));
            _reflCamera = go.GetComponent<Camera>();
            _reflCamera.enabled = false;
            _reflCamera.transform.position = transform.position;
            _reflCamera.transform.rotation = transform.rotation;
            _reflCamera.GetComponent<FlareLayer>();
            go.hideFlags = HideFlags.HideAndDontSave;
        }
        
    }
    
    public static void CloneCameraModes(Camera src, Camera dest)
    {
        if (dest == null)
            return;
        dest.clearFlags = src.clearFlags;
        dest.backgroundColor = src.backgroundColor;
        if (src.clearFlags == CameraClearFlags.Skybox)
        {
            Skybox sky = src.GetComponent(typeof(Skybox)) as Skybox;
            Skybox mysky = dest.GetComponent(typeof(Skybox)) as Skybox;
            if (!sky || !sky.material)
            {
                mysky.enabled = false;
            }
            else
            {
                mysky.enabled = true;
                mysky.material = sky.material;
            }
        }
        
        dest.depth = src.depth;
        dest.farClipPlane = src.farClipPlane;
        dest.nearClipPlane = src.nearClipPlane;
        dest.orthographic = src.orthographic;
        dest.fieldOfView = src.fieldOfView;
        dest.aspect = src.aspect;
        dest.orthographicSize = src.orthographicSize;
    }
    
    //计算关于反射平面的反射矩阵，来得到主相机的镜像位置位置 
    /*若平面表示为(nx,ny,nz,d)则关于它的反射矩阵为
     |1-2nx*nx,-2ny*nx,-2nz*nx,-2d*nx|
     |-2nx*ny,1-2ny*ny,-2nz*ny,-2d*ny|
     |-2nx*nz,-2ny*nz,1-2nz*nz,-2d*nz|
     |      0,      0,       0,     1|
    */
    static Matrix4x4 CalculateReflectionMatrixByPlane(Vector4 plane)
    {
        Matrix4x4 reflectionMat=new Matrix4x4();
        
        reflectionMat.m00 = 1f - 2f * plane.x * plane.x;
        reflectionMat.m01 = -2f * plane.x * plane.y;
        reflectionMat.m02 = -2f * plane.x * plane.z;
        reflectionMat.m03 = -2f * plane.x * plane.w;

        reflectionMat.m10 = -2f * plane.y * plane.x;
        reflectionMat.m11 = 1f - 2f * plane.y * plane.y;
        reflectionMat.m12 = -2f * plane.y * plane.z;
        reflectionMat.m13 = -2f * plane.y * plane.w;

        reflectionMat.m20 = -2f * plane.z * plane.x;
        reflectionMat.m21 = -2f * plane.z * plane.y;
        reflectionMat.m22 = 1f - 2f * plane.z * plane.z;
        reflectionMat.m23 = -2f * plane.z * plane.w;

        reflectionMat.m30 = 0f;
        reflectionMat.m31 = 0f;
        reflectionMat.m32 = 0f;
        reflectionMat.m33 = 1f;

        return reflectionMat;
    }
    
    //用于将反射平面转换成在反射相机中的表示 
    static Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float planeOffset)
    {
        Vector3 wPos = pos + normal * planeOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cPos = m.MultiplyPoint(wPos);
        Vector3 cNormal = m.MultiplyVector(normal).normalized;
        return  new Vector4(cNormal.x,cNormal.y,cNormal.z,-Vector3.Dot(cPos,cNormal));
    }
    
    //修改反射相机的投影矩阵，使之以反射面为近平面(这样水面下的东西就不会被渲染进反射贴图)
    static Matrix4x4 CalculateProjectionBasePlane(Matrix4x4 projectMat,Vector4 clipPlane)
    {
        Vector4 pQ=new Vector4(sgn(clipPlane.x),sgn(clipPlane.y),1.0f,1.0f);
        Vector3 cQ = projectMat.inverse * pQ;
        //矩阵第三行替换为 M3=-2cQ.z*clipPlane/(C·cQ)+<0,0,1,0> 
        Vector4 c = clipPlane * (-2.0F / (Vector4.Dot(clipPlane, cQ)));
        projectMat.m20=c.x+projectMat.m30;
        projectMat.m21 = c.y + projectMat.m31;
        projectMat.m22 = c.z + projectMat.m32;
        projectMat.m23 = c.w + projectMat.m33;
        return projectMat;
    }
    
    //Mathf.Sign()在a=0时返回1 所以得自己写一个
    static float sgn (float a)
    {
        if (a > 0.0f) return 1.0f;
        if (a < 0.0f) return -1.0f;
        return 0.0f;
    }
    
    
    
    
    
    #endregion
    
    /*
    #region 将水深写入顶点颜色

    public void ApplyDepthToVertexColor()
    {
        MeshFilter mf = GetComponent<MeshFilter>();
        Mesh mesh = mf.sharedMesh;
        Vector3 s = transform.localScale;
        Color[] vertexColor=new Color[mesh.vertices.Length];
        for (int i = 0; i < mesh.vertices.Length; i++)
        {
            Vector3 v = mesh.vertices[i];
            Vector3 pos = new Vector3(v.x*s.x,v.y*s.y,v.z*s.z)+ transform.position;
            Ray ray=new Ray(pos,Vector3.down);
            RaycastHit info;
            float d;
            //对地面做射线检测得到深度 默认湖底的层为Ground
            if(Physics.Raycast(ray, out info,100,LayerMask.GetMask("Ground")))
            {
                d = info.distance;
            }else
            {
                d = -1;
            }
            vertexColor[i]=new Color(d/10,0,0);
        }
        mesh.colors = vertexColor;
        mf.mesh = mesh;
        
        
    }

    #endregion
    */
}

