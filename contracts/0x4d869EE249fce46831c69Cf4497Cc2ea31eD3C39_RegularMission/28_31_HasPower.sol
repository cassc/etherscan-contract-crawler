// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface HasPower {
    function power(uint256 tokenId) external view returns(uint256);
}