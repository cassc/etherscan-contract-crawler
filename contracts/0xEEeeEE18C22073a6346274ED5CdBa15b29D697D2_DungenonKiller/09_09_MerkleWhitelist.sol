// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

contract MerkleWhitelist is Ownable {
    bytes32 public wl1WhitelistMerkleRoot;

    constructor(bytes32 _wl1WhitelistMerkleRoot) {
        wl1WhitelistMerkleRoot = _wl1WhitelistMerkleRoot;
    }

    function _verifyWl1Sender(bytes32[] memory proof) internal view returns (bool) {
        return _verify(proof, _hash(msg.sender), wl1WhitelistMerkleRoot);
    }

    function _verify(bytes32[] memory proof, bytes32 addressHash, bytes32 whitelistMerkleRoot)
    internal
    pure
    returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
    }

    function _hash(address _address) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(_address))));
    }

    function setWl1WhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        wl1WhitelistMerkleRoot = merkleRoot;
    }

    /*
    MODIFIER
    */
    modifier onlyWl1Whitelist(bytes32[] memory proof) {
        require(_verifyWl1Sender(proof), "MerkleWhitelist: Caller is not whitelisted");
        _;
    }
}