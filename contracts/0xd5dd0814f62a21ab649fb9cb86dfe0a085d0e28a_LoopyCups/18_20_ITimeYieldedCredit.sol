// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITimeYieldedCredit {
    function getCurrentYield() external view returns(uint256);
}