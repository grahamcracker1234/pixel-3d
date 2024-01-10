using UnityEngine;

public class Rotator : MonoBehaviour
{
    [SerializeField] float _speedX = 50f;
    [SerializeField] float _speedY = 50f;
    [SerializeField] float _speedZ = 50f;

    void Update()
    {
        var rotationX = _speedX * Time.deltaTime;
        var rotationY = _speedY * Time.deltaTime;
        var rotationZ = _speedZ * Time.deltaTime;

        transform.Rotate(rotationX, rotationY, rotationZ, Space.Self);
    }
}
