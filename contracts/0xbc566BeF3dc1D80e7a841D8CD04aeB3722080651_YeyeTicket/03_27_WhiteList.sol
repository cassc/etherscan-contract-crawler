// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhiteList {
    bool public requireWhiteList;
    bytes32 public merkleRoot;

    modifier onlyListed(bytes32[] calldata _proof) {
        require(isListed(_proof, msg.sender), "Not whitelisted");
        _;
    }

    constructor () {
        requireWhiteList = true;
    }

    function _setRequireWhiteList(bool value) internal {
        requireWhiteList = value;
    }

    function _setMerkleRoot(bytes32 root) internal {
        merkleRoot = root;
    }

    function isListed(bytes32[] calldata _proof, address _address) public view returns(bool) {
        bytes32 leaf = toBytes32(_address);
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}