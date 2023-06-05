// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMetadataFreeze {
    function isTokenFrozen(uint256 tokenId) external view returns (bool);
}