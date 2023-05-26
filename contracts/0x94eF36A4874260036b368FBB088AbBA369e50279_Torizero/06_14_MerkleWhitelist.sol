//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract MerkleWhitelist is Ownable {
  bytes32 public wlWhitelistMerkleRoot;
  bytes32 public mainWhitelistMerkleRoot;
  bytes32 public extraWhitelistMerkleRoot;
  bytes32 public teamWhitelistMerkleRoot;


  function _verifyWlSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), wlWhitelistMerkleRoot);
  }

  function _verifyMainSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), mainWhitelistMerkleRoot);
  }

  function _verifyExtraSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), extraWhitelistMerkleRoot);
  }

   function _verifyTeamSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), teamWhitelistMerkleRoot);
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


  function setWlWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    wlWhitelistMerkleRoot = merkleRoot;
  }

  function setMainWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    mainWhitelistMerkleRoot = merkleRoot;
  }

  function setExtraWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    extraWhitelistMerkleRoot = merkleRoot;
  }

  function setTeamWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    teamWhitelistMerkleRoot = merkleRoot;
  }

  /*
  MODIFIER
  */
 modifier onlyWlWhitelist(bytes32[] memory proof) {
    require(_verifyWlSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }

  modifier onlyMainWhitelist(bytes32[] memory proof) {
    require(_verifyMainSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
  
  modifier onlyExtraWhitelist(bytes32[] memory proof) {
    require(_verifyExtraSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }

  modifier onlyTeamWhitelist(bytes32[] memory proof) {
    require(_verifyTeamSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
}