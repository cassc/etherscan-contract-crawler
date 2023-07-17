// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20PairToken {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}