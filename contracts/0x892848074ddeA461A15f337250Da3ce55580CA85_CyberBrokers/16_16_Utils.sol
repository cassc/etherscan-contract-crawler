// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {

  /**
   * From https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
   **/

   function uint2bytes(uint _i) internal pure returns (bytes memory) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }
    return bstr;
  }

  function unpackNumberSetValues(uint _i, bool decimal, bool negative, bool percent) internal pure returns (bytes memory) {
    // Base case
    if (_i == 0) {
      if (percent) {
        return "0%";
      } else {
        return "0";
      }
    }

    // Kick off length with the slots needed to make room for, considering certain bits
    uint j = _i;
    uint len = (negative ? 1 : 0) + (percent ? 1 : 0) + (decimal ? 2 : 0);

    // See how many tens we need
    uint numTens;
    while (j != 0) {
      numTens++;
      j /= 10;
    }

    // Expand length
    // Special case: if decimal & numTens is less than 3, need to pad by 3 since we'll left-pad zeroes
    if (decimal && numTens < 3) {
      len += 3;
    } else {
      len += numTens;
    }

    // Now create the byte "string"
    bytes memory bstr = new bytes(len);

    // Index from right-most to left-most
    uint k = len - 1;

    // Percent character
    if (percent) {
      bstr[k--] = bytes1("%");
    }

    // The entire number
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }

    // If a decimal, we need to left-pad if the numTens isn't enough
    if (decimal) {
      while (numTens < 3) {
        bstr[k--] = bytes1("0");
        numTens++;
      }
      bstr[k--] = bytes1(".");

      unchecked {
        bstr[k--] = bytes1("0");
      }
    }

    // If negative, the last byte should be negative
    if (negative) {
      bstr[0] = bytes1("-");
    }

    return bstr;
  }

  /**
   * Reference pulled from https://gist.github.com/okwme/f3a35193dc4eb9d1d0db65ccf3eb4034
   **/

  function unpackHexColorValues(uint8 r, uint8 g, uint8 b) internal pure returns (bytes memory) {
    bytes memory rHex = Utils.uint2hexchar(r);
    bytes memory gHex = Utils.uint2hexchar(g);
    bytes memory bHex = Utils.uint2hexchar(b);
    bytes memory bstr = new bytes(7);
    bstr[6] = bHex[1];
    bstr[5] = bHex[0];
    bstr[4] = gHex[1];
    bstr[3] = gHex[0];
    bstr[2] = rHex[1];
    bstr[1] = rHex[0];
    bstr[0] = bytes1("#");
    return bstr;
  }

  function uint2hexchar(uint8 _i) internal pure returns (bytes memory) {
    uint8 mask = 15;
    bytes memory bstr = new bytes(2);
    bstr[1] = (_i & mask) > 9 ? bytes1(uint8(55 + (_i & mask))) : bytes1(uint8(48 + (_i & mask)));
    bstr[0] = ((_i >> 4) & mask) > 9 ? bytes1(uint8(55 + ((_i >> 4) & mask))) : bytes1(uint8(48 + ((_i >> 4) & mask)));
    return bstr;
  }

}