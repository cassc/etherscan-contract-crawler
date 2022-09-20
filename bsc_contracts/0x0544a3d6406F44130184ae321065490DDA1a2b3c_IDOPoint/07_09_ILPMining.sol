// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILPMining {
    function getDepositedAmount(address user) external view returns (uint256);
}