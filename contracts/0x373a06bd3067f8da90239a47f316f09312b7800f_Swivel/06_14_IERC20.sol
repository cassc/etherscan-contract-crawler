// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

// methods requried on other contracts which are expected to, at least, implement the following:
interface IERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}