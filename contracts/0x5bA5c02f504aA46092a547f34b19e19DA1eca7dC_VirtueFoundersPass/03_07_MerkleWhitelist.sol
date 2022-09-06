//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleWhitelist is Ownable {
  bytes32 public merkleRoot;

  string public whitelistURI;

  /*
  READ FUNCTIONS
  */

  function _verify(bytes32[] memory proof, bytes32 addressHash, bytes32 whitelistMerkleRoot)
    internal
    pure
    returns (bool)
  {
    return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
  }

  function _hash(address _address) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address));
  }

  /*
  OWNER FUNCTIONS
  */

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /*
  MODIFIER
  */
  modifier onlyWhitelisted(bytes32[] memory proof) {
    bool whitelisted = _verify(proof, _hash(msg.sender), merkleRoot);
    require(whitelisted, "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
}