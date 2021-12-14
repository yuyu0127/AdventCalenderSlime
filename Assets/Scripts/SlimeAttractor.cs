using System;
using UnityEngine;

public class SlimeAttractor : MonoBehaviour
{
    private Rigidbody[] _rigidbodies;

    private void Start()
    {
        // 子のRigidbodyをすべて取得
        _rigidbodies = GetComponentsInChildren<Rigidbody>();
    }

    private void FixedUpdate()
    {
        var massCenter = Vector3.zero;
        foreach (var rb in _rigidbodies)
        {
            massCenter += rb.position;
        }

        massCenter /= _rigidbodies.Length;

        foreach (var rb in _rigidbodies)
        {
            var force = (massCenter - rb.position).normalized;
            rb.AddForce(force);
        }
    }
}