// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

interface IWarmWallet {
    function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}