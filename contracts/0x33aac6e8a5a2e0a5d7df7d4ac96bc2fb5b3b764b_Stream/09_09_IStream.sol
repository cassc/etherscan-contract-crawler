// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IStream {
    function initialize() external;

    function withdraw(uint256 amount) external;
}