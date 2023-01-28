// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IXENStake {
    event CreateStake(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 term);
    event EndStake(address indexed user, uint256 indexed tokenId);

    function createStake(uint256 amount, uint256 term) external returns (uint256);

    function endStake(uint256 tokenId) external;
}