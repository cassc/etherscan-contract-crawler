// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IXENTorrent {
    event StartTorrent(address indexed user, uint256 count, uint256 term);
    event EndTorrent(address indexed user, uint256 tokenId, address to);

    function bulkClaimRank(uint256 count, uint256 term) external returns (uint256);

    function bulkClaimMintReward(uint256 tokenId, address to) external;
}