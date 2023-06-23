// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ITokenPreTimelock {
    function depositTokens(address recipient, uint256 amount) external;
}