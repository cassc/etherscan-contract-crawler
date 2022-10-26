// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface HayJoinLike {
    function join(address usr, uint256 wad) external;

    function exit(address usr, uint256 wad) external;
}