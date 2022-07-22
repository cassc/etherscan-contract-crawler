// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function getTargetValue() external view returns(uint256, uint256);
}