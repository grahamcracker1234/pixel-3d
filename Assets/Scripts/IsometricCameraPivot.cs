using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IsometricCameraPivot : MonoBehaviour
{

    float _targetAngle = 0;
    float _currentAngle = 0;

    [SerializeField] float _mouseSensitivity = 2;
    [SerializeField] float _rotationSpeed = 5;

    void Awake()
    {
        _targetAngle = transform.eulerAngles.y;
    }


    void Update()
    {
        float mouseX = Input.GetAxis("Mouse X");

        if (Input.GetMouseButton(0))
        {
            _targetAngle += mouseX * _mouseSensitivity;
        }
        else
        {
            _targetAngle = Mathf.Round(_targetAngle / 45) * 45;
        }

        _targetAngle = (_targetAngle + 360) % 360;
        _currentAngle = Mathf.LerpAngle(transform.eulerAngles.y, _targetAngle, Time.deltaTime * _rotationSpeed);
        if (Mathf.Abs(_currentAngle - _targetAngle) < 0.1f)
        {
            _currentAngle = _targetAngle;
        }
        transform.rotation = Quaternion.Euler(30, _currentAngle, 0);
    }
}
