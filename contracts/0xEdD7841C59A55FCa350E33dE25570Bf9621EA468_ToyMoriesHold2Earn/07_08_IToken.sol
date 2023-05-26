// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IToken {
    function mintTo(address to, uint256 amount) external;
}