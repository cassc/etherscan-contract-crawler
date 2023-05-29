// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IAvatar {
    function ownerOf(uint256 avatarId) external view returns (address);
}