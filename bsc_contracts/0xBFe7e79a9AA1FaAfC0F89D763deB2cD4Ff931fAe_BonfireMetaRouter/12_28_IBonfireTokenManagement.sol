// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IBonfireTokenManagement {
    function WETH() external view returns (address);

    function tokenFactory() external view returns (address);

    function defaultToken() external view returns (address);

    function getIntermediateTokens() external view returns (address[] memory);

    function getAlternateProxy(address sourceToken) external returns (address);

    function getDefaultProxy(address sourceToken) external returns (address);

    function maxTx(address token) external view returns (uint256);
}