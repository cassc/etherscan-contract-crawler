// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IMerkleDistributor.sol';

// https://github.com/Uniswap/merkle-distributor
contract MerkleDistributor is IMerkleDistributor, Ownable, ReentrancyGuard {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public expireTimestamp;

    mapping(address => bool) public hasClaimed;

    /**
     * @dev sets values for associated token (ERC20), merkleRoot and expiration time
     *
     * @param token_ Contract address of the ERC20 token that is being dropped
     * @param merkleRoot_ Root of the token distribution merkle tree
     */
    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 expireTimestamp_
    ) {
        require(token_ != address(0), 'MerkleDistributor: token address cannot be zero');

        token = token_;
        merkleRoot = merkleRoot_;
        expireTimestamp = expireTimestamp_;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(!hasClaimed[account], 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed.
        hasClaimed[account] = true;

        // Transfer token
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Failed token transfer');
        
        emit Claimed(account, amount);
    }

    /**
     * @dev Sweep any unclaimed funds to arbitrary destination. Can only be called by owner.
     */
    function sweep(address target) external onlyOwner {
        require(block.timestamp >= expireTimestamp, 'MerkleDistributor: Drop not expired');
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));

        bool success = tokenContract.transfer(target, balance);
        require(success, 'MerkleDistributor: Failed token transfer');
    }

    /**
     * @dev Sweep any unclaimed funds to contract owner. Can be called by anyone.
     */
    function sweepToOwner() external {
        require(block.timestamp >= expireTimestamp, 'MerkleDistributor: Drop not expired');
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));

        bool success = tokenContract.transfer(owner(), balance);
        require(success, 'MerkleDistributor: Failed token transfer');
    }

    /**
     * @dev
     * 
     * @param newExpireTimestamp New expire timestamp
     */
    function updateExpireTimestamp(uint256 newExpireTimestamp) external onlyOwner {
        require(block.timestamp < newExpireTimestamp, 'MerkleDistributor: New timestamp must be in the future');
        require(newExpireTimestamp > expireTimestamp, 'MerkleDistributor: New timestamp must be greater than current');
        expireTimestamp = newExpireTimestamp;
    }

}