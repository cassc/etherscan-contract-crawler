// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITimeCatsLoveEmHateEm {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setAsUsed(uint256 tokenId) external;

    function isUsed(uint256 tokenId) external view returns (bool);
}