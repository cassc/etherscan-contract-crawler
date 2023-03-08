// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IStargateFactory {
    function getPool(uint256) external view returns (address);
}