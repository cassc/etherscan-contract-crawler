// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "./Vector.sol";

library Path {
  function roundedCorner(Vector.Struct memory _vector) internal pure returns(uint) {
    return uint(_vector.x/0x8000) + (uint(_vector.y/0x8000) << 32) + (566 << 64);
  }

  function sharpCorner(Vector.Struct memory _vector) internal pure returns(uint) {
    return uint(_vector.x/0x8000) + (uint(_vector.y/0x8000) << 32) + (0x1 << 80);
  }

  function closedPath(uint[] memory points) internal pure returns(bytes memory newPath) {
    uint length = points.length;
    assembly{
      function toString(_wbuf, _value) -> wbuf {
        let len := 2
        let cmd := 0
        if gt(_value,9) {
          if gt(_value,99) {
            if gt(_value,999) {
              cmd := or(shl(8, cmd), add(48, div(_value, 1000))) 
              len := add(1, len)
              _value := mod(_value, 1000)
            }
            cmd := or(shl(8, cmd), add(48, div(_value, 100)))
            len := add(1, len)
            _value := mod(_value, 100)
          }
          cmd := or(shl(8, cmd), add(48, div(_value, 10)))
          len := add(1, len)
          _value := mod(_value, 10)
        }
        cmd := or(or(shl(16, cmd), shl(8, add(48, _value))), 32)

        mstore(_wbuf, shl(sub(256, mul(len, 8)), cmd))
        wbuf := add(_wbuf, len)
      }

      // dynamic allocation
      newPath := mload(0x40)
      let wbuf := add(newPath, 0x20)
      let rbuf := add(points, 0x20)

      let wordP := mload(add(rbuf, mul(sub(length,1), 0x20)))
      let word := mload(rbuf)
      for {let i := 0} lt(i, length) {i := add(i, 1)} {
        let x := and(word, 0xffffffff)
        let y := and(shr(32, word), 0xffffffff)
        let r := and(shr(64, word), 0xffff)
        let sx := div(add(x, and(wordP, 0xffffffff)),2)
        let sy := div(add(y, and(shr(32, wordP), 0xffffffff)),2)
        if eq(i, 0) {
          mstore(wbuf, shl(248, 0x4D)) // M
          wbuf := add(wbuf, 1)
          wbuf := toString(wbuf, sx)
          wbuf := toString(wbuf, sy)
        }
        
        let wordN := mload(add(rbuf, mul(mod(add(i,1), length), 0x20)))
        {
          let ex := div(add(x, and(wordN, 0xffffffff)),2)
          let ey := div(add(y, and(shr(32, wordN), 0xffffffff)),2)

          switch and(shr(80, word), 0x01) 
            case 0 {
              mstore(wbuf, shl(248, 0x43)) // C
              wbuf := add(wbuf, 1)
              x := mul(x, r)
              y := mul(y, r)
              r := sub(1024, r)
              wbuf := toString(wbuf, div(add(x, mul(sx, r)),1024))
              wbuf := toString(wbuf, div(add(y, mul(sy, r)),1024))
              wbuf := toString(wbuf, div(add(x, mul(ex, r)),1024))
              wbuf := toString(wbuf, div(add(y, mul(ey, r)),1024))
            }
            default {
              mstore(wbuf, shl(248, 0x4C)) // L
              wbuf := add(wbuf, 1)
              wbuf := toString(wbuf, x)
              wbuf := toString(wbuf, y)
            }
          wbuf := toString(wbuf, ex)
          wbuf := toString(wbuf, ey)
        }
        wordP := word
        word := wordN
      }

      mstore(newPath, sub(sub(wbuf, newPath), 0x20))
      mstore(0x40, wbuf)
    }
  }

  function decode(bytes memory body) internal pure returns (bytes memory) {
    bytes memory ret;
    assembly{
      let bodyMemory := add(body, 0x20)
      let length := div(mul(mload(body), 2), 3)
      ret := mload(0x40)
      let retMemory := add(ret, 0x20)
      let data
      for {let i := 0} lt(i, length) {i := add(i, 1)} {
        if eq(mod(i, 16), 0) {
          data := mload(bodyMemory) // reading 8 extra bytes
          bodyMemory := add(bodyMemory, 24)
        }
        let low
        let high
        switch mod(i, 2)
        case 0 {
          low := shr(248, data)
          high := and(shr(240, data), 0x0f)
        }
        default {
          low := and(shr(232, data), 0xff)
          high := and(shr(244, data), 0x0f)
          data := shl(24, data)
        }
        
        switch high
        case 0 {
          if or(and(gt(low, 64), lt(low, 91)), and(gt(low, 96), lt(low, 123))) {
            mstore(retMemory, shl(248, low))
            retMemory := add(retMemory, 1)
          }
        }
        default {
          let cmd := 0
          let lenCmd := 2 // last digit and space
          // SVG value: undo (value + 1024) + 0x100 
          let value := sub(add(shl(8, high), low), 0x0100)
          switch lt(value, 1024)
          case 0 {
            value := sub(value, 1024)
          }
          default {
            cmd := 45 // "-"
            lenCmd := 3
            value := sub(1024,value)
          }
          if gt(value,9) {
            if gt(value,99) {
              if gt(value,999) {
                cmd := or(shl(8, cmd), 49) // always "1"
                lenCmd := add(1, lenCmd)
                value := mod(value, 1000)
              }
              cmd := or(shl(8, cmd), add(48, div(value, 100)))
              lenCmd := add(1, lenCmd)
              value := mod(value, 100)
            }
            cmd := or(shl(8, cmd), add(48, div(value, 10)))
            lenCmd := add(1, lenCmd)
            value := mod(value, 10)
          }
          // last digit and space
          cmd := or(or(shl(16, cmd), shl(8, add(48, value))), 32)

          mstore(retMemory, shl(sub(256, mul(lenCmd, 8)), cmd))
          retMemory := add(retMemory, lenCmd)
        }
      }
      mstore(ret, sub(sub(retMemory, ret), 0x20))
      mstore(0x40, retMemory)
    }
    return ret;
  }
}