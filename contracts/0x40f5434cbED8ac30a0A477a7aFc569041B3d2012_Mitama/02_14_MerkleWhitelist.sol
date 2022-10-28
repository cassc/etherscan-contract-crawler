//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library WL {
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
}

contract MerkleWhitelist is Ownable {
  bytes32 public normalWhitelistMerkleRoot;
  bytes32 public specialWhitelistMerkleRoot;
  bytes32 public freeMintWhitelistMerkleRoot;

  string public whitelistURI;
  error CallerIsNotWhitelisted();

  /*
  READ FUNCTIONS
  */

  //Frontend verify functions
  function verifyNormalSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return WL._verify(proof, WL._hash(userAddress), normalWhitelistMerkleRoot);
  }

  function verifySpecialSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return WL._verify(proof, WL._hash(userAddress), specialWhitelistMerkleRoot);
  }

  function verifyFreeMintSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return WL._verify(proof, WL._hash(userAddress), freeMintWhitelistMerkleRoot);
  }

  //Internal verify functions
  function _verifyNormalSender(bytes32[] memory proof) internal view returns (bool) {
    return WL._verify(proof, WL._hash(msg.sender), normalWhitelistMerkleRoot);
  }

  function _verifySpecialSender(bytes32[] memory proof) internal view returns (bool) {
    return WL._verify(proof, WL._hash(msg.sender), specialWhitelistMerkleRoot);
  }

  function _verifyFreeMintSender(bytes32[] memory proof) internal view returns (bool) {
    return WL._verify(proof, WL._hash(msg.sender), freeMintWhitelistMerkleRoot);
  }

  /*
  OWNER FUNCTIONS
  */

  function setNormalWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    normalWhitelistMerkleRoot = merkleRoot;
  }
  function setSpecialWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    specialWhitelistMerkleRoot = merkleRoot;
  }
  function setFreeMintWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    freeMintWhitelistMerkleRoot = merkleRoot;
  }
  /*
  MODIFIER
  */
  modifier onlyNormalWhitelist(bytes32[] memory proof) {
    if(!_verifyNormalSender(proof)) revert CallerIsNotWhitelisted();
    _;
  }

  modifier onlySpecialWhitelist(bytes32[] memory proof) {
    if(!_verifySpecialSender(proof)) revert CallerIsNotWhitelisted();
    _;
  }
  
  modifier onlyFreeMintWhitelist(bytes32[] memory proof) {
    if(!_verifyFreeMintSender(proof)) revert CallerIsNotWhitelisted();
    _;
  }
}