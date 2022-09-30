// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

// Based on Uniswap's NFTDescriptor
library DescriptorUtils {
  using Strings for uint256;
  using Strings for uint32;

  function fixedPointToDecimalString(uint256 _value, uint8 _decimals) internal pure returns (string memory) {
    if (_value == 0) {
      return '0.0000';
    }

    bool _priceBelow1 = _value < 10**_decimals;

    // get digit count
    uint256 _temp = _value;
    uint8 _digits;
    while (_temp != 0) {
      _digits++;
      _temp /= 10;
    }
    // don't count extra digit kept for rounding
    _digits = _digits - 1;

    // address rounding
    (uint256 _sigfigs, bool _extraDigit) = _sigfigsRounded(_value, _digits);
    if (_extraDigit) {
      _digits++;
    }

    DecimalStringParams memory _params;
    if (_priceBelow1) {
      // 7 bytes ( "0." and 5 sigfigs) + leading 0's bytes
      _params.bufferLength = _digits >= 5 ? _decimals - _digits + 6 : _decimals + 2;
      _params.zerosStartIndex = 2;
      _params.zerosEndIndex = _decimals - _digits + 1;
      _params.sigfigIndex = _params.bufferLength - 1;
    } else if (_digits >= _decimals + 4) {
      // no decimal in price string
      _params.bufferLength = _digits - _decimals + 1;
      _params.zerosStartIndex = 5;
      _params.zerosEndIndex = _params.bufferLength - 1;
      _params.sigfigIndex = 4;
    } else {
      // 5 sigfigs surround decimal
      _params.bufferLength = 6;
      _params.sigfigIndex = 5;
      _params.decimalIndex = _digits - _decimals + 1;
    }
    _params.sigfigs = _sigfigs;
    _params.isLessThanOne = _priceBelow1;

    return _generateDecimalString(_params);
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    bytes memory _s = new bytes(40);
    for (uint256 _i = 0; _i < 20; _i++) {
      bytes1 _b = bytes1(uint8(uint256(uint160(_addr)) / (2**(8 * (19 - _i)))));
      bytes1 _hi = bytes1(uint8(_b) / 16);
      bytes1 _lo = bytes1(uint8(_b) - 16 * uint8(_hi));
      _s[2 * _i] = _char(_hi);
      _s[2 * _i + 1] = _char(_lo);
    }
    return string(abi.encodePacked('0x', string(_s)));
  }

  struct DecimalStringParams {
    // significant figures of decimal
    uint256 sigfigs;
    // length of decimal string
    uint8 bufferLength;
    // ending index for significant figures (funtion works backwards when copying sigfigs)
    uint8 sigfigIndex;
    // index of decimal place (0 if no decimal)
    uint8 decimalIndex;
    // start index for trailing/leading 0's for very small/large numbers
    uint8 zerosStartIndex;
    // end index for trailing/leading 0's for very small/large numbers
    uint8 zerosEndIndex;
    // true if decimal number is less than one
    bool isLessThanOne;
  }

  function _generateDecimalString(DecimalStringParams memory _params) private pure returns (string memory) {
    bytes memory _buffer = new bytes(_params.bufferLength);
    if (_params.isLessThanOne) {
      _buffer[0] = '0';
      _buffer[1] = '.';
    }

    // add leading/trailing 0's
    for (uint256 _zerosCursor = _params.zerosStartIndex; _zerosCursor < _params.zerosEndIndex + 1; _zerosCursor++) {
      _buffer[_zerosCursor] = bytes1(uint8(48));
    }
    // add sigfigs
    while (_params.sigfigs > 0) {
      if (_params.decimalIndex > 0 && _params.sigfigIndex == _params.decimalIndex) {
        _buffer[_params.sigfigIndex--] = '.';
      }
      uint8 _charIndex = uint8(48 + (_params.sigfigs % 10));
      _buffer[_params.sigfigIndex] = bytes1(_charIndex);
      _params.sigfigs /= 10;
      if (_params.sigfigs > 0) {
        _params.sigfigIndex--;
      }
    }
    return string(_buffer);
  }

  function _sigfigsRounded(uint256 _value, uint8 _digits) private pure returns (uint256, bool) {
    bool _extraDigit;
    if (_digits > 5) {
      _value = _value / (10**(_digits - 5));
    }
    bool _roundUp = _value % 10 > 4;
    _value = _value / 10;
    if (_roundUp) {
      _value = _value + 1;
    }
    // 99999 -> 100000 gives an extra sigfig
    if (_value == 100000) {
      _value /= 10;
      _extraDigit = true;
    }
    return (_value, _extraDigit);
  }

  function _char(bytes1 _b) private pure returns (bytes1) {
    if (uint8(_b) < 10) return bytes1(uint8(_b) + 0x30);
    else return bytes1(uint8(_b) + 0x57);
  }
}