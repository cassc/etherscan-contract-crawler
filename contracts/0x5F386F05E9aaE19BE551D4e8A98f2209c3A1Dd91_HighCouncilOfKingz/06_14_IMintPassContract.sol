// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMintPassContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isValid(uint256 tokenId) external view returns (bool);

    function setAsUsed(uint256 tokenId) external;
}