//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRandom {
    function random(uint256 salt, uint256 length) external view returns (uint256);
}