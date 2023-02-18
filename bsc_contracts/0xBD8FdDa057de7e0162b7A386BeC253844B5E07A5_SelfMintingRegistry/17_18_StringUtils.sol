// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Library for strings
 */
library StringUtils {
  /**
   * @notice Convert string in 32bytes
   * @param _string string to convert
   * @return result string converted in 32bytes
   */
  function stringToBytes32(string memory _string)
    internal
    pure
    returns (bytes32 result)
  {
    bytes memory source = bytes(_string);
    if (source.length == 0) {
      return 0x0;
    } else if (source.length > 32) {
      revert('Bytes length bigger than 32');
    } else {
      assembly {
        result := mload(add(source, 32))
      }
    }
  }

  /**
   * @notice Conevert bytes32 in string
   * @param _bytes32 32bytes to convert
   * @return 32bytes converted in string
   */
  function bytes32ToString(bytes32 _bytes32)
    internal
    pure
    returns (string memory)
  {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }
}