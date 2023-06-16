// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMachinieLevel{
    function getLevel (uint256 tokenId_) external view returns(uint256);
}