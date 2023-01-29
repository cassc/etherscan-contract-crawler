// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMetacadePresaleV1 {
    function totalTokensSold() external view returns(uint256);

    function userDeposits(address) external view returns(uint256);
}