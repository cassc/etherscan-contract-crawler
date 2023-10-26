/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

// SPDX-License-Identifier: UNLICENSED

/**
 * @title NTP Collabs Minter
 * @author 0xSumo <@0xSumo>
 */

pragma solidity ^0.8.0;

abstract contract OwnControll {
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

contract CollabsMinter is OwnControll, MerkleProof {

    iToken public Token = iToken(0x68607266e9118B971901239891e6280a8066fCEb);

    uint256 public activeTime = 1697889600;
    uint256 public endTime = 1699185600;

    uint256 public constant TOKEN_ID = 15;

    mapping(address => uint256) public mintMin;

    address[] public minterMax;
    mapping(address => uint256) public minterMaxMin;

    constructor(bytes32 merkleRoot_) { 
        _setMerkleRoot(merkleRoot_);
    }

    function mintMany(bytes32[] memory proof_, uint256 amount, bytes memory data) external {
        require(block.timestamp >= activeTime && block.timestamp <= endTime, "Inactive");
        require(isWhitelisted(msg.sender, proof_), "You are not whitelisted!");
        bool isInMinterMax = false;
        for (uint i = 0; i < minterMax.length; i++) {
            if (minterMax[i] == msg.sender) {
                isInMinterMax = true;
                break;
            }
        }
        if (isInMinterMax) {
            require(minterMaxMin[msg.sender] >= amount, "Exceed max per addy and tx");
            require(minterMaxMin[msg.sender] >= mintMin[msg.sender] + amount, "Exceed max per addy and tx");
            Token.mintToken(msg.sender, TOKEN_ID, amount, data);
            mintMin[msg.sender] += amount;
        }
        else {
            require(mintMin[msg.sender] == 0, "Exceed max per addy and tx");
            Token.mintToken(msg.sender, TOKEN_ID, 1, data);
            mintMin[msg.sender]++;
        }
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_);
    }

    function setTime(uint256 timeStart_, uint256 timeEnd_) public onlyOwner { 
        activeTime = timeStart_; 
        endTime = timeEnd_;
    }

    function setMinterMaxAmount(address _address, uint256 amount) external onlyOwner {
        minterMaxMin[_address] = amount;
        minterMax.push(_address);
    }
}