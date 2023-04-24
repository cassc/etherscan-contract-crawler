pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;

interface ICobee {
    function mint(address to) external returns (uint256);
}