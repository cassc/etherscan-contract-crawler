// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function index() external view returns(uint256);
    function stakeFor(address, uint256) external;
}