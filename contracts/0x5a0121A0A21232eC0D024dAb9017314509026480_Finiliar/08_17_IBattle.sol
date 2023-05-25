// SPDX-License-Identifier: GPL-3.0

/// @title IBattle interface

pragma solidity ^0.8.6;

interface IBattle {
    function isBattling(uint256 tokenId) external view returns (bool);
}