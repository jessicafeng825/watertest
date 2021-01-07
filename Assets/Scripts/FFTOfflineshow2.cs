using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFTOfflineshow2 : MonoBehaviour
{
    public Material OceanMaterial;  //渲染海洋的材质
    //public int count = 0;//128
    public int MeshSize = 250;		//网格长宽数量
    public float MeshLength = 10;	//网格长度
    public float TimeScale = 1;

    private int[] vertIndexs;		//网格三角形索引
    private Vector3[] positions;    //位置
    private Vector2[] uvs; 			//uv坐标
    private Mesh mesh;
    private MeshFilter filetr;
    private MeshRenderer render;//渲染网格

    private float timer;//计时器
    private Texture[] texturedisplace;//贴图数组
    private Texture[] texturenormal;
    //private Texture[] texturebubble;

    private string materialTexture1 = "Textures/res/Displace/";
    private string materialTexture2 = "Textures/res/Normal/";
    //private string materialTexture3 = "Textures/res/Bubbles/";

    public int textureCount = 128;//每组有128张贴图
    private int index = 0;//索引
    public float changeTime = 0.5f;



    private void Awake()
    {
        //添加网格及渲染组件
        filetr = gameObject.GetComponent<MeshFilter>();
        if (filetr == null)
        {
            filetr = gameObject.AddComponent<MeshFilter>();
        }
        render = gameObject.GetComponent<MeshRenderer>();
        if (render == null)
        {
            render = gameObject.AddComponent<MeshRenderer>();
        }
        //mesh = gameObject.GetComponent<Mesh>();
        //filetr.mesh = mesh;
        //render.material = OceanMaterial;
    }
    // Start is called before the first frame update
    void Start()
    {
        timer = 0;
        texturedisplace = new Texture[textureCount];
        texturenormal = new Texture[textureCount];
        //texturebubble = new Texture[textureCount];
        for (int i = 0; i < texturedisplace.Length; i++)
        {
            texturedisplace[i] = Resources.Load(materialTexture1 + (i)) as Texture;
        }
        
        for (int i = 0; i < texturenormal.Length; i++)
        {
            texturenormal[i] = Resources.Load(materialTexture2 + (i)) as Texture;
        }
        /*
        for (int i = 0; i < texturebubble.Length; i++)
        {
            texturebubble[i] = Resources.Load(materialTexture3 + (i)) as Texture;
        }
        */

        //创建网格
        //CreateMesh();

    }

    // Update is called once per frame
    void Update()
    {
        
        timer += Time.deltaTime * TimeScale;
        if(timer > changeTime){
            timer = 0;
            OceanMaterial.SetTexture("_Displace",texturedisplace[index]);
            OceanMaterial.SetTexture("_Normal",texturenormal[index]);
            //OceanMaterial.SetTexture("_Bubbles",texturebubble[index]);

            index = (index + 1) % texturedisplace.Length;
        }
    }
    private void SetTex(string file1,string file2,string file3){
        OceanMaterial.SetTexture("_Displace",(Texture)Resources.Load(file1));
        OceanMaterial.SetTexture("_Normal", (Texture)Resources.Load(file2));
        //OceanMaterial.SetTexture("_Bubbles", (Texture)Resources.Load(file3));

    }
    /*
    /// <summary>
    /// 创建网格
    /// </summary>
    private void CreateMesh()
    {
        //fftSize = (int)Mathf.Pow(2, FFTPow);
        vertIndexs = new int[(MeshSize - 1) * (MeshSize - 1) * 6];
        positions = new Vector3[MeshSize * MeshSize];
        uvs = new Vector2[MeshSize * MeshSize];

        int inx = 0;
        for (int i = 0; i < MeshSize; i++)
        {
            for (int j = 0; j < MeshSize; j++)
            {
                int index = i * MeshSize + j;
                positions[index] = new Vector3((j - MeshSize / 2.0f) * MeshLength / MeshSize, 0, (i - MeshSize / 2.0f) * MeshLength / MeshSize);
                uvs[index] = new Vector2(j / (MeshSize - 1.0f), i / (MeshSize - 1.0f));

                if (i != MeshSize - 1 && j != MeshSize - 1)
                {
                    vertIndexs[inx++] = index;
                    vertIndexs[inx++] = index + MeshSize;
                    vertIndexs[inx++] = index + MeshSize + 1;

                    vertIndexs[inx++] = index;
                    vertIndexs[inx++] = index + MeshSize + 1;
                    vertIndexs[inx++] = index + 1;
                }
            }
        }
        mesh.vertices = positions;
        mesh.SetIndices(vertIndexs, MeshTopology.Triangles, 0);
        mesh.uv = uvs;
    }
    */
}
