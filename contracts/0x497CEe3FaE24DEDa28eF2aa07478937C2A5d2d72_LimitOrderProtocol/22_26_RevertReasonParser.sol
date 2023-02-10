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

/// @title Library that allows to parse unsuccessful arbitrary calls revert reasons.
/// See https://solidity.readthedocs.io/en/latest/control-structures.html#revert for details.
/// Note that we assume revert reason being abi-encoded as Error(string) so it may fail to parse reason
/// if structured reverts appear in the future.
///
/// All unsuccessful parsings get encoded as Unknown(data) string
library RevertReasonParser {
  bytes4 private constant _PANIC_SELECTOR = bytes4(keccak256('Panic(uint256)'));
  bytes4 private constant _ERROR_SELECTOR = bytes4(keccak256('Error(string)'));

  function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
    if (data.length >= 4) {
      bytes4 selector;

      assembly {
        // solhint-disable-line no-inline-assembly
        selector := mload(add(data, 0x20))
      }

      // 68 = 4-byte selector + 32 bytes offset + 32 bytes length
      if (selector == _ERROR_SELECTOR && data.length >= 68) {
        uint256 offset;
        bytes memory reason;
        assembly {
          // solhint-disable-line no-inline-assembly
          // 36 = 32 bytes data length + 4-byte selector
          offset := mload(add(data, 36))
          reason := add(data, add(36, offset))
        }
        /*
                    revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                    also sometimes there is extra 32 bytes of zeros padded in the end:
                    https://github.com/ethereum/solidity/issues/10170
                    because of that we can't check for equality and instead check
                    that offset + string length + extra 36 bytes is less than overall data length
                */
        require(data.length >= 36 + offset + reason.length, 'Invalid revert reason');
        return string(abi.encodePacked(prefix, 'Error(', reason, ')'));
      }
      // 36 = 4-byte selector + 32 bytes integer
      else if (selector == _PANIC_SELECTOR && data.length == 36) {
        uint256 code;
        assembly {
          // solhint-disable-line no-inline-assembly
          // 36 = 32 bytes data length + 4-byte selector
          code := mload(add(data, 36))
        }
        return string(abi.encodePacked(prefix, 'Panic(', _toHex(code), ')'));
      }
    }

    return string(abi.encodePacked(prefix, 'Unknown(', _toHex(data), ')'));
  }

  function _toHex(uint256 value) private pure returns (string memory) {
    return _toHex(abi.encodePacked(value));
  }

  function _toHex(bytes memory data) private pure returns (string memory) {
    bytes16 alphabet = 0x30313233343536373839616263646566;
    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < data.length; i++) {
      str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
      str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
    }
    return string(str);
  }
}