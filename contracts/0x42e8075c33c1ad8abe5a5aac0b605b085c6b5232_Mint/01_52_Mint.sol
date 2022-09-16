// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {Wheyfu} from "./Wheyfu.sol";

contract Mint is Owned {
    uint256 public constant MAX_MINT_AMOUNT = 10;
    bytes32 public merkleRoot;
    Wheyfu public wheyfu;
    mapping(address => uint256) public minted;

    constructor(address payable _wheyfu) Owned(msg.sender) {
        wheyfu = Wheyfu(_wheyfu);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function mint(uint256 amount, bytes32[] memory proof) public {
        // verify proof
        require(
            MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid whitelist proof"
        );

        // increment the amount that the msg.sender has minted
        minted[msg.sender] += amount;
        require(minted[msg.sender] <= MAX_MINT_AMOUNT, "Already minted max amount");

        // mint wheyfus to msg.sender
        wheyfu.mintTo(amount, msg.sender);
    }
}