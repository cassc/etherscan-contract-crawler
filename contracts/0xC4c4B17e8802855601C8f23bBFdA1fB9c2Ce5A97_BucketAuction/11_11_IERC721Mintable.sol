// SPDX-License-Identifier: MIT
// Creator: Vadim Fadeev
pragma solidity ^0.8.0;

interface IERC721Mintable {
    function mintBucketSmurf(address to, uint256 numberOfTokens) external;
}