// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

interface IBottoStaking {
    function botto() external view returns (address);
    function owner() external view returns (address);
    function totalStaked() external view returns (uint256);
    function userStakes(address user) external view returns (uint256);
}