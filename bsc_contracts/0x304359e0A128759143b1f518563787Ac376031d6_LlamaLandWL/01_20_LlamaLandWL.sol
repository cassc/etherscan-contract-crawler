// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./LlamaLandClaimer.sol";

contract LlamaLandWL is LlamaLandClaimer {

    mapping(address => bool) public claimedList;

    bytes32 public merkleRoot;

    constructor(address llamaLandAddress) LlamaLandClaimer(llamaLandAddress, 1688, 15 * 10 ** 16, 6) {
    }

    function claim(bytes32[] memory proof, uint amount) payable external {
        _checkClaim(amount);
        require(!claimedList[_msgSender()], "Has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        _pay();
        _effectClaim(amount);
        claimedList[_msgSender()] = true;
        _interactClaim(amount);
    }

    function setMerkleRoot(bytes32 root) onlyOwner external {
        merkleRoot = root;
    }
}