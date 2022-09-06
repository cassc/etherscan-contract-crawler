// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMintable {
    function mint(address to, uint256 amount) external;
}