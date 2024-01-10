using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IsometricCameraPivot : MonoBehaviour
{

    float _targetAngleY;
    float _currentAngleY;
    float _targetAngleX;
    float _currentAngleX;

    [SerializeField] float _mouseSensitivity = 2;
    [SerializeField] float _rotationSpeed = 5;

    void Awake()
    {
        _targetAngleY = transform.eulerAngles.y;
        _targetAngleX = transform.eulerAngles.x;
    }


    void Update()
    {
        float mouseX = Input.GetAxis("Mouse X");
        float mouseY = Input.GetAxis("Mouse Y");

        if (Input.GetMouseButton(0))
        {
            _targetAngleY += mouseX * _mouseSensitivity;
            _targetAngleX -= mouseY * _mouseSensitivity / 3;
        }
        else
        {
            _targetAngleY = Mathf.Round(_targetAngleY / 45) * 45;
            _targetAngleX = Mathf.Round(_targetAngleX / 15) * 15;
        }

        _targetAngleY = (_targetAngleY + 360) % 360;
        _targetAngleX = Mathf.Clamp(_targetAngleX, 30, 60);

        _currentAngleY = Mathf.LerpAngle(transform.eulerAngles.y, _targetAngleY, Time.deltaTime * _rotationSpeed);
        _currentAngleX = Mathf.LerpAngle(transform.eulerAngles.x, _targetAngleX, Time.deltaTime * _rotationSpeed);

        if (Mathf.Abs(_currentAngleY - _targetAngleY) < 0.1f) _currentAngleY = _targetAngleY;
        if (Mathf.Abs(_currentAngleX - _targetAngleX) < 0.1f) _currentAngleX = _targetAngleX;

        transform.rotation = Quaternion.Euler(_currentAngleX, _currentAngleY, 0);
    }
}
