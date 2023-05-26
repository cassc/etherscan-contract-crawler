//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Allowlist {
    bool public requireAllowlist;
    bytes32 public merkleRoot;

    modifier onlyAllowed(bytes32[] calldata _proof) {
        require(isAllowed(_proof, msg.sender), "Allowlist: not found");
        _;
    }

    constructor () {
        requireAllowlist = true;
    }

    function _setRequireAllowlist(bool value) internal {
        requireAllowlist = value;
    }

    function _setMerkleRoot(bytes32 root) internal {
        merkleRoot = root;
    }

    function isAllowed(bytes32[] calldata _proof, address _address) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }
}