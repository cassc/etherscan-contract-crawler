// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @dev Interace to provide a function from Polygon Root Chain Manager
 */
interface IRootChainManager {
    function rootToChildToken(address _rootToken) external returns (address);
}