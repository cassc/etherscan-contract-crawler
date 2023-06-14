// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IETHUnwrapper {
    function unwrap(uint256 _amount, address _to) external;
}