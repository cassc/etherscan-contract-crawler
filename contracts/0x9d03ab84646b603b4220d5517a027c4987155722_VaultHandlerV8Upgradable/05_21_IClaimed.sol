// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IClaimed {
    function isClaimed(address nftAddress, uint tokenId, bytes32[] calldata proof) external returns(bool);
    function claim(address nftAddress, uint tokenId, address _claimedBy) external;
}