using UnityEngine;

public class WaterLevelShift : MonoBehaviour
{
    public float shift = 0.5f;
    public float speed = 0.5f;

    private float waterLevel = 0f;


    void Start()
    {
        waterLevel = transform.position.y;
    }

    void Update()
    {
        float newY = waterLevel + Mathf.Sin(Time.time * speed) * shift;
        transform.position = new Vector3(transform.position.x, newY, transform.position.z);
    }
}
