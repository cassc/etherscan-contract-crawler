// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface ILido {
    function wrap(uint256) external returns (uint256);

    function unwrap(uint256) external returns (uint256);

    function getWstETHByStETH(uint256) external returns (uint256);
}