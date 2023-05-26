//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleWhitelist is Ownable {
  bytes32 public publicWhitelistMerkleRoot;
  bytes32 public mouseWhitelistMerkleRoot;

  string public whitelistURI;

  /*
  READ FUNCTIONS
  */

  //Frontend verify functions
  function verifyPublicSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, _hash(userAddress), publicWhitelistMerkleRoot);
  }

  function verifyMouseSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, _hash(userAddress), mouseWhitelistMerkleRoot);
  }

  //Internal verify functions
  function _verifyPublicSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), publicWhitelistMerkleRoot);
  }

  function _verifyMouseSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), mouseWhitelistMerkleRoot);
  }

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

  function setPublicWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    publicWhitelistMerkleRoot = merkleRoot;
  }

  function setMouseWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    mouseWhitelistMerkleRoot = merkleRoot;
  }

  /*
  MODIFIER
  */
  modifier onlyMouseWhitelist(bytes32[] memory proof) {
    require(_verifyMouseSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
  
  modifier onlyPublicWhitelist(bytes32[] memory proof) {
    require(_verifyPublicSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
}