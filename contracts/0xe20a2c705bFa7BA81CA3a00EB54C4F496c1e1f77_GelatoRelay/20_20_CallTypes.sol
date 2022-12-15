// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Sponsored relay call
struct SponsoredCall {
    uint256 chainId;
    address target;
    bytes data;
}

// Relay call with user signature verification for ERC 2771 compliance
struct CallWithERC2771 {
    uint256 chainId;
    address target;
    bytes data;
    address user;
    uint256 userNonce;
    uint256 userDeadline;
}