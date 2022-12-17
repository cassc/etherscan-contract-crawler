// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IBalancerMinter {
    function mint(address gauge) external;
    function getBalancerToken() external returns (address);
}