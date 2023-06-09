// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArt {
    function isGoldToken(uint256 _membershipId) external view returns (bool);
}