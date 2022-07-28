//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WgmisMerkleTreeWhitelist {

  bytes32 public merkleRoot;

  constructor(bytes32 _merkleRoot) {
    merkleRoot = _merkleRoot;
  }

  function isValidMerkleProof(bytes32[] calldata _merkleProof, address _minter, uint96 _amount) external view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_minter, _amount));
    bool result = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    require(result, 'INVALID_MERKLE_PROOF');
    return result;
  }

}