// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Verify {
  function verifySignature(bytes32 hash, bytes memory signature, address signer) internal pure {
    bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
    require(ecrecover(signedHash, v, r, s) == signer, "Invalid signature");
  }

  function verifyMerkleTree(bytes32 merkleRoot, bytes32[] calldata merkleProof) internal view returns (bool) {
    bytes32 computedHash = keccak256(abi.encodePacked(msg.sender));
    for (uint256 i = 0; i < merkleProof.length; i++) {
      computedHash = _hashPair(computedHash, merkleProof[i]);
    }
    return computedHash == merkleRoot;
  }

  function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
  }

  function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}