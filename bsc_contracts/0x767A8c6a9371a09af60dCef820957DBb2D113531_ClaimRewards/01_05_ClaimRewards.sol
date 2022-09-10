// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimRewards is Ownable {
    bytes32 private root;
    // Mapping for keeping track of which address claimed already
    mapping(address => bool) public claimedAlready;

    constructor(bytes32 _root) {
        root = _root;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setRoot(bytes32 _newRoot) public onlyOwner {
        root = _newRoot;
    }

    function withdraw(address token, bytes32[] memory proof) external {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not part of Allowlist");
        require(!claimedAlready[msg.sender], "Claimed already");
        claimedAlready[msg.sender] = true;
        IERC20(token).transfer(msg.sender, 50 * 10**18);
    }
}