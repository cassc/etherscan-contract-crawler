// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface HpprsInterface {
    function burn(uint256) external;
    function ownerOf(uint256) external returns (address);
}