// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library ENSNamehash {

  function namehash(bytes memory domain) internal pure returns (bytes32) {
    return namehash(domain, 0);
  }

  function namehash(bytes memory domain, uint i) internal pure returns (bytes32) {
    if (domain.length <= i)
      return 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint len = LabelLength(domain, i);

    return keccak256(abi.encodePacked(namehash(domain, i+len+1), keccak(domain, i, len)));
  }

  function LabelLength(bytes memory domain, uint i) private pure returns (uint) {
    uint len;
    while (i+len != domain.length && domain[i+len] != 0x2e) {
      len++;
    }
    return len;
  }

  function keccak(bytes memory data, uint offset, uint len) private pure returns (bytes32 ret) {
    require(offset + len <= data.length);
    assembly {
      ret := keccak256(add(add(data, 32), offset), len)
    }
  }
}