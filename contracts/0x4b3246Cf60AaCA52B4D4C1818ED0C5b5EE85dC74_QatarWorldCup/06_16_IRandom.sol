// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;
interface IRandom {
    function random() external returns (uint256 seed_);
}