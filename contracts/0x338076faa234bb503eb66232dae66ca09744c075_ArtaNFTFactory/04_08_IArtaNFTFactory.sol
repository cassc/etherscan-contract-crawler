// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface IArtaNFTFactory {
    function beforeMint(address addr, bytes32[] calldata merkleProof) external returns (uint256);

    function checkBlacklistMarketplaces(address addr) external;

    function isAdmin(address addr) external view returns (bool);
}