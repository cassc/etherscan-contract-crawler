// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBalancerPoolToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}