// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v1;

/*
“Copyright (c) 2023 Lyfebloc
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

/// @title Library with gas efficient alternatives to `abi.decode`
library ArgumentsDecoder {
  function decodeUint256(bytes memory data) internal pure returns (uint256) {
    uint256 value;
    assembly {
      // solhint-disable-line no-inline-assembly
      value := mload(add(data, 0x20))
    }
    return value;
  }

  function decodeBool(bytes memory data) internal pure returns (bool) {
    bool value;
    assembly {
      // solhint-disable-line no-inline-assembly
      value := eq(mload(add(data, 0x20)), 1)
    }
    return value;
  }

  function decodeTargetAndCalldata(bytes memory data)
    internal
    pure
    returns (address, bytes memory)
  {
    address target;
    bytes memory args;
    assembly {
      // solhint-disable-line no-inline-assembly
      target := mload(add(data, 0x14))
      args := add(data, 0x14)
      mstore(args, sub(mload(data), 0x14))
    }
    return (target, args);
  }

  function decodeTargetAndData(bytes calldata data)
    internal
    pure
    returns (address, bytes calldata)
  {
    address target;
    bytes calldata args;
    assembly {
      // solhint-disable-line no-inline-assembly
      target := shr(96, calldataload(data.offset))
    }
    args = data[20:];
    return (target, args);
  }
}