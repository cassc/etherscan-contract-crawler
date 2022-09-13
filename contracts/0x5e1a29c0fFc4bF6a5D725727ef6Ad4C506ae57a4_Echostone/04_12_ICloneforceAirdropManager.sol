// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

pragma solidity ^0.8.16;

interface ICloneforceAirdropManager {
    function hasAirdrops() external view returns (bool value);
    function remainingClaims(address baseContract, uint256 tokenId, address airdropContract) external view returns (uint256 count);
    function claim(address to, uint256 baseTokenId, address airdropContract, uint256 count) external;
    function claimAll(address to, uint256 baseTokenId) external;
}