// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import 'trigonometry.sol/Trigonometry.sol';

library Vector {
  using Trigonometry for uint;
  int constant PI = 0x2000;
  int constant PI2 = 0x4000;
  int constant ONE = 0x8000;

  struct Struct {
    int x; // fixed point * ONE
    int y; // fixed point * ONE
  }

  function vector(int _x, int _y) internal pure returns (Struct memory newVector) {
    newVector.x = _x * ONE;
    newVector.y = _y * ONE;
  }

  function vectorWithAngle(int _angle, int _radius) internal pure returns (Struct memory newVector) {
    uint angle = uint(_angle + (PI2 << 64));
    newVector.x = _radius * angle.cos();
    newVector.y = _radius * angle.sin();
  }

  function div(Struct memory _vector, int _value) internal pure returns (Struct memory newVector) {
    newVector.x = _vector.x / _value;
    newVector.y = _vector.y / _value;
  }

  function mul(Struct memory _vector, int _value) internal pure returns (Struct memory newVector) {
    newVector.x = _vector.x * _value;
    newVector.y = _vector.y * _value;
  }

  function add(Struct memory _vector, Struct memory _vector2) internal pure returns (Struct memory newVector) {
    newVector.x = _vector.x + _vector2.x;
    newVector.y = _vector.y + _vector2.y;
  }

  function rotate(Struct memory _vector, int _angle) internal pure returns (Struct memory newVector) {
    uint angle = uint(_angle + (PI2 << 64));
    int cos = angle.cos();
    int sin = angle.sin();
    newVector.x = (cos * _vector.x - sin * _vector.y) / ONE;
    newVector.y = (sin * _vector.x + cos * _vector.y) / ONE;
  }
}