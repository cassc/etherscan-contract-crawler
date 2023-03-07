// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

interface IOracle {
    function latestAnswer() external view returns (uint256);
}