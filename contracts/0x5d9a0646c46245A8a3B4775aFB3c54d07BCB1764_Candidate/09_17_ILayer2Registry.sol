// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2Registry {
    function layer2s(address layer2) external view returns (bool);

    function register(address layer2) external returns (bool);
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);

    function deployCoinage(address layer2, address seigManager) external returns (bool);
    function registerAndDeployCoinage(address layer2, address seigManager) external returns (bool);
    function unregister(address layer2) external returns (bool);
}