// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

// Issue based on the transaction sender (e.g. the API)
interface ICedarIssuerV0 {
    // Issue a specific token
    function issue(address recipient, uint256 tokenId) external;
}