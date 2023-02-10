// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IStrategy {
    function initialize(address token, bytes memory data) external;

    function deposit(address token, uint256 amount) external;

    function withdraw(address token, uint256 amount) external;

    function exit(address token) external;

    function collectExtra(
        address token,
        address to,
        bytes memory data
    ) external;

    function getBalance(address token) external view returns (uint256);
}