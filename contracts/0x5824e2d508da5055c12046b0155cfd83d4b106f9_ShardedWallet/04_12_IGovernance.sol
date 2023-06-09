// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernance
{
    function isModule(address, address) external view returns (bool);
    function isAuthorized(address, address) external view returns (bool);
    function getModule(address, bytes4) external view returns (address);
    function getConfig(address, bytes32) external view returns (uint256);
    function getNiftexWallet() external view returns (address);
}