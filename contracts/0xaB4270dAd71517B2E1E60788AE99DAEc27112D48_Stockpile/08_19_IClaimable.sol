// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

pragma solidity ^0.8.17;

interface IClaimable {
    function mintClaim(address to, uint256 tokenId, uint256 count) external;
}