//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBalancerPool {
    function totalSupply() external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
}