/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

// SPDX-License-Identifier: UNLISENCED

/**
 * @title NTP Collabs Minter
 * @author 0xSumo 
 */

pragma solidity ^0.8.0;

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

abstract contract MerkleProof {
    bytes32 internal _merkleRoot;
    function _setMerkleRoot(bytes32 merkleRoot_) internal virtual { _merkleRoot = merkleRoot_; }
    function isWhitelisted(address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRoot;
    }
}

interface iToken { 
    function mintToken(address to, uint256 id, uint256 amount, bytes memory data) external; 
}

contract Minter is Ownable, MerkleProof {

    iToken public Token = iToken(0x68607266e9118B971901239891e6280a8066fCEb);

    uint256 public constant startTime = 1689422400;
    uint256 public constant TOKEN_ID = 11;
    mapping(address => uint256) private minted;

    modifier onlySender { require(msg.sender == tx.origin, "No smart contract");_; }

    function mintToken(bytes32[] memory proof_, bytes memory data) external onlySender {
        require(block.timestamp >= startTime, "Sale has not started yet!");
        require(isWhitelisted(msg.sender, proof_), "You are not whitelisted!");
        require(minted[msg.sender] == 0, "Exceed max per addy and tx");
        minted[msg.sender]++;
        Token.mintToken(msg.sender, TOKEN_ID, 1, data);
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_);
    }
}