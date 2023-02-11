// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IOnChainMetadata.sol";
import "../tokens/erc721/custom-erc721/ERC721AEnumerable.sol";
import "../libraries/Math.sol";

library SymmetricEncryptionUtils {
  function bytesToBytes32Arr(bytes memory source) internal pure returns (bytes32[] memory) {
    uint256 sourceLen = source.length;
    bytes32[] memory result = new bytes32[](Math.ceilDiv(sourceLen, 32));

    for (uint256 i = 0; i < result.length; i++) {
      for (uint256 j = 0; j < 32; j++) {
        uint256 index = i * 32 + j;
        if (index >= sourceLen) {
          result[i] |= bytes32(0) >> (8 * j);
        } else {
          result[i] |= bytes32(source[index]) >> (8 * j);
        }
      }
    }
    return result;
  }

  function bytes32ArrToBytes(bytes32[] memory source) internal pure returns (bytes memory) {
    bytes memory result = new bytes(source.length * 32);
    for (uint256 i = 0; i < source.length; i++) {
      for (uint256 j = 0; j < 32; j++) {
        result[i * 32 + j] = bytes1(source[i] << (8 * j));
      }
    }
    return result;
  }

  function encrypt(
    bytes32 decryptionKey,
    bytes32[] memory secret
  ) internal pure returns (bytes32[] memory) {
    bytes32[] memory encrypted = new bytes32[](secret.length);
    for (uint256 i = 0; i < secret.length; i++) {
      encrypted[i] = secret[i] ^ decryptionKey;
    }
    return encrypted;
  }

  function bytesTrimEnd(bytes memory source) internal pure returns (bytes memory result) {
    uint256 len = 0;
    for (uint256 i = 0; i < source.length; i++) {
      if (source[i] == 0) {
        len = i;
        break;
      }
    }
    result = new bytes(len);
    for (uint256 i = 0; i < len; i++) {
      result[i] = source[i];
    }
    return result;
  }
}